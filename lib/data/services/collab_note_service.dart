
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/project.dart';
import '../../domain/models/task.dart';
import '../../domain/models/asset_link.dart';
import '../../domain/models/profile.dart';

class CollabNoteService {
  final SupabaseClient _supabase;

  CollabNoteService(this._supabase);

  // Jeda asynchronous sesuai ketentuan tugas.
  // Data tetap diambil langsung dari Supabase.
  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // ==========================================
  // AUTH & PROFILE
  // ==========================================

  bool get isLoggedIn => _supabase.auth.currentSession != null;

  String? get currentUserEmail => _supabase.auth.currentUser?.email;

  /// Emit true saat ada sesi aktif, false saat keluar.
  Stream<bool> get authChanges {
    return _supabase.auth.onAuthStateChange
        .map((state) => state.session != null)
        .distinct();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception(_authMessage(e));
    }
  }

  /// Mengembalikan true jika sesi langsung aktif.
  /// Mengembalikan false jika Supabase meminta konfirmasi email dulu.
  Future<bool> signUp({
    required String fullName,
    required String studyProgram,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'study_program': studyProgram,
        },
      );

      final user = response.user;

      if (response.session != null && user != null) {
        try {
          await _supabase.from('profiles').upsert({
            'id': user.id,
            'full_name': fullName,
            'study_program': studyProgram,
          });
        } catch (_) {
          // Profil juga dibuat oleh trigger di database
          // (lihat supabase_schema.sql), jadi kegagalan di sini
          // tidak membatalkan pendaftaran.
        }
        return true;
      }

      return false;
    } on AuthException catch (e) {
      throw Exception(_authMessage(e));
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<Profile?> fetchProfile() async {
    final user = _supabase.auth.currentUser;

    if (user == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;

    return Profile.fromJson(response);
  }

  String _authMessage(AuthException e) {
    final message = e.message.toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'Email atau password salah.';
    }
    if (message.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi. Cek kotak masuk emailmu.';
    }
    if (message.contains('already registered')) {
      return 'Email sudah terdaftar. Silakan masuk.';
    }
    if (message.contains('password')) {
      return 'Password tidak memenuhi syarat (minimal 6 karakter).';
    }

    return e.message;
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

  /// Membuat banyak tugas sekaligus (dipakai oleh template proyek).
  Future<void> createDefaultTasks(
    String projectId,
    List<String> titles,
  ) async {
    if (titles.isEmpty) return;

    final now = DateTime.now().toUtc();

    await _supabase.from('tasks').insert([
      for (var i = 0; i < titles.length; i++)
        {
          'project_id': projectId,
          'title': titles[i],
          'status': 'To Do',
          'is_completed': false,
          // Selisih 1 ms agar urutan template tetap terjaga.
          'created_at': now.add(Duration(milliseconds: i)).toIso8601String(),
        },
    ]);
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
