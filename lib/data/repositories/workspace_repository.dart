import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/models/document_model.dart';
import '../../domain/models/note_model.dart';
import '../../domain/models/reference_model.dart';
import '../../domain/models/template_model.dart';
import '../../domain/models/workspace_model.dart';
import '../services/collab_note_service.dart';
import '../services/local_file_service.dart';
import 'base_repository.dart';

/// Repository isi Ruang Kerja: workspace, catatan, dokumen, dan referensi.
/// Semua data memiliki assignmentId sehingga selalu terhubung ke penugasan induknya.
class WorkspaceRepository extends BaseRepository {
  WorkspaceRepository(this._service, this._files);

  final CollabNoteService _service;
  final LocalFileService _files;

  List<WorkspaceModel> _workspaces = [];
  List<NoteModel> _notes = [];
  List<DocumentModel> _documents = [];
  List<ReferenceModel> _references = [];

  @override
  Future<void> loadData() async {
    final results = await Future.wait([
      _service.fetchCollection('workspaces'),
      _service.fetchCollection('notes'),
      _service.fetchCollection('documents'),
      _service.fetchCollection('references'),
    ]);
    _workspaces = results[0].map(WorkspaceModel.fromJson).toList();
    _notes = results[1].map(NoteModel.fromJson).toList();
    _documents = results[2].map(DocumentModel.fromJson).toList();
    _references = results[3].map(ReferenceModel.fromJson).toList();
  }

  Future<void> _saveWorkspaces() =>
      _service.saveCollection('workspaces', _workspaces.map((e) => e.toJson()).toList());
  Future<void> _saveNotes() => _service.saveCollection('notes', _notes.map((e) => e.toJson()).toList());
  Future<void> _saveDocuments() =>
      _service.saveCollection('documents', _documents.map((e) => e.toJson()).toList());
  Future<void> _saveReferences() =>
      _service.saveCollection('references', _references.map((e) => e.toJson()).toList());

  // ---------------------------------------------------------------- Workspace

  WorkspaceModel? workspaceOf(String assignmentId) {
    for (final w in _workspaces) {
      if (w.assignmentId == assignmentId) return w;
    }
    return null;
  }

  Future<WorkspaceModel> createWorkspace(String assignmentId) async {
    final ws = WorkspaceModel(id: newId('w'), assignmentId: assignmentId, createdAt: DateTime.now());
    _workspaces.add(ws);
    notifyListeners();
    await _saveWorkspaces();
    return ws;
  }

  Future<void> setFinalSummary(String workspaceId, String summary) async {
    final i = _workspaces.indexWhere((w) => w.id == workspaceId);
    if (i < 0) return;
    _workspaces[i] = _workspaces[i].copyWith(finalSummary: summary);
    notifyListeners();
    await _saveWorkspaces();
  }

  // ------------------------------------------------------------------ Catatan

  List<NoteModel> notesOf(String assignmentId) {
    final list = _notes.where((n) => n.assignmentId == assignmentId).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Future<void> addNote({
    required String workspaceId,
    required String assignmentId,
    required String title,
    required String content,
    required String authorName,
  }) async {
    final now = DateTime.now();
    _notes.add(NoteModel(
      id: newId('n'),
      workspaceId: workspaceId,
      assignmentId: assignmentId,
      title: title.trim(),
      content: content.trim(),
      authorName: authorName,
      createdAt: now,
      updatedAt: now,
    ));
    notifyListeners();
    await _saveNotes();
  }

  Future<void> updateNote(String id, {required String title, required String content}) async {
    final i = _notes.indexWhere((n) => n.id == id);
    if (i < 0) return;
    _notes[i] = _notes[i].copyWith(title: title.trim(), content: content.trim(), updatedAt: DateTime.now());
    notifyListeners();
    await _saveNotes();
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
    await _saveNotes();
  }

  // --------------------------------------------------------------- Referensi

  List<ReferenceModel> referencesOf(String assignmentId) {
    final list = _references.where((r) => r.assignmentId == assignmentId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> addReference({
    required String workspaceId,
    required String assignmentId,
    required String title,
    required String url,
    required ReferenceType type,
    required String note,
  }) async {
    _references.add(ReferenceModel(
      id: newId('r'),
      workspaceId: workspaceId,
      assignmentId: assignmentId,
      title: title.trim(),
      url: url.trim(),
      type: type,
      note: note.trim(),
      createdAt: DateTime.now(),
    ));
    notifyListeners();
    await _saveReferences();
  }

  Future<void> updateReference(
    String id, {
    required String title,
    required String url,
    required ReferenceType type,
    required String note,
  }) async {
    final i = _references.indexWhere((r) => r.id == id);
    if (i < 0) return;
    _references[i] = _references[i].copyWith(title: title.trim(), url: url.trim(), type: type, note: note.trim());
    notifyListeners();
    await _saveReferences();
  }

  Future<void> deleteReference(String id) async {
    _references.removeWhere((r) => r.id == id);
    notifyListeners();
    await _saveReferences();
  }

  // ----------------------------------------------------------------- Dokumen

  List<DocumentModel> documentsOf(String assignmentId) {
    final list = _documents.where((d) => d.assignmentId == assignmentId).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  /// Menambahkan template ke Ruang Kerja sebagai dokumen kerja (draft).
  Future<DocumentModel> addFromTemplate(String workspaceId, String assignmentId, TemplateModel template) async {
    final now = DateTime.now();
    final doc = DocumentModel(
      id: newId('d'),
      workspaceId: workspaceId,
      assignmentId: assignmentId,
      title: template.title,
      fileName: template.fileName,
      extension: template.extension,
      kind: DocumentKind.draft,
      source: DocumentSource.template,
      assetPath: template.assetPath.isEmpty ? null : template.assetPath,
      localPath: template.localPath,
      templateId: template.id,
      createdAt: now,
      updatedAt: now,
    );
    _documents.add(doc);
    notifyListeners();
    await _saveDocuments();
    return doc;
  }

  /// Membuat dokumen teks (.md) yang dapat diedit langsung di aplikasi.
  Future<DocumentModel> addTextDocument({
    required String workspaceId,
    required String assignmentId,
    required String title,
    required String text,
    DocumentKind kind = DocumentKind.draft,
    DocumentSource source = DocumentSource.created,
  }) async {
    final now = DateTime.now();
    final doc = DocumentModel(
      id: newId('d'),
      workspaceId: workspaceId,
      assignmentId: assignmentId,
      title: title.trim(),
      fileName: '${title.trim()}.md',
      extension: 'md',
      kind: kind,
      source: source,
      textContent: text,
      size: utf8.encode(text).length,
      createdAt: now,
      updatedAt: now,
    );
    _documents.add(doc);
    notifyListeners();
    await _saveDocuments();
    return doc;
  }

  Future<void> updateTextDocument(String id, {required String title, required String text}) async {
    final i = _documents.indexWhere((d) => d.id == id);
    if (i < 0) return;
    _documents[i] = _documents[i].copyWith(
      title: title.trim(),
      fileName: '${title.trim()}.md',
      textContent: text,
      size: utf8.encode(text).length,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _saveDocuments();
  }

  Future<DocumentModel> addUploadedFile({
    required String workspaceId,
    required String assignmentId,
    required PickedFileData file,
    required DocumentKind kind,
  }) async {
    final path = await _files.saveBytes(file.name, file.bytes);
    final now = DateTime.now();
    final dot = file.name.lastIndexOf('.');
    final doc = DocumentModel(
      id: newId('d'),
      workspaceId: workspaceId,
      assignmentId: assignmentId,
      title: dot > 0 ? file.name.substring(0, dot) : file.name,
      fileName: file.name,
      extension: file.extension,
      kind: kind,
      source: DocumentSource.uploaded,
      localPath: path,
      size: file.bytes.length,
      createdAt: now,
      updatedAt: now,
    );
    _documents.add(doc);
    notifyListeners();
    await _saveDocuments();
    return doc;
  }

  /// Mengganti isi dokumen dengan versi hasil pengerjaan (file yang sudah diedit di aplikasi lain).
  Future<void> replaceFile(String id, PickedFileData file) async {
    final i = _documents.indexWhere((d) => d.id == id);
    if (i < 0) return;
    final old = _documents[i];
    final path = await _files.saveBytes(file.name, file.bytes);
    if (old.source != DocumentSource.template || old.assetPath == null) {
      await _files.delete(old.localPath);
    }
    _documents[i] = DocumentModel(
      id: old.id,
      workspaceId: old.workspaceId,
      assignmentId: old.assignmentId,
      title: old.title,
      fileName: file.name,
      extension: file.extension,
      kind: old.kind,
      source: old.source,
      localPath: path,
      assetPath: old.assetPath,
      templateId: old.templateId,
      size: file.bytes.length,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _saveDocuments();
  }

  Future<void> setFinal(String id, bool isFinal) async {
    final i = _documents.indexWhere((d) => d.id == id);
    if (i < 0) return;
    _documents[i] = _documents[i].copyWith(
      kind: isFinal ? DocumentKind.finalDoc : DocumentKind.draft,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _saveDocuments();
  }

  Future<void> deleteDocument(String id) async {
    final i = _documents.indexWhere((d) => d.id == id);
    if (i < 0) return;
    final doc = _documents[i];
    if (doc.source != DocumentSource.template || doc.assetPath == null) {
      await _files.delete(doc.localPath);
    }
    _documents.removeAt(i);
    notifyListeners();
    await _saveDocuments();
  }

  /// Isi file dokumen (untuk diunduh). null bila file tidak tersedia.
  Future<Uint8List?> bytesOf(DocumentModel doc) async {
    if (doc.textContent != null) {
      return Uint8List.fromList(utf8.encode(doc.textContent!));
    }
    final local = await _files.readBytes(doc.localPath);
    if (local != null) return local;
    if (doc.assetPath != null) {
      final data = await rootBundle.load(doc.assetPath!);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    }
    return null;
  }

  // ------------------------------------------------------------------ Hapus

  /// Menghapus seluruh isi ruang kerja saat penugasan dihapus.
  Future<void> removeByAssignment(String assignmentId) async {
    for (final d in _documents.where((d) => d.assignmentId == assignmentId)) {
      if (d.source != DocumentSource.template || d.assetPath == null) {
        await _files.delete(d.localPath);
      }
    }
    _workspaces.removeWhere((w) => w.assignmentId == assignmentId);
    _notes.removeWhere((n) => n.assignmentId == assignmentId);
    _documents.removeWhere((d) => d.assignmentId == assignmentId);
    _references.removeWhere((r) => r.assignmentId == assignmentId);
    notifyListeners();
    await Future.wait([_saveWorkspaces(), _saveNotes(), _saveDocuments(), _saveReferences()]);
  }
}
