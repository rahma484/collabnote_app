import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/models/template_model.dart';
import '../dummy/template_catalog.dart';
import '../services/collab_note_service.dart';
import '../services/local_file_service.dart';
import 'base_repository.dart';

/// Repository Smart Template Gallery: katalog bawaan + template milik sendiri,
/// ditambah daftar favorit dan template yang baru digunakan.
class TemplateRepository extends BaseRepository {
  TemplateRepository(this._service, this._files);

  final CollabNoteService _service;
  final LocalFileService _files;

  static const String _customCollection = 'customTemplates';
  static const String _prefsCollection = 'templatePrefs';

  List<TemplateModel> _custom = [];
  List<String> _favorites = [];
  List<String> _recent = [];

  @override
  Future<void> loadData() async {
    final custom = await _service.fetchCollection(_customCollection);
    _custom = custom.map(TemplateModel.fromJson).toList();
    final prefs = await _service.fetchCollection(_prefsCollection);
    if (prefs.isNotEmpty) {
      _favorites = (prefs.first['favorites'] as List? ?? []).map((e) => e.toString()).toList();
      _recent = (prefs.first['recent'] as List? ?? []).map((e) => e.toString()).toList();
    }
  }

  List<TemplateModel> get all => [...TemplateCatalog.all, ..._custom];

  List<TemplateModel> get customTemplates => List.unmodifiable(_custom);

  TemplateModel? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  bool isFavorite(String id) => _favorites.contains(id);

  List<TemplateModel> get favorites => _favorites.map(byId).whereType<TemplateModel>().toList();

  List<TemplateModel> get recent => _recent.map(byId).whereType<TemplateModel>().toList();

  Future<void> _savePrefs() => _service.saveCollection(_prefsCollection, [
        {'favorites': _favorites, 'recent': _recent}
      ]);

  Future<void> toggleFavorite(String id) async {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
    notifyListeners();
    await _savePrefs();
  }

  /// Dicatat setiap kali template dipakai ("Template yang baru digunakan").
  Future<void> markUsed(String id) async {
    _recent.remove(id);
    _recent.insert(0, id);
    if (_recent.length > 5) _recent = _recent.sublist(0, 5);
    notifyListeners();
    await _savePrefs();
  }

  /// Custom Template: pengguna memakai file miliknya sendiri sebagai template.
  Future<TemplateModel?> addCustomFromFile() async {
    final picked = await _files.pickFile();
    if (picked == null) return null;
    final path = await _files.saveBytes(picked.name, picked.bytes);
    final dot = picked.name.lastIndexOf('.');
    final title = dot > 0 ? picked.name.substring(0, dot) : picked.name;
    final template = TemplateModel(
      id: newId('custom'),
      category: TemplateCategory.custom,
      title: title,
      format: picked.extension.isEmpty ? 'File' : picked.extension.toUpperCase(),
      extension: picked.extension,
      description: 'File milik sendiri yang dipakai sebagai template.',
      usage: 'Gunakan untuk pekerjaan yang formatnya sudah Anda siapkan sendiri.',
      localPath: path,
      previewLines: ['File: ${picked.name}', 'Ukuran: ${picked.bytes.length} byte'],
    );
    _custom.add(template);
    notifyListeners();
    await _service.saveCollection(_customCollection, _custom.map((e) => e.toJson()).toList());
    return template;
  }

  /// Isi file template (untuk diunduh). null bila file tidak ditemukan.
  Future<Uint8List?> bytesOf(TemplateModel t) async {
    final local = await _files.readBytes(t.localPath);
    if (local != null) return local;
    if (t.assetPath.isEmpty) return null;
    final data = await rootBundle.load(t.assetPath);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<void> deleteCustom(String id) async {
    final i = _custom.indexWhere((t) => t.id == id);
    if (i < 0) return;
    await _files.delete(_custom[i].localPath);
    _custom.removeAt(i);
    _favorites.remove(id);
    _recent.remove(id);
    notifyListeners();
    await _service.saveCollection(_customCollection, _custom.map((e) => e.toJson()).toList());
    await _savePrefs();
  }
}
