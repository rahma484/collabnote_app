import 'dart:math';

import '../../domain/models/group_member_model.dart';
import '../../domain/models/group_model.dart';
import '../../domain/models/submission_model.dart';
import '../../domain/models/work_item_model.dart';
import '../services/collab_note_service.dart';
import '../services/local_file_service.dart';
import 'base_repository.dart';

/// Repository mode kelompok: kelompok, anggota (simulasi), bagian pekerjaan, dan pengumpulan hasil.
/// Untuk penugasan individu repository ini tidak berisi data apa pun.
class GroupRepository extends BaseRepository {
  GroupRepository(this._service, this._files);

  final CollabNoteService _service;
  final LocalFileService _files;

  List<GroupModel> _groups = [];
  List<GroupMemberModel> _members = [];
  List<WorkItemModel> _items = [];
  List<SubmissionModel> _submissions = [];

  @override
  Future<void> loadData() async {
    final r = await Future.wait([
      _service.fetchCollection('groups'),
      _service.fetchCollection('members'),
      _service.fetchCollection('workItems'),
      _service.fetchCollection('submissions'),
    ]);
    _groups = r[0].map(GroupModel.fromJson).toList();
    _members = r[1].map(GroupMemberModel.fromJson).toList();
    _items = r[2].map(WorkItemModel.fromJson).toList();
    _submissions = r[3].map(SubmissionModel.fromJson).toList();
  }

  Future<void> _saveGroups() => _service.saveCollection('groups', _groups.map((e) => e.toJson()).toList());
  Future<void> _saveMembers() => _service.saveCollection('members', _members.map((e) => e.toJson()).toList());
  Future<void> _saveItems() => _service.saveCollection('workItems', _items.map((e) => e.toJson()).toList());
  Future<void> _saveSubmissions() =>
      _service.saveCollection('submissions', _submissions.map((e) => e.toJson()).toList());

  // ------------------------------------------------------------------ Kelompok

  GroupModel? groupOf(String assignmentId) {
    for (final g in _groups) {
      if (g.assignmentId == assignmentId) return g;
    }
    return null;
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    return List.generate(5, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  /// Membuat kelompok baru. Pembuat otomatis menjadi Pemilik Kelompok.
  Future<GroupModel> createGroup({
    required String assignmentId,
    required String name,
    required String ownerName,
  }) async {
    final group = GroupModel(
      id: newId('g'),
      assignmentId: assignmentId,
      name: name.trim(),
      inviteCode: _generateCode(),
      createdAt: DateTime.now(),
    );
    _groups.add(group);
    _members.add(GroupMemberModel(
      id: newId('m'),
      groupId: group.id,
      name: ownerName,
      role: MemberRole.pemilik,
      status: MemberStatus.aktif,
      isMe: true,
      userId: _service.activeAccountId,
      joinedAt: DateTime.now(),
    ));
    notifyListeners();
    await Future.wait([_saveGroups(), _saveMembers()]);
    return group;
  }

  // ------------------------------------------------------------------ Anggota

  List<GroupMemberModel> membersOf(String groupId) {
    final list = _members.where((m) => m.groupId == groupId).toList();
    list.sort((a, b) {
      if (a.isOwner != b.isOwner) return a.isOwner ? -1 : 1;
      return a.joinedAt.compareTo(b.joinedAt);
    });
    return list;
  }

  GroupMemberModel? memberById(String id) {
    for (final m in _members) {
      if (m.id == id) return m;
    }
    return null;
  }

  GroupMemberModel? me(String groupId) {
    final accountId = _service.activeAccountId;
    for (final m in _members) {
      if (m.groupId == groupId && ((accountId != null && m.userId == accountId) || (accountId == null && m.isMe))) return m;
    }
    return null;
  }

  bool isOwner(String groupId) => me(groupId)?.isOwner ?? false;

  /// Mengundang anggota melalui kode undangan (disimulasikan lokal).
  Future<void> inviteMember(String groupId, String name, {bool joined = false}) async {
    _members.add(GroupMemberModel(
      id: newId('m'),
      groupId: groupId,
      name: name.trim(),
      role: MemberRole.anggota,
      status: joined ? MemberStatus.aktif : MemberStatus.diundang,
      joinedAt: DateTime.now(),
    ));
    notifyListeners();
    await _saveMembers();
  }

  Future<void> confirmMember(String memberId) async {
    final i = _members.indexWhere((m) => m.id == memberId);
    if (i < 0) return;
    _members[i] = _members[i].copyWith(status: MemberStatus.aktif);
    notifyListeners();
    await _saveMembers();
  }

  /// Menghapus anggota. Pekerjaannya dialihkan ke pemilik agar setiap bagian tetap punya penanggung jawab.
  Future<void> removeMember(String memberId) async {
    final i = _members.indexWhere((m) => m.id == memberId);
    if (i < 0 || _members[i].isOwner) return;
    final member = _members[i];
    final owner = membersOf(member.groupId).firstWhere((m) => m.isOwner, orElse: () => member);
    for (var n = 0; n < _items.length; n++) {
      if (_items[n].assigneeId == memberId) {
        _items[n] = _items[n].copyWith(assigneeId: owner.id, updatedAt: DateTime.now());
      }
    }
    _members.removeAt(i);
    notifyListeners();
    await Future.wait([_saveMembers(), _saveItems()]);
  }

  /// Dipanggil saat nama di Profil diubah, agar nama pada kelompok ikut berubah.
  Future<void> renameCurrentUser(String name) async {
    var changed = false;
    for (var i = 0; i < _members.length; i++) {
      if (((_service.activeAccountId != null && _members[i].userId == _service.activeAccountId) || (_service.activeAccountId == null && _members[i].isMe)) && _members[i].name != name) {
        final m = _members[i];
        _members[i] = GroupMemberModel(
          id: m.id,
          groupId: m.groupId,
          name: name,
          role: m.role,
          status: m.status,
          isMe: m.isMe,
          userId: m.userId,
          joinedAt: m.joinedAt,
        );
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      await _saveMembers();
    }
  }

  // ---------------------------------------------------------- Bagian pekerjaan

  List<WorkItemModel> itemsOfGroup(String groupId) {
    final list = _items.where((i) => i.groupId == groupId).toList();
    list.sort((a, b) => a.deadline.compareTo(b.deadline));
    return list;
  }

  List<WorkItemModel> itemsOfAssignment(String assignmentId) =>
      _items.where((i) => i.assignmentId == assignmentId).toList();

  List<WorkItemModel> itemsByStatus(String groupId, WorkStatus status) =>
      itemsOfGroup(groupId).where((i) => i.status == status).toList();

  Future<void> addItem({
    required String groupId,
    required String assignmentId,
    required String title,
    required String description,
    required String assigneeId,
    required DateTime deadline,
    WorkStatus status = WorkStatus.todo,
    String? attachmentPath,
    String? attachmentName,
  }) async {
    final now = DateTime.now();
    _items.add(WorkItemModel(
      id: newId('wi'),
      groupId: groupId,
      assignmentId: assignmentId,
      title: title.trim(),
      description: description.trim(),
      assigneeId: assigneeId,
      deadline: deadline,
      status: status,
      createdAt: now,
      updatedAt: now,
      attachmentPath: attachmentPath,
      attachmentName: attachmentName,
    ));
    notifyListeners();
    await _saveItems();
  }

  Future<void> updateItem(WorkItemModel item) async {
    final i = _items.indexWhere((e) => e.id == item.id);
    if (i < 0) return;
    _items[i] = item.copyWith(updatedAt: DateTime.now());
    notifyListeners();
    await _saveItems();
  }

  Future<void> deleteItem(String id) async {
    for (final s in _submissions.where((s) => s.workItemId == id)) {
      await _files.delete(s.localPath);
    }
    WorkItemModel? removed;
    for (final item in _items) { if (item.id == id) { removed = item; break; } }
    if (removed != null) await _files.delete(removed.attachmentPath);
    _items.removeWhere((i) => i.id == id);
    _submissions.removeWhere((s) => s.workItemId == id);
    notifyListeners();
    await Future.wait([_saveItems(), _saveSubmissions()]);
  }

  // --------------------------------------------------------------- Pengumpulan

  List<SubmissionModel> submissionsOf(String workItemId) {
    final list = _submissions.where((s) => s.workItemId == workItemId).toList();
    list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return list;
  }

  List<SubmissionModel> submissionsOfGroup(String groupId) => _submissions.where((s) => s.groupId == groupId).toList();

  /// Anggota mengunggah hasil. Status pekerjaan otomatis menjadi Review.
  Future<void> submit({
    required WorkItemModel item,
    required String memberId,
    required PickedFileData file,
    required String note,
  }) async {
    final path = await _files.saveBytes(file.name, file.bytes);
    _submissions.add(SubmissionModel(
      id: newId('sub'),
      workItemId: item.id,
      groupId: item.groupId,
      memberId: memberId,
      fileName: file.name,
      localPath: path,
      note: note.trim(),
      submittedAt: DateTime.now(),
    ));
    final i = _items.indexWhere((e) => e.id == item.id);
    if (i >= 0) {
      _items[i] = _items[i].copyWith(status: WorkStatus.review, updatedAt: DateTime.now());
    }
    notifyListeners();
    await Future.wait([_saveSubmissions(), _saveItems()]);
  }

  /// Pemeriksaan: Approved membuat pekerjaan Done, Revision mengembalikannya ke In Progress.
  Future<void> review({
    required String submissionId,
    required ReviewStatus status,
    required String note,
  }) async {
    final i = _submissions.indexWhere((s) => s.id == submissionId);
    if (i < 0) return;
    final sub = _submissions[i].copyWith(reviewStatus: status, reviewNote: note.trim());
    _submissions[i] = sub;
    final n = _items.indexWhere((e) => e.id == sub.workItemId);
    if (n >= 0) {
      if (status == ReviewStatus.approved) {
        _items[n] = _items[n].copyWith(status: WorkStatus.done, updatedAt: DateTime.now());
      } else if (status == ReviewStatus.revision) {
        _items[n] = _items[n].copyWith(status: WorkStatus.inProgress, updatedAt: DateTime.now());
      }
    }
    notifyListeners();
    await Future.wait([_saveSubmissions(), _saveItems()]);
  }

  // -------------------------------------------------------------------- Hapus

  Future<void> removeByAssignment(String assignmentId) async {
    final groupIds = _groups.where((g) => g.assignmentId == assignmentId).map((g) => g.id).toSet();
    for (final s in _submissions.where((s) => groupIds.contains(s.groupId))) {
      await _files.delete(s.localPath);
    }
    _groups.removeWhere((g) => groupIds.contains(g.id));
    _members.removeWhere((m) => groupIds.contains(m.groupId));
    _items.removeWhere((i) => groupIds.contains(i.groupId));
    _submissions.removeWhere((s) => groupIds.contains(s.groupId));
    notifyListeners();
    await Future.wait([_saveGroups(), _saveMembers(), _saveItems(), _saveSubmissions()]);
  }
}
