import 'package:flutter/foundation.dart';

import '../../data/repositories/project_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../domain/models/project.dart';
import '../../domain/models/task.dart';
import '../projects/projects_view_model.dart';

class HomeViewModel extends ChangeNotifier {
  final ProjectRepository _projectRepository;
  final TaskRepository _taskRepository;

  List<Project> _projects = [];

  /// Kategori terpilih di Beranda ('Semua' = tanpa filter).
  String selectedCategory = 'Semua';

  bool isLoading = false;
  String? error;

  HomeViewModel({
    required this._projectRepository,
    required this._taskRepository,
  }) {
    _taskRepository.addListener(_onTasksChanged);
  }

  static List<String> get categories => ProjectsViewModel.categories;

  List<Project> get projects => List.unmodifiable(_projects);

  /// Data utama untuk kategori yang dipilih.
  List<Project> get filteredProjects {
    if (selectedCategory == 'Semua') {
      return List.unmodifiable(_projects);
    }

    return _projects
        .where((project) => project.category == selectedCategory)
        .toList();
  }

  /// Data aksi yang belum selesai (dari repository tugas).
  List<Task> get incompleteTasks => _taskRepository.incompleteTasks;

  List<Task> get completedTasks => _taskRepository.completedTasks;

  int totalTasksFor(String projectId) =>
      _taskRepository.tasksForProject(projectId).length;

  int completedTasksFor(String projectId) => _taskRepository
      .tasksForProject(projectId)
      .where((task) => task.isCompleted)
      .length;

  /// Nilai 0.0 - 1.0 untuk indikator progress di kartu proyek.
  double progressFor(String projectId) {
    final total = totalTasksFor(projectId);

    if (total == 0) return 0;

    return completedTasksFor(projectId) / total;
  }

  void selectCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

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
