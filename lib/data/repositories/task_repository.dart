import 'package:flutter/foundation.dart';

import '../../domain/models/task.dart';
import '../services/collab_note_service.dart';

class TaskRepository extends ChangeNotifier {
  final CollabNoteService _service;

  List<Task> _tasks = [];

  TaskRepository(this._service);

  List<Task> get tasks => List.unmodifiable(_tasks);

  List<Task> get incompleteTasks =>
      _tasks.where((task) => !task.isCompleted).toList();

  List<Task> get completedTasks =>
      _tasks.where((task) => task.isCompleted).toList();

  Future<void> loadTasks(String projectId) async {
    _tasks = await _service.fetchTasks(projectId);
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

    _tasks = [..._tasks, newTask];
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

  Future<void> removeTask(String taskId) async {
    await _service.deleteTask(taskId);

    _tasks = _tasks.where((task) => task.id != taskId).toList();
    notifyListeners();
  }
}