import 'package:flutter/foundation.dart';

import '../../data/repositories/project_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../domain/models/project.dart';
import '../../domain/models/task.dart';

class ProjectDetailViewModel extends ChangeNotifier {
  final ProjectRepository _projectRepository;
  final TaskRepository _taskRepository;

  /// Urutan kolom Task Board.
  static const List<String> statuses = ['To Do', 'In Progress', 'Done'];

  final Project project;

  bool _disposed = false;

  bool isLoading = false;
  String? error;

  ProjectDetailViewModel({
    required this.project,
    required this._projectRepository,
    required this._taskRepository,
  }) {
    _taskRepository.addListener(_onTasksChanged);
  }

  List<Task> get tasks => _taskRepository.tasksForProject(project.id);

  List<Task> tasksWithStatus(String status) =>
      tasks.where((task) => task.status == status).toList();

  int get totalCount => tasks.length;

  int get completedCount => tasks.where((task) => task.isCompleted).length;

  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;

  void _onTasksChanged() {
    notifyListeners();
  }

  /// Memuat tugas lalu mengaktifkan Supabase Realtime untuk proyek ini.
  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _taskRepository.loadTasks(project.id);
      _taskRepository.watchProject(project.id);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTask({
    required String title,
    String? assignee,
  }) async {
    try {
      await _taskRepository.addTask(
        projectId: project.id,
        title: title,
        assignee: assignee,
      );
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> moveTask(Task task, String status) async {
    try {
      await _taskRepository.moveTask(task, status);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(Task task) async {
    try {
      await _taskRepository.removeTask(task.id);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProject() async {
    try {
      await _projectRepository.removeProject(project.id);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _taskRepository.removeListener(_onTasksChanged);
    _taskRepository.stopWatching();
    super.dispose();
  }
}
