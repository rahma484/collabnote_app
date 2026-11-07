import '../../domain/models/project_update.dart';
import '../services/supabase_collabnote_service.dart';

class ProjectUpdateRepository {
  final SupabaseCollabNoteService _service;

  ProjectUpdateRepository(this._service);

  Future<List<ProjectUpdate>> getUpdates() async {
    return await _service.fetchProjectUpdates();
  }
}