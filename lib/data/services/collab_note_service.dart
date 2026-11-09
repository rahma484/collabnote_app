
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/project.dart';
import '../../domain/models/task.dart';
import '../../domain/models/asset_link.dart';

class CollabNoteService {
  final SupabaseClient _supabase;

  CollabNoteService(this._supabase);

  // Jeda asynchronous sesuai ketentuan tugas.
  // Data tetap diambil langsung dari Supabase.
  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // ==========================================
  // PROJECT
  // ==========================================

  Future<List<Project>> fetchProjects() async {
    await _simulateDelay();

    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Pengguna belum login.');
    }

    final response = await _supabase
        .from('projects')
        .select()
        .eq('owner_id', user.id)
        .order('created_at', ascending: false);

    return response
        .map((json) => Project.fromJson(json))
        .toList();
  }

  Future<Project> createProject({
    required String title,
    String? description,
    required String category,
    required String projectType,
    DateTime? deadline,
  }) async {
    await _simulateDelay();

    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Pengguna belum login.');
    }

    final response = await _supabase
        .from('projects')
        .insert({
          'owner_id': user.id,
          'title': title,
          'description': description,
          'category': category,
          'project_type': projectType,
          'deadline': deadline?.toIso8601String().split('T').first,
        })
        .select()
        .single();

    return Project.fromJson(response);
  }

  Future<void> deleteProject(String projectId) async {
    await _simulateDelay();

    await _supabase
        .from('projects')
        .delete()
        .eq('id', projectId);
  }

  // ==========================================
  // TASK
  // ==========================================

  Future<List<Task>> fetchTasks(String projectId) async {
    await _simulateDelay();

    final response = await _supabase
        .from('tasks')
        .select()
        .eq('project_id', projectId)
        .order('created_at');

    return response
        .map((json) => Task.fromJson(json))
        .toList();
  }

  Future<Task> createTask({
    required String projectId,
    required String title,
    String? assignee,
  }) async {
    await _simulateDelay();

    final response = await _supabase
        .from('tasks')
        .insert({
          'project_id': projectId,
          'title': title,
          'assignee': assignee,
          'status': 'To Do',
          'is_completed': false,
        })
        .select()
        .single();

    return Task.fromJson(response);
  }

  Future<Task> updateTask(Task task) async {
    await _simulateDelay();

    final response = await _supabase
        .from('tasks')
        .update({
          'title': task.title,
          'assignee': task.assignee,
          'status': task.status,
          'is_completed': task.isCompleted,
        })
        .eq('id', task.id)
        .select()
        .single();

    return Task.fromJson(response);
  }

  Future<void> deleteTask(String taskId) async {
    await _simulateDelay();

    await _supabase
        .from('tasks')
        .delete()
        .eq('id', taskId);
  }

  // ==========================================
  // ASSET LINKS
  // ==========================================

  Future<List<AssetLink>> fetchAssetLinks(
    String projectId,
  ) async {
    await _simulateDelay();

    final response = await _supabase
        .from('asset_links')
        .select()
        .eq('project_id', projectId)
        .order('created_at', ascending: false);

    return response
        .map((json) => AssetLink.fromJson(json))
        .toList();
  }

  Future<AssetLink> createAssetLink({
    required String projectId,
    required String title,
    required String url,
    required String category,
  }) async {
    await _simulateDelay();

    final response = await _supabase
        .from('asset_links')
        .insert({
          'project_id': projectId,
          'title': title,
          'url': url,
          'category': category,
        })
        .select()
        .single();

    return AssetLink.fromJson(response);
  }

  Future<void> deleteAssetLink(String assetLinkId) async {
    await _simulateDelay();

    await _supabase
        .from('asset_links')
        .delete()
        .eq('id', assetLinkId);
  }

  // ==========================================
  // REALTIME
  // ==========================================

  Stream<List<Map<String, dynamic>>> streamTasks(
    String projectId,
  ) {
    return _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('project_id', projectId);
  }

  Stream<List<Map<String, dynamic>>> streamAssetLinks(
    String projectId,
  ) {
    return _supabase
        .from('asset_links')
        .stream(primaryKey: ['id'])
        .eq('project_id', projectId);
  }
}
