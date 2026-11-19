import 'dart:async';

import '../../core/date_utils.dart';
import '../../domain/models/archive_model.dart';
import '../../domain/models/assignment_model.dart';
import '../../domain/models/course_model.dart';
import '../../domain/models/document_model.dart';
import '../../domain/models/template_model.dart';
import '../../domain/models/work_item_model.dart';
import '../services/collab_note_service.dart';
import '../services/local_file_service.dart';
import 'archive_repository.dart';
import 'base_repository.dart';
import 'group_repository.dart';
import 'task_step_repository.dart';
import 'workspace_repository.dart';

/// Satu pekerjaan yang masih harus dikerjakan (tahapan individu atau bagian pekerjaan kelompok).
class PendingAction {
  final int seq;
  final String id;
  final String title;
  final String assignmentId;
  final String assignmentTitle;
  final DateTime deadline;
  final bool isGroupWork;

  const PendingAction({
    required this.seq,
    required this.id,
    required this.title,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.deadline,
    required this.isGroupWork,
  });
}

/// Repository data utama: penugasan + mata kuliah.
///
/// Penugasan adalah induk dari semua data. Repository ini juga mengatur operasi lintas data
/// (membuat ruang kerja, menghapus semua data turunan, finalisasi dan pengarsipan),
/// serta menghitung status dan progres otomatis dari aktivitas nyata.
class AssignmentRepository extends BaseRepository {
  AssignmentRepository(
    this._service,
    this._steps,
    this._workspaces,
    this._groups,
    this._archives,
  ) {
    // Bila tahapan/pekerjaan/arsip berubah, status & progres penugasan ikut dihitung ulang.
    _steps.addListener(_onDependencyChanged);
    _workspaces.addListener(_onDependencyChanged);
    _groups.addListener(_onDependencyChanged);
    _archives.addListener(_onDependencyChanged);
  }

  final CollabNoteService _service;
  final TaskStepRepository _steps;
  final WorkspaceRepository _workspaces;
  final GroupRepository _groups;
  final ArchiveRepository _archives;

  static const List<String> defaultStepTitles = [
    'Membaca instruksi',
    'Mengumpulkan materi',
    'Mempelajari referensi',
    'Menyusun draft',
    'Melakukan revisi',
    'Menyelesaikan hasil akhir',
  ];

  List<CourseModel> _courses = [];
  List<AssignmentModel> _assignments = [];

  // ------------------------------------------------------------------ Memuat

  @override
  Future<void> loadData() async {
    await Future.wait([_steps.load(), _workspaces.load(), _groups.load(), _archives.load()]);
    final c = await _service.fetchCollection('courses');
    final a = await _service.fetchCollection('assignments');
    _courses = c.map(CourseModel.fromJson).toList();
    _assignments = a.map(AssignmentModel.fromJson).toList();
    if (_recomputeStatuses()) {
      await _saveAssignments();
    }
  }

  Future<void> _saveAssignments() =>
      _service.saveCollection('assignments', _assignments.map((e) => e.toJson()).toList());

  Future<void> _saveCourses() => _service.saveCollection('courses', _courses.map((e) => e.toJson()).toList());

  void _onDependencyChanged() {
    if (!isLoaded) return;
    if (_recomputeStatuses()) {
      unawaited(_saveAssignments());
    }
    notifyListeners();
  }

  // ------------------------------------------------------------ Akses data

  /// Seluruh penugasan (aktif, selesai, dan diarsipkan), deadline terdekat di atas.
  List<AssignmentModel> get assignments {
    final list = [..._assignments];
    list.sort((a, b) => a.deadline.compareTo(b.deadline));
    return list;
  }

  /// Penugasan yang belum diarsipkan (tampil di daftar Penugasan).
  List<AssignmentModel> get activeAssignments => assignments.where((a) => a.status != AssignmentStatus.diarsipkan).toList();

  List<CourseModel> get courses => List.unmodifiable(_courses);

  AssignmentModel? byId(String id) {
    for (final a in _assignments) {
      if (a.id == id) return a;
    }
    return null;
  }

  CourseModel? courseOf(AssignmentModel a) {
    for (final c in _courses) {
      if (c.id == a.courseId) return c;
    }
    return null;
  }

  String courseName(AssignmentModel a) => courseOf(a)?.name ?? '-';

  int semesterOf(AssignmentModel a) => courseOf(a)?.semester ?? 0;

  // ----------------------------------------------- Status, progres, deadline

  int daysLeft(AssignmentModel a) => daysUntil(a.deadline);

  /// "Terlambat" dihitung otomatis: lewat deadline dan belum selesai.
  bool isOverdue(AssignmentModel a) => !a.status.isFinal && daysLeft(a) < 0;

  /// Mendesak: deadline <= 3 hari (termasuk terlambat) atau prioritas tinggi, dan belum selesai.
  bool isUrgent(AssignmentModel a) =>
      !a.status.isFinal && (daysLeft(a) <= 3 || a.priority == AssignmentPriority.tinggi);

  /// Progres 0.0 - 1.0. Individu: tahapan selesai. Kelompok: bagian pekerjaan yang Done.
  double progressOf(AssignmentModel a) {
    if (a.status.isFinal) return 1;
    if (a.isGroup) {
      final items = _groups.itemsOfAssignment(a.id);
      if (items.isEmpty) return 0;
      return items.where((i) => i.status == WorkStatus.done).length / items.length;
    }
    final total = _steps.totalOf(a.id);
    if (total == 0) return 0;
    return _steps.doneCountOf(a.id) / total;
  }

  AssignmentStatus _computeStatus(AssignmentModel a) {
    if (a.isGroup) {
      final items = _groups.itemsOfAssignment(a.id);
      if (items.isEmpty) return AssignmentStatus.belumDimulai;
      if (items.every((i) => i.status == WorkStatus.todo)) return AssignmentStatus.belumDimulai;
      if (items.every((i) => i.status == WorkStatus.review || i.status == WorkStatus.done)) {
        return AssignmentStatus.menungguPemeriksaan;
      }
      return AssignmentStatus.sedangDikerjakan;
    }
    final hasActivity = _steps.doneCountOf(a.id) > 0 ||
        _workspaces.notesOf(a.id).isNotEmpty ||
        _workspaces.referencesOf(a.id).isNotEmpty;
    return hasActivity ? AssignmentStatus.sedangDikerjakan : AssignmentStatus.belumDimulai;
  }

  bool _recomputeStatuses() {
    var changed = false;
    for (var i = 0; i < _assignments.length; i++) {
      final a = _assignments[i];
      if (a.status.isFinal) continue;
      final status = _computeStatus(a);
      if (status != a.status) {
        _assignments[i] = a.copyWith(status: status, updatedAt: DateTime.now());
        changed = true;
      }
    }
    return changed;
  }

  // -------------------------------------------------------- Ringkasan Beranda

  int get totalCount => _assignments.length;

  int get notStartedCount => _assignments.where((a) => a.status == AssignmentStatus.belumDimulai).length;

  int get inProgressCount => _assignments
      .where((a) => a.status == AssignmentStatus.sedangDikerjakan || a.status == AssignmentStatus.menungguPemeriksaan)
      .length;

  int get completedCount => _assignments.where((a) => a.status.isFinal).length;

  int get overdueCount => _assignments.where(isOverdue).length;

  /// Daftar pekerjaan yang perlu segera dikerjakan, gabungan tahapan individu dan bagian kelompok.
  List<PendingAction> pendingActions() {
    final result = <PendingAction>[];
    var seq = 0;
    for (final a in _assignments.where((a) => !a.status.isFinal)) {
      if (a.isGroup) {
        final group = _groups.groupOf(a.id);
        final me = group == null ? null : _groups.me(group.id);
        if (group == null || me == null) continue;
        for (final item in _groups.itemsOfGroup(group.id)) {
          if (item.assigneeId == me.id && item.status != WorkStatus.done) {
            result.add(PendingAction(
              seq: seq++,
              id: item.id,
              title: item.title,
              assignmentId: a.id,
              assignmentTitle: a.title,
              deadline: item.deadline,
              isGroupWork: true,
            ));
          }
        }
      } else {
        for (final step in _steps.pendingOf(a.id)) {
          result.add(PendingAction(
            seq: seq++,
            id: step.id,
            title: step.title,
            assignmentId: a.id,
            assignmentTitle: a.title,
            deadline: a.deadline,
            isGroupWork: false,
          ));
        }
      }
    }
    result.sort((x, y) {
      final c = x.deadline.compareTo(y.deadline);
      return c != 0 ? c : x.seq.compareTo(y.seq);
    });
    return result;
  }

  int get pendingActionCount => pendingActions().length;

  // ------------------------------------------------------------- Pembuatan

  Future<CourseModel> _findOrCreateCourse(String name, int semester) async {
    final clean = name.trim();
    for (final c in _courses) {
      if (c.name.toLowerCase() == clean.toLowerCase()) return c;
    }
    final course = CourseModel(
      id: newId('c'),
      name: clean,
      semester: semester,
      academicYear: academicYearFor(DateTime.now()),
    );
    _courses.add(course);
    await _saveCourses();
    return course;
  }

  /// Membuat penugasan beserta Ruang Kerja-nya (satu penugasan = satu ruang kerja utama).
  Future<AssignmentModel> create({
    required String title,
    required String courseName,
    required int semester,
    required String description,
    required AssignmentMode mode,
    required AssignmentPriority priority,
    DateTime? assignedDate,
    required DateTime deadline,
    TemplateModel? template,
    String? groupName,
    required String ownerName,
    List<PickedFileData> instructionFiles = const [],
  }) async {
    final course = await _findOrCreateCourse(courseName, semester);
    final id = newId('a');
    final ws = await _workspaces.createWorkspace(id);
    String? groupId;
    if (mode == AssignmentMode.kelompok) {
      final group = await _groups.createGroup(
        assignmentId: id,
        name: (groupName == null || groupName.trim().isEmpty) ? 'Kelompok ${title.trim()}' : groupName,
        ownerName: ownerName,
      );
      groupId = group.id;
    }
    final now = DateTime.now();
    final assignment = AssignmentModel(
      id: id,
      title: title.trim(),
      courseId: course.id,
      description: description.trim(),
      mode: mode,
      priority: priority,
      assignedDate: assignedDate,
      deadline: dateOnly(deadline),
      templateId: template?.id,
      templateTitle: template?.title,
      status: AssignmentStatus.belumDimulai,
      workspaceId: ws.id,
      groupId: groupId,
      createdAt: now,
      updatedAt: now,
    );
    _assignments.add(assignment);
    notifyListeners();
    await _saveAssignments();

    if (template != null) {
      await _workspaces.addFromTemplate(ws.id, id, template);
    }
    if (mode == AssignmentMode.individu) {
      await _steps.addMany(ws.id, id, defaultStepTitles);
    }
    for (final file in instructionFiles) {
      await _workspaces.addUploadedFile(
        workspaceId: ws.id,
        assignmentId: id,
        file: file,
        kind: DocumentKind.instruction,
      );
    }
    return assignment;
  }

  Future<void> update({
    required String id,
    required String title,
    required String courseName,
    required int semester,
    required String description,
    required AssignmentPriority priority,
    DateTime? assignedDate,
    required DateTime deadline,
  }) async {
    final i = _assignments.indexWhere((a) => a.id == id);
    if (i < 0) return;
    final course = await _findOrCreateCourse(courseName, semester);
    _assignments[i] = _assignments[i].copyWith(
      title: title.trim(),
      courseId: course.id,
      description: description.trim(),
      priority: priority,
      assignedDate: assignedDate,
      clearAssignedDate: assignedDate == null,
      deadline: dateOnly(deadline),
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _saveAssignments();
  }

  /// Menghapus penugasan beserta SEMUA data turunannya (ruang kerja, tahapan, kelompok, arsip).
  Future<void> delete(String id) async {
    _assignments.removeWhere((a) => a.id == id);
    notifyListeners();
    await _steps.removeByAssignment(id);
    await _workspaces.removeByAssignment(id);
    await _groups.removeByAssignment(id);
    await _archives.removeByAssignment(id);
    await _saveAssignments();
  }

  // ------------------------------------------------ Finalisasi dan pengarsipan

  /// Menyelesaikan penugasan. Bila [archive] true, penugasan langsung dipindahkan ke Arsip.
  Future<void> finalize(String id, {required String summary, required bool archive}) async {
    final i = _assignments.indexWhere((a) => a.id == id);
    if (i < 0) return;
    final now = DateTime.now();
    final ws = _workspaces.workspaceOf(id);
    if (ws != null) await _workspaces.setFinalSummary(ws.id, summary);

    var updated = _assignments[i].copyWith(
      status: AssignmentStatus.selesai,
      completedAt: _assignments[i].completedAt ?? now,
      updatedAt: now,
    );
    if (archive) {
      updated = updated.copyWith(status: AssignmentStatus.diarsipkan, archivedAt: now);
      await _archives.add(_buildArchive(updated, summary));
    }
    _assignments[i] = updated;
    notifyListeners();
    await _saveAssignments();
  }

  ArchiveModel _buildArchive(AssignmentModel a, String summary) {
    final course = courseOf(a);
    final members = <String>[];
    if (a.isGroup) {
      final group = _groups.groupOf(a.id);
      if (group != null) members.addAll(_groups.membersOf(group.id).map((m) => m.name));
    }
    final completed = a.completedAt ?? DateTime.now();
    final archived = a.archivedAt ?? DateTime.now();
    return ArchiveModel(
      id: newId('ar'),
      assignmentId: a.id,
      title: a.title,
      courseName: course?.name ?? '-',
      semester: course?.semester ?? 0,
      academicYear: course?.academicYear ?? '',
      mode: a.mode,
      assignedDate: a.assignedDate,
      deadline: a.deadline,
      completedAt: completed,
      archivedAt: archived,
      memberNames: members,
      templateTitle: a.templateTitle,
      summary: summary,
      history: [
        ArchiveEvent(date: a.createdAt, text: 'Penugasan dibuat'),
        ArchiveEvent(date: completed, text: 'Finalisasi dikonfirmasi, penugasan selesai'),
        ArchiveEvent(date: archived, text: 'Dipindahkan ke Arsip'),
      ],
    );
  }

  /// Memindahkan penugasan selesai (belum diarsipkan) ke Arsip setelah konfirmasi pengguna.
  Future<void> archiveCompleted(String id) async {
    final a = byId(id);
    if (a == null || a.status != AssignmentStatus.selesai) return;
    final ws = _workspaces.workspaceOf(id);
    await finalize(id, summary: ws?.finalSummary ?? '', archive: true);
  }

  /// Membuka kembali arsip: penugasan kembali aktif, dokumen dan referensi tetap utuh.
  Future<void> restoreFromArchive(String id) async {
    final i = _assignments.indexWhere((a) => a.id == id);
    if (i < 0) return;
    _assignments[i] = _assignments[i].copyWith(
      status: AssignmentStatus.sedangDikerjakan,
      clearCompletedAt: true,
      clearArchivedAt: true,
      updatedAt: DateTime.now(),
    );
    await _archives.removeByAssignment(id);
    _recomputeStatuses();
    notifyListeners();
    await _saveAssignments();
  }
}
