import 'package:flutter/foundation.dart';

import '../../data/repositories/assignment_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/task_step_repository.dart';
import '../../data/repositories/template_repository.dart';
import '../../data/repositories/workspace_repository.dart';
import '../../data/services/local_file_service.dart';
import '../../domain/models/assignment_model.dart';
import '../../domain/models/document_model.dart';
import '../../domain/models/group_member_model.dart';
import '../../domain/models/group_model.dart';
import '../../domain/models/note_model.dart';
import '../../domain/models/reference_model.dart';
import '../../domain/models/submission_model.dart';
import '../../domain/models/task_step_model.dart';
import '../../domain/models/template_model.dart';
import '../../domain/models/work_item_model.dart';
import '../../domain/models/workspace_model.dart';

/// Satu butir pemeriksaan pada halaman Finalisasi.
class FinalCheck {
  final String label;
  final String detail;
  final bool ok;
  final bool required;

  const FinalCheck({required this.label, required this.detail, required this.ok, this.required = true});
}

/// ViewModel Ruang Kerja: mengelola seluruh isi ruang kerja SATU penugasan yang sedang dibuka.
/// Mode individu memakai tahapan; mode kelompok memakai anggota, pembagian pekerjaan, dan pengumpulan hasil.
/// Semua data tetap disimpan di repository, ViewModel hanya merangkum dan meneruskan aksi.
class WorkspaceViewModel extends ChangeNotifier {
  WorkspaceViewModel({
    required this.assignments,
    required this.steps,
    required this.workspaces,
    required this.groups,
    required this.profile,
    required this.templates,
    required this.files,
  }) {
    assignments.addListener(notifyListeners);
    steps.addListener(notifyListeners);
    workspaces.addListener(notifyListeners);
    groups.addListener(notifyListeners);
  }

  final AssignmentRepository assignments;
  final TaskStepRepository steps;
  final WorkspaceRepository workspaces;
  final GroupRepository groups;
  final ProfileRepository profile;
  final TemplateRepository templates;
  final LocalFileService files;

  String? _assignmentId;
  bool isLoading = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await Future.wait([assignments.load(), profile.load(), templates.load()]);
    } catch (e) {
      error = 'Gagal memuat Ruang Kerja: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void open(String assignmentId) {
    _assignmentId = assignmentId;
    notifyListeners();
  }

  void close() {
    _assignmentId = null;
    notifyListeners();
  }

  // ------------------------------------------------------------ Data umum

  /// Penugasan yang dibuka. null bila belum dipilih, sudah dihapus, atau sudah diarsipkan.
  AssignmentModel? get assignment {
    final id = _assignmentId;
    if (id == null) return null;
    final a = assignments.byId(id);
    if (a == null || a.status == AssignmentStatus.diarsipkan) return null;
    return a;
  }

  bool get hasWorkspace => assignment != null && workspace != null;
  bool get isGroup => assignment?.isGroup ?? false;
  String get assignmentId => assignment?.id ?? '';
  WorkspaceModel? get workspace => assignment == null ? null : workspaces.workspaceOf(assignment!.id);
  String get courseName => assignment == null ? '-' : assignments.courseName(assignment!);
  double get progress => assignment == null ? 0 : assignments.progressOf(assignment!);
  int get daysLeft => assignment == null ? 0 : assignments.daysLeft(assignment!);
  String get userName => profile.user.name;

  /// Penugasan aktif yang dapat dipilih untuk dibuka ruang kerjanya.
  List<AssignmentModel> get openableAssignments => assignments.activeAssignments;

  // ------------------------------------------------------ Tahapan (individu)

  List<TaskStepModel> get pendingSteps => steps.pendingOf(assignmentId);
  List<TaskStepModel> get doneSteps => steps.doneOf(assignmentId);
  int get stepsTotal => steps.totalOf(assignmentId);
  int get stepsDone => steps.doneCountOf(assignmentId);

  Future<void> addStep(String title) => steps.add(workspace!.id, assignmentId, title);
  Future<void> renameStep(String id, String title) => steps.rename(id, title);
  Future<void> toggleStep(String id) => steps.toggle(id);
  Future<void> deleteStep(String id) => steps.delete(id);
  Future<void> reorderSteps(int oldIndex, int newIndex) => steps.reorderPending(assignmentId, oldIndex, newIndex);

  // ------------------------------------------------------------- Catatan

  List<NoteModel> get notes => workspaces.notesOf(assignmentId);

  Future<void> addNote(String title, String content) => workspaces.addNote(
        workspaceId: workspace!.id,
        assignmentId: assignmentId,
        title: title,
        content: content,
        authorName: userName,
      );

  Future<void> updateNote(String id, String title, String content) =>
      workspaces.updateNote(id, title: title, content: content);

  Future<void> deleteNote(String id) => workspaces.deleteNote(id);

  // ---------------------------------------------------------- Referensi

  List<ReferenceModel> get references => workspaces.referencesOf(assignmentId);

  Future<void> addReference(String title, String url, ReferenceType type, String note) => workspaces.addReference(
        workspaceId: workspace!.id,
        assignmentId: assignmentId,
        title: title,
        url: url,
        type: type,
        note: note,
      );

  Future<void> updateReference(String id, String title, String url, ReferenceType type, String note) =>
      workspaces.updateReference(id, title: title, url: url, type: type, note: note);

  Future<void> deleteReference(String id) => workspaces.deleteReference(id);

  // ------------------------------------------------------------ Dokumen

  List<DocumentModel> get documents => workspaces.documentsOf(assignmentId);

  List<DocumentModel> get finalDocuments => documents.where((d) => d.kind == DocumentKind.finalDoc).toList();

  List<DocumentModel> get attachmentDocuments =>
      documents.where((d) => d.kind == DocumentKind.attachment || d.kind == DocumentKind.instruction).toList();

  /// Menambahkan template ke Ruang Kerja (hanya ke penugasan aktif ini).
  Future<void> useTemplate(TemplateModel template) async {
    await workspaces.addFromTemplate(workspace!.id, assignmentId, template);
    await templates.markUsed(template.id);
  }

  Future<void> createTextDocument(String title, String text) =>
      workspaces.addTextDocument(workspaceId: workspace!.id, assignmentId: assignmentId, title: title, text: text);

  Future<void> updateTextDocument(String id, String title, String text) =>
      workspaces.updateTextDocument(id, title: title, text: text);

  /// Mengunggah file ke Ruang Kerja. Mengembalikan pesan untuk pengguna, null bila dibatalkan.
  Future<String?> uploadDocument(DocumentKind kind) async {
    final picked = await files.pickFile();
    if (picked == null) return null;
    await workspaces.addUploadedFile(workspaceId: workspace!.id, assignmentId: assignmentId, file: picked, kind: kind);
    return 'File "${picked.name}" ditambahkan.';
  }

  /// Mengganti dokumen dengan versi hasil edit dari aplikasi lain.
  Future<String?> replaceDocumentFile(DocumentModel doc) async {
    final picked = await files.pickFile();
    if (picked == null) return null;
    await workspaces.replaceFile(doc.id, picked);
    return 'Versi baru "${picked.name}" disimpan.';
  }

  Future<void> setDocumentFinal(DocumentModel doc, bool isFinal) => workspaces.setFinal(doc.id, isFinal);

  Future<void> deleteDocument(DocumentModel doc) => workspaces.deleteDocument(doc.id);

  /// Byte dokumen untuk dibuka langsung di dalam aplikasi (pratinjau).
  Future<Uint8List?> bytesOfDocument(DocumentModel doc) => workspaces.bytesOf(doc);

  Future<Uint8List?> bytesOfAttachment(WorkItemModel item) => files.readBytes(item.attachmentPath);

  Future<Uint8List?> bytesOfSubmission(SubmissionModel s) => files.readBytes(s.localPath);

  Future<String> downloadDocument(DocumentModel doc) async {
    final bytes = await workspaces.bytesOf(doc);
    if (bytes == null) return 'File tidak tersedia.';
    final ok = await files.exportBytes(doc.fileName, bytes);
    return ok ? 'File disimpan: ${doc.fileName}' : 'Unduhan dibatalkan.';
  }

  // ------------------------------------------------------------- Kelompok

  GroupModel? get group => assignment == null ? null : groups.groupOf(assignment!.id);
  List<GroupMemberModel> get members => group == null ? const [] : groups.membersOf(group!.id);
  GroupMemberModel? get me => group == null ? null : groups.me(group!.id);
  bool get isOwner => group != null && groups.isOwner(group!.id);
  List<WorkItemModel> get workItems => group == null ? const [] : groups.itemsOfGroup(group!.id);

  List<WorkItemModel> itemsByStatus(WorkStatus s) => group == null ? const [] : groups.itemsByStatus(group!.id, s);

  int get workDone => workItems.where((i) => i.status == WorkStatus.done).length;

  GroupMemberModel? memberOf(String id) => groups.memberById(id);

  String memberName(String id) => groups.memberById(id)?.name ?? '-';

  List<SubmissionModel> submissionsOf(String workItemId) => groups.submissionsOf(workItemId);

  /// Pemilik atau penanggung jawab boleh mengubah bagian pekerjaan.
  bool canEditItem(WorkItemModel item) => isOwner || item.assigneeId == me?.id;

  /// Hanya pemilik kelompok yang memeriksa hasil dan menyetujui.
  bool get canReview => isOwner;

  Future<void> inviteMember(String name) => groups.inviteMember(group!.id, name);

  Future<void> confirmMember(String memberId) => groups.confirmMember(memberId);

  Future<void> removeMember(String memberId) => groups.removeMember(memberId);

  Future<void> addWorkItem({
    required String title,
    required String description,
    required String assigneeId,
    required DateTime deadline,
    required WorkStatus status,
    String? attachmentPath,
    String? attachmentName,
  }) =>
      groups.addItem(
        groupId: group!.id,
        assignmentId: assignmentId,
        title: title,
        description: description,
        assigneeId: assigneeId,
        deadline: deadline,
        status: status,
        attachmentPath: attachmentPath,
        attachmentName: attachmentName,
      );

  Future<void> saveWorkItem(WorkItemModel item) => groups.updateItem(item);

  Future<String> downloadWorkAttachment(WorkItemModel item) async {
    final bytes = await files.readBytes(item.attachmentPath);
    if (bytes == null || item.attachmentName == null) return 'Lampiran tidak ditemukan.';
    final ok = await files.exportBytes(item.attachmentName!, bytes);
    return ok ? 'File diunduh: ${item.attachmentName}' : 'Unduhan dibatalkan.';
  }

  Future<void> deleteWorkItem(String id) => groups.deleteItem(id);

  /// Menyimpan perubahan dari "Detail Pekerjaan": status pekerjaan dan/atau hasil pemeriksaan.
  Future<void> applyItemChanges(
    WorkItemModel item, {
    required WorkStatus status,
    required ReviewStatus review,
    required String reviewNote,
  }) async {
    final subs = submissionsOf(item.id);
    final latest = subs.isEmpty ? null : subs.first;
    if (canReview && latest != null && (review != latest.reviewStatus || reviewNote != latest.reviewNote)) {
      await groups.review(submissionId: latest.id, status: review, note: reviewNote);
      if (review == ReviewStatus.pending && status != item.status) {
        await groups.updateItem(item.copyWith(status: status));
      }
      return;
    }
    if (status != item.status) {
      await groups.updateItem(item.copyWith(status: status));
    }
  }

  /// Anggota mengunggah hasil pekerjaan (disimulasikan lokal).
  Future<String?> submitResult(WorkItemModel item, String note) async {
    final picked = await files.pickFile();
    if (picked == null) return null;
    await groups.submit(item: item, memberId: item.assigneeId, file: picked, note: note);
    return 'Hasil "${picked.name}" dikirim untuk diperiksa.';
  }

  Future<String> downloadSubmission(SubmissionModel s) async {
    final bytes = await files.readBytes(s.localPath);
    if (bytes == null) return 'Berkas contoh ini tidak memiliki isi file.';
    final ok = await files.exportBytes(s.fileName, bytes);
    return ok ? 'File disimpan: ${s.fileName}' : 'Unduhan dibatalkan.';
  }

  /// Penggabungan dokumen: menyusun satu dokumen dari semua hasil anggota yang sudah disetujui.
  Future<String> mergeApprovedResults() async {
    final a = assignment;
    if (a == null || !isOwner) return 'Hanya Pemilik Kelompok yang dapat menggabungkan dokumen.';
    final buffer = StringBuffer('# Dokumen Gabungan: ${a.title}\n\n');
    var count = 0;
    for (final item in workItems) {
      final subs = submissionsOf(item.id).where((s) => s.reviewStatus == ReviewStatus.approved).toList();
      if (subs.isEmpty) continue;
      final s = subs.first;
      count++;
      buffer
        ..writeln('## ${item.title}')
        ..writeln('Penanggung jawab: ${memberName(item.assigneeId)}')
        ..writeln('Berkas: ${s.fileName}')
        ..writeln('Catatan: ${s.note.isEmpty ? '-' : s.note}')
        ..writeln();
    }
    if (count == 0) return 'Belum ada hasil anggota yang disetujui.';
    await workspaces.addTextDocument(
      workspaceId: workspace!.id,
      assignmentId: assignmentId,
      title: 'Dokumen Gabungan',
      text: buffer.toString(),
      source: DocumentSource.merged,
    );
    return 'Dokumen Gabungan dibuat dari $count hasil. Tandai sebagai Final bila sudah siap.';
  }

  // ----------------------------------------------------------- Finalisasi

  List<FinalCheck> get finalChecks {
    final refCount = references.length;
    final finals = finalDocuments;
    final attachments = attachmentDocuments;
    if (isGroup) {
      final total = workItems.length;
      return [
        FinalCheck(label: 'Semua Bagian Pekerjaan Selesai', detail: '$workDone/$total Done', ok: total > 0 && workDone == total),
        FinalCheck(label: 'Dokumen Akhir Kelompok', detail: finals.isEmpty ? 'Belum ada' : '${finals.length} file', ok: finals.isNotEmpty),
        FinalCheck(label: 'Referensi Lengkap', detail: '$refCount referensi', ok: refCount > 0),
        FinalCheck(label: 'Lampiran', detail: attachments.isEmpty ? 'Opsional' : '${attachments.length} file', ok: attachments.isNotEmpty, required: false),
        FinalCheck(label: 'Konfirmasi Pemilik Kelompok', detail: isOwner ? 'Anda pemilik' : 'Hanya pemilik', ok: isOwner),
      ];
    }
    return [
      FinalCheck(label: 'Tahapan Selesai', detail: '$stepsDone/$stepsTotal', ok: stepsTotal > 0 && stepsDone == stepsTotal),
      FinalCheck(label: 'Dokumen Akhir', detail: finals.isEmpty ? 'Belum ada' : '${finals.length} file', ok: finals.isNotEmpty),
      FinalCheck(label: 'Referensi Lengkap', detail: '$refCount referensi', ok: refCount > 0),
      FinalCheck(label: 'Lampiran', detail: attachments.isEmpty ? 'Opsional' : '${attachments.length} file', ok: attachments.isNotEmpty, required: false),
    ];
  }

  bool get canFinalize => finalChecks.where((c) => c.required).every((c) => c.ok);

  String get savedSummary => workspace?.finalSummary ?? '';

  String get suggestedSummary {
    final a = assignment;
    if (a == null) return '';
    final tail = isGroup ? '$workDone bagian pekerjaan kelompok selesai.' : '$stepsDone tahapan pengerjaan selesai.';
    return 'Penugasan "${a.title}" ($courseName) diselesaikan. $tail';
  }

  /// Menyelesaikan penugasan. [archive] true = langsung masuk Arsip.
  Future<void> finalize({required String summary, required bool archive}) {
    final text = summary.trim().isEmpty ? suggestedSummary : summary.trim();
    return assignments.finalize(assignmentId, summary: text, archive: archive);
  }

  @override
  void dispose() {
    assignments.removeListener(notifyListeners);
    steps.removeListener(notifyListeners);
    workspaces.removeListener(notifyListeners);
    groups.removeListener(notifyListeners);
    super.dispose();
  }
}
