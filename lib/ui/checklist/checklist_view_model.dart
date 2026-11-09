import 'package:flutter/foundation.dart';

import '../../data/repositories/project_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../domain/models/task.dart';

class ChecklistViewModel extends ChangeNotifier {
  final ProjectRepository _projectRepository;
  final TaskRepository _taskRepository;

  bool isLoading = false;
  String? error;

  ChecklistViewModel({
    required this._projectRepository,
    required this._taskRepository,
  }) {
    _taskRepository.addListener(_onTasksChanged);
  }

  List<Task> get incompleteTasks => _taskRepository.incompleteTasks;

  List<Task> get completedTasks => _taskRepository.completedTasks;

  void _onTasksChanged() {
    notifyListeners();
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final projects = await _projectRepository.getProjects();

      await _taskRepository.loadTasksForProjects(
        projects.map((project) => project.id).toList(),
      );
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggle(Task task, bool isCompleted) async {
    error = null;

    try {
      await _taskRepository.toggleTask(task, isCompleted);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _taskRepository.removeListener(_onTasksChanged);
    super.dispose();
  }
}
