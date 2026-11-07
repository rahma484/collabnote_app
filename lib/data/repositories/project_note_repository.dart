import '../../domain/models/project_note.dart';
import '../services/supabase_collabnote_service.dart';

class ProjectNoteRepository {
  final SupabaseCollabNoteService _service;

  ProjectNoteRepository(this._service);

  Future<List<ProjectNote>> getNotes() async {
    return await _service.fetchProjectNotes();
  }
}