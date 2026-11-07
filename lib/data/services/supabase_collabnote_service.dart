import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/project_note.dart';
import '../../domain/models/task_item.dart';
import '../../domain/models/project_update.dart';

class SupabaseCollabNoteService {
  final _supabase = Supabase.instance.client;

  // Mengambil Data Utama (Catatan Proyek)
  Future<List<ProjectNote>> fetchProjectNotes() async {
    final response = await _supabase.from('project_notes').select();
    return response.map((json) => ProjectNote.fromJson(json)).toList();
  }

  // Mengambil Data Aksi (Tugas Anggota)
  Future<List<TaskItem>> fetchTaskItems() async {
    final response = await _supabase.from('task_items').select();
    return response.map((json) => TaskItem.fromJson(json)).toList();
  }

  // Update status tugas ke Supabase (saat checklist dicentang)
  Future<void> updateTaskCompletion(String id, bool isCompleted) async {
    await _supabase
        .from('task_items')
        .update({'isCompleted': isCompleted})
        .eq('id', id);
  }

  // Mengambil Data Informasi (Update Proyek)
  Future<List<ProjectUpdate>> fetchProjectUpdates() async {
    final response = await _supabase.from('project_updates').select();
    return response.map((json) => ProjectUpdate.fromJson(json)).toList();
  }
}