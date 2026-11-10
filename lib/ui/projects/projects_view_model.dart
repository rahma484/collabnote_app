import 'package:flutter/foundation.dart';

import '../../data/repositories/project_repository.dart';
import '../../domain/models/project.dart';

class ProjectsViewModel extends ChangeNotifier {
  final ProjectRepository _repository;

  ProjectsViewModel(this._repository);

  List<Project> _projects = [];

  static const List<String> categories = [
    'Semua',
    'Software / App Development',
    'Business Plan & Startup',
    'Makalah, Proposal, & Riset Ilmiah',
    'Creative, Media / Desain',
    'Catatan Bebas / General',
  ];

  String selectedCategory = 'Semua';

  bool isLoading = false;
  String? error;

  // Dipisah dari `error` supaya gagal menyimpan tidak
  // mengosongkan daftar proyek di layar.
  bool isSaving = false;
  String? saveError;

  List<Project> get projects {
    if (selectedCategory == 'Semua') {
      return List.unmodifiable(_projects);
    }

    return _projects
        .where((project) => project.category == selectedCategory)
        .toList();
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      _projects = await _repository.getProjects();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Menyimpan proyek baru. Tugas default dari template
  /// dibuat otomatis oleh repository.
  Future<bool> createProject({
    required String title,
    String? description,
    required String category,
    required String projectType,
    DateTime? deadline,
  }) async {
    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      await _repository.addProject(
        title: title,
        description: description,
        category: category,
        projectType: projectType,
        deadline: deadline,
      );
      return true;
    } catch (e) {
      saveError = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void selectCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }
}