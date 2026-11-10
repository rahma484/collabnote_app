import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/models/task.dart';
import '../services/collab_note_service.dart';

class TaskRepository extends ChangeNotifier {
  final CollabNoteService _service;

  List<Task> _tasks = [];

  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  String? _watchedProjectId;

  TaskRepository(this._service);

  List<Task> get tasks => List.unmodifiable(_tasks);

  List<Task> get incompleteTasks =>
      _tasks.where((task) => !task.isCompleted).toList();

  List<Task> get completedTasks =>
      _tasks.where((task) => task.isCompleted).toList();

  List<Task> tasksForProject(String projectId) =>
      _tasks.where((task) => task.projectId == projectId).toList();

  /// Dipanggil saat pindah akun agar data pengguna lama tidak tampil.
  void clear() {
    stopWatching();
    _tasks = [];
  }

  void _replaceProjectTasks(String projectId, List<Task> projectTasks) {
    _tasks = [
      ..._tasks.where((task) => task.projectId != projectId),
      ...projectTasks,
    ];
  }

  /// Memuat tugas satu proyek tanpa menghapus tugas proyek lain,
  /// sehingga Beranda dan Checklist tetap lengkap.
  Future<void> loadTasks(String projectId) async {
    final fetched = await _service.fetchTasks(projectId);

    _replaceProjectTasks(projectId, fetched);
    notifyListeners();
  }

  Future<void> loadTasksForProjects(List<String> projectIds) async {
    if (projectIds.isEmpty) {
      _tasks = [];
      notifyListeners();
      return;
    }

    final results = await Future.wait(
      projectIds.map((id) => _service.fetchTasks(id)),
    );

    _tasks = results.expand((items) => items).toList();
    notifyListeners();
  }

  /// Supabase Realtime: perubahan tugas dari HP anggota lain
  /// langsung masuk ke sini dan memicu notifyListeners().
  void watchProject(String projectId) {
    if (_watchedProjectId == projectId) return;

    stopWatching();
    _watchedProjectId = projectId;

    _subscription = _service.streamTasks(projectId).listen(
      (rows) {
        final fetched = rows.map(Task.fromJson).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        _replaceProjectTasks(projectId, fetched);
        notifyListeners();
      },
      onError: (Object error) {
        // Koneksi realtime putus: data terakhir tetap ditampilkan.
        debugPrint('Realtime tasks error: $error');
      },
    );
  }

  void stopWatching() {
    _subscription?.cancel();
    _subscription = null;
    _watchedProjectId = null;
  }

  Future<void> addTask({
    required String projectId,
    required String title,
    String? assignee,
  }) async {
    final newTask = await _service.createTask(
      projectId: projectId,
      title: title,
      assignee: assignee,
    );

    // Stream realtime bisa saja sudah membawa tugas ini lebih dulu.
    if (!_tasks.any((task) => task.id == newTask.id)) {
      _tasks = [..._tasks, newTask];
    }

    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    final updatedTask = await _service.updateTask(task);

    _tasks = _tasks.map((item) {
      return item.id == updatedTask.id ? updatedTask : item;
    }).toList();

    notifyListeners();
  }

  Future<void> toggleTask(Task task, bool isCompleted) async {
    final updatedTask = task.copyWith(
      isCompleted: isCompleted,
      status: isCompleted ? 'Done' : 'To Do',
    );

    await updateTask(updatedTask);
  }

  /// Pindah kolom di Task Board (To Do / In Progress / Done).
  /// isCompleted ikut disinkronkan agar Checklist & Beranda konsisten.
  Future<void> moveTask(Task task, String status) async {
    final updatedTask = task.copyWith(
      status: status,
      isCompleted: status == 'Done',
    );

    await updateTask(updatedTask);
  }

  Future<void> removeTask(String taskId) async {
    await _service.deleteTask(taskId);

    _tasks = _tasks.where((task) => task.id != taskId).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    stopWatching();
    super.dispose();
  }
}
