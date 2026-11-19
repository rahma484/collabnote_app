import '../../domain/models/task_step_model.dart';
import '../services/collab_note_service.dart';
import 'base_repository.dart';

/// Repository data aksi (tahapan pengerjaan). Berupa ChangeNotifier sehingga Beranda,
/// progres, dan badge tab ikut berubah saat tahapan dicentang.
class TaskStepRepository extends BaseRepository {
  TaskStepRepository(this._service);

  final CollabNoteService _service;
  static const String _collection = 'steps';

  List<TaskStepModel> _items = [];

  List<TaskStepModel> get all => List.unmodifiable(_items);

  @override
  Future<void> loadData() async {
    final rows = await _service.fetchCollection(_collection);
    _items = rows.map(TaskStepModel.fromJson).toList();
  }

  Future<void> _save() => _service.saveCollection(_collection, _items.map((e) => e.toJson()).toList());

  List<TaskStepModel> stepsOf(String assignmentId) {
    final list = _items.where((s) => s.assignmentId == assignmentId).toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  List<TaskStepModel> pendingOf(String assignmentId) => stepsOf(assignmentId).where((s) => !s.isDone).toList();

  List<TaskStepModel> doneOf(String assignmentId) => stepsOf(assignmentId).where((s) => s.isDone).toList();

  int totalOf(String assignmentId) => _items.where((s) => s.assignmentId == assignmentId).length;

  int doneCountOf(String assignmentId) => _items.where((s) => s.assignmentId == assignmentId && s.isDone).length;

  int _nextOrder(String assignmentId) {
    var max = -1;
    for (final s in _items) {
      if (s.assignmentId == assignmentId && s.order > max) max = s.order;
    }
    return max + 1;
  }

  Future<void> add(String workspaceId, String assignmentId, String title) async {
    _items.add(TaskStepModel(
      id: newId('s'),
      workspaceId: workspaceId,
      assignmentId: assignmentId,
      title: title.trim(),
      order: _nextOrder(assignmentId),
      createdAt: DateTime.now(),
    ));
    notifyListeners();
    await _save();
  }

  Future<void> addMany(String workspaceId, String assignmentId, List<String> titles) async {
    for (final t in titles) {
      _items.add(TaskStepModel(
        id: newId('s'),
        workspaceId: workspaceId,
        assignmentId: assignmentId,
        title: t,
        order: _nextOrder(assignmentId),
        createdAt: DateTime.now(),
      ));
    }
    notifyListeners();
    await _save();
  }

  Future<void> rename(String id, String title) async {
    final i = _items.indexWhere((s) => s.id == id);
    if (i < 0) return;
    _items[i] = _items[i].copyWith(title: title.trim());
    notifyListeners();
    await _save();
  }

  Future<void> toggle(String id) async {
    final i = _items.indexWhere((s) => s.id == id);
    if (i < 0) return;
    final step = _items[i];
    _items[i] = step.isDone
        ? step.copyWith(isDone: false, clearCompletedAt: true)
        : step.copyWith(isDone: true, completedAt: DateTime.now());
    notifyListeners();
    await _save();
  }

  Future<void> delete(String id) async {
    _items.removeWhere((s) => s.id == id);
    notifyListeners();
    await _save();
  }

  /// Mengatur ulang urutan tahapan yang belum selesai (drag and drop).
  Future<void> reorderPending(String assignmentId, int oldIndex, int newIndex) async {
    final pending = pendingOf(assignmentId);
    if (oldIndex < 0 || oldIndex >= pending.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = pending.removeAt(oldIndex);
    pending.insert(newIndex.clamp(0, pending.length), moved);
    final ordered = [...pending, ...doneOf(assignmentId)];
    for (var n = 0; n < ordered.length; n++) {
      final i = _items.indexWhere((s) => s.id == ordered[n].id);
      if (i >= 0) _items[i] = _items[i].copyWith(order: n);
    }
    notifyListeners();
    await _save();
  }

  Future<void> removeByAssignment(String assignmentId) async {
    _items.removeWhere((s) => s.assignmentId == assignmentId);
    notifyListeners();
    await _save();
  }
}
