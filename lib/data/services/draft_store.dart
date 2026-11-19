import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Cache lokal untuk draf (catatan, dokumen teks) memakai SharedPreferences.
/// Draf disimpan otomatis saat mengetik dan dipulihkan bila editor dibuka kembali
/// (mis. aplikasi tertutup atau halaman tidak sengaja ditutup sebelum menyimpan).
class DraftStore {
  static const String _prefix = 'collabnote_draft_';

  Future<void> save(String key, Map<String, String> fields) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefix$key', jsonEncode(fields));
    } catch (_) {}
  }

  Future<Map<String, String>?> load(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$key');
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return null;
    }
  }

  Future<void> clear(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$key');
    } catch (_) {}
  }
}
