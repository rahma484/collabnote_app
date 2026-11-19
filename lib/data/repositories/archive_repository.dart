import '../../domain/models/archive_model.dart';
import '../services/collab_note_service.dart';
import 'base_repository.dart';

/// Repository data informasi: arsip penugasan yang telah selesai.
class ArchiveRepository extends BaseRepository {
  ArchiveRepository(this._service);

  final CollabNoteService _service;
  static const String _collection = 'archives';

  List<ArchiveModel> _items = [];

  /// Arsip terbaru di atas.
  List<ArchiveModel> get all {
    final list = [..._items];
    list.sort((a, b) => b.archivedAt.compareTo(a.archivedAt));
    return list;
  }

  @override
  Future<void> loadData() async {
    final rows = await _service.fetchCollection(_collection);
    _items = rows.map(ArchiveModel.fromJson).toList();
  }

  Future<void> _save() => _service.saveCollection(_collection, _items.map((e) => e.toJson()).toList());

  ArchiveModel? byId(String id) {
    for (final a in _items) {
      if (a.id == id) return a;
    }
    return null;
  }

  ArchiveModel? byAssignment(String assignmentId) {
    for (final a in _items) {
      if (a.assignmentId == assignmentId) return a;
    }
    return null;
  }

  Future<void> add(ArchiveModel archive) async {
    _items.removeWhere((a) => a.assignmentId == archive.assignmentId);
    _items.add(archive);
    notifyListeners();
    await _save();
  }

  Future<void> removeByAssignment(String assignmentId) async {
    _items.removeWhere((a) => a.assignmentId == assignmentId);
    notifyListeners();
    await _save();
  }
}
