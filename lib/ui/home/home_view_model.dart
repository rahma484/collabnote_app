import 'package:flutter/foundation.dart';

import '../../data/repositories/project_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../domain/models/project.dart';
import '../../domain/models/task.dart';

class HomeViewModel extends ChangeNotifier {
  final ProjectRepository _projectRepository;
  final TaskRepository _taskRepository;

  List<Project> _projects = [];

  bool isLoading = false;
  String? error;

  HomeViewModel({
    required this._projectRepository,
    required this._taskRepository,
  }) {
    _taskRepository.addListener(_onTasksChanged);
  }

  List<Project> get projects => List.unmodifiable(_projects);

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
      _projects = await _projectRepository.getProjects();

      await _taskRepository.loadTasksForProjects(
        _projects.map((project) => project.id).toList(),
      );
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _taskRepository.removeListener(_onTasksChanged);
    super.dispose();
  }
}