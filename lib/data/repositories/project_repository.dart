
import '../../domain/models/project.dart';
import '../services/collab_note_service.dart';

class ProjectRepository {
  final CollabNoteService _service;

  ProjectRepository(this._service);

  Future<List<Project>> getProjects() {
    return _service.fetchProjects();
  }

  Future<Project> addProject({
    required String title,
    String? description,
    required String category,
    required String projectType,
    DateTime? deadline,
  }) {
    return _service.createProject(
      title: title,
      description: description,
      category: category,
      projectType: projectType,
      deadline: deadline,
    );
  }

  Future<void> removeProject(String projectId) {
    return _service.deleteProject(projectId);
  }
}
