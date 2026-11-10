import '../../domain/models/project.dart';
import '../../domain/models/project_template.dart';
import '../services/collab_note_service.dart';

class ProjectRepository {
  final CollabNoteService _service;

  ProjectRepository(this._service);

  Future<List<Project>> getProjects() {
    return _service.fetchProjects();
  }

  /// Menyimpan proyek lalu otomatis membuat tugas default
  /// sesuai template (kategori) yang dipilih.
  Future<Project> addProject({
    required String title,
    String? description,
    required String category,
    required String projectType,
    DateTime? deadline,
  }) async {
    final project = await _service.createProject(
      title: title,
      description: description,
      category: category,
      projectType: projectType,
      deadline: deadline,
    );

    final template = ProjectTemplate.byCategory(category);

    try {
      await _service.createDefaultTasks(
        project.id,
        template.defaultTasks,
      );
    } catch (_) {
      // Proyek sudah tersimpan; tugas default bersifat bonus,
      // jadi kegagalannya tidak membatalkan pembuatan proyek.
    }

    return project;
  }

  Future<void> removeProject(String projectId) {
    return _service.deleteProject(projectId);
  }
}
