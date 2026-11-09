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

  void selectCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }
}