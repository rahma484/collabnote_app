import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../dummy/dummy_data.dart';

/// Satu-satunya "server" simulasi aplikasi.
///
/// - Data contoh dibuat oleh [DummyData] pada penggunaan pertama.
/// - Seluruh data disimpan sebagai JSON di SharedPreferences, sehingga tetap ada
///   setelah aplikasi ditutup dan dibuka kembali (Local Storage).
/// - Future.delayed() mensimulasikan waktu tunggu jaringan.
class CollabNoteService {
  static const String _dbKey = 'collabnote_db_v1';

  Map<String, dynamic>? _db;

  Future<void> _ensureLoaded() async {
    if (_db != null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dbKey);
    if (raw != null) {
      try {
        _db = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        return;
      } catch (_) {
        // JSON rusak: lanjut membuat ulang data contoh.
      }
    }
    _db = DummyData.build();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dbKey, jsonEncode(_db));
  }

  /// Mengambil satu koleksi data (misalnya 'assignments').
  Future<List<Map<String, dynamic>>> fetchCollection(String name) async {
    await Future.delayed(const Duration(milliseconds: 250));
    await _ensureLoaded();
    if (name == 'user') {
      final id = _db!['activeAccountId'] as String?;
      final profiles = _db!['profiles'];
      if (id != null && profiles is Map && profiles[id] is Map) {
        return [Map<String, dynamic>.from(profiles[id] as Map)];
      }
      return [];
    }
    final raw = _db![name];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  /// Menyimpan ulang satu koleksi data ke Local Storage.
  Future<void> saveCollection(String name, List<Map<String, dynamic>> rows) async {
    await _ensureLoaded();
    if (name == 'user') {
      final id = _db!['activeAccountId'] as String?;
      if (id != null && rows.isNotEmpty) {
        final profiles = Map<String, dynamic>.from((_db!['profiles'] as Map?) ?? {});
        profiles[id] = rows.first;
        _db!['profiles'] = profiles;
      }
    } else {
      _db![name] = rows;
    }
    await _persist();
  }



  String? get activeAccountId => _db?['activeAccountId'] as String?;

  Future<bool> hasActiveAccount() async {
    await _ensureLoaded();
    return _db!['activeAccountId'] != null;
  }

  Future<String?> registerAccount({required String name, required String email, required String password, required String nim, required String university, required String studyProgram}) async {
    await _ensureLoaded();
    final accounts = List<Map<String, dynamic>>.from((_db!['accounts'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
    if (accounts.any((a) => (a['email'] as String).toLowerCase() == email.trim().toLowerCase())) return null;
    final id = 'acc_${DateTime.now().microsecondsSinceEpoch}';
    accounts.add({'id': id, 'name': name.trim(), 'email': email.trim().toLowerCase(), 'password': password});
    _db!['accounts'] = accounts;
    final profiles = Map<String, dynamic>.from((_db!['profiles'] as Map?) ?? {});
    profiles[id] = {'id': id, 'name': name.trim(), 'nim': nim.trim(), 'university': university.trim(), 'faculty': '', 'studyProgram': studyProgram.trim(), 'semester': 1, 'deadlineReminder': true, 'textSize': 1};
    _db!['profiles'] = profiles;
    _db!['activeAccountId'] = id;
    await _persist();
    return id;
  }

  Future<bool> loginAccount({required String email, required String password}) async {
    await _ensureLoaded();
    final accounts = List<Map<String, dynamic>>.from((_db!['accounts'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
    for (final account in accounts) {
      if ((account['email'] as String).toLowerCase() == email.trim().toLowerCase() && account['password'] == password) {
        _db!['activeAccountId'] = account['id'];
        await _persist();
        return true;
      }
    }
    return false;
  }

  Future<void> logoutAccount() async {
    await _ensureLoaded();
    _db!.remove('activeAccountId');
    await _persist();
  }

  Future<bool> joinGroupByCode(String code) async {
    await _ensureLoaded();
    final id = _db!['activeAccountId'] as String?;
    if (id == null) return false;
    final accounts = List<Map<String, dynamic>>.from((_db!['accounts'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
    final account = accounts.firstWhere((a) => a['id'] == id);
    final groups = List<Map<String, dynamic>>.from((_db!['groups'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
    Map<String, dynamic>? group;
    for (final candidate in groups) { if ((candidate['inviteCode'] as String? ?? '').toUpperCase() == code.trim().toUpperCase()) { group = candidate; break; } }
    final matchedGroup = group;
    if (matchedGroup == null) return false;
    final members = List<Map<String, dynamic>>.from((_db!['members'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
    if (members.any((m) => m['groupId'] == matchedGroup['id'] && m['userId'] == id)) return true;
    members.add({'id': 'm_${DateTime.now().microsecondsSinceEpoch}', 'groupId': matchedGroup['id'], 'name': account['name'], 'role': 'anggota', 'status': 'aktif', 'isMe': false, 'userId': id, 'joinedAt': DateTime.now().toIso8601String()});
    _db!['members'] = members;
    await _persist();
    return true;
  }

  /// Mengembalikan seluruh data ke data contoh awal.
  Future<void> resetToSampleData() async {
    await _ensureLoaded();
    final accounts = _db!['accounts'];
    final profiles = _db!['profiles'];
    final active = _db!['activeAccountId'];
    _db = DummyData.build();
    if (accounts != null) _db!['accounts'] = accounts;
    if (profiles != null) _db!['profiles'] = profiles;
    if (active != null) _db!['activeAccountId'] = active;
    await _persist();
  }
}
