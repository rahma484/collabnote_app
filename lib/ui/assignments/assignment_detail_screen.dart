import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/assignment_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/workspace_repository.dart';
import '../../domain/models/assignment_model.dart';
import '../core/app_colors.dart';
import '../core/app_widgets.dart';
import '../core/formatters.dart';
import '../shell/navigation_controller.dart';
import 'assignment_form_screen.dart';

void openAssignmentDetail(BuildContext context, String assignmentId) {
  pushSlideUp<void>(context, AssignmentDetailScreen(assignmentId: assignmentId));
}

/// Detail penugasan: informasi lengkap + pintu masuk ke Ruang Kerja.
class AssignmentDetailScreen extends StatelessWidget {
  final String assignmentId;

  const AssignmentDetailScreen({super.key, required this.assignmentId});

  Future<void> _delete(BuildContext context) async {
    final repo = context.read<AssignmentRepository>();
    final ok = await showConfirmDialog(
      context,
      title: 'Hapus Penugasan?',
      message: 'Tindakan ini akan menghapus seluruh data terkait penugasan dan ruang kerja. Tidak dapat dibatalkan.',
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    await repo.delete(assignmentId);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Penugasan dihapus.')));
  }

  void _openWorkspace(BuildContext context) {
    final nav = context.read<NavigationController>();
    Navigator.of(context).popUntil((r) => r.isFirst);
    nav.openWorkspace(assignmentId);
  }

  Future<void> _archive(BuildContext context) async {
    final repo = context.read<AssignmentRepository>();
    final ok = await showConfirmDialog(
      context,
      title: 'Arsipkan Penugasan?',
      message: 'Penugasan akan dipindahkan ke Arsip. Dokumen dan referensi tetap tersimpan.',
      confirmLabel: 'Arsipkan',
    );
    if (!ok || !context.mounted) return;
    final nav = context.read<NavigationController>();
    await repo.archiveCompleted(assignmentId);
    if (!context.mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    nav.goTo(3);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AssignmentRepository>();
    final a = repo.byId(assignmentId);
    if (a == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final groups = context.watch<GroupRepository>();
    final workspaces = context.watch<WorkspaceRepository>();
    final group = a.isGroup ? groups.groupOf(a.id) : null;
    final course = repo.courseOf(a);
    final progress = repo.progressOf(a);
    final templateDocs = workspaces.documentsOf(a.id).length;

    Widget info(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.mocca)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<String>(
            color: AppColors.cream,
            onSelected: (v) {
              if (v == 'edit') {
                pushSlideUp<String>(context, AssignmentFormScreen(editId: a.id));
              } else if (v == 'delete') {
                _delete(context);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit Penugasan')),
              PopupMenuItem(value: 'delete', child: Text('Hapus Penugasan')),
            ],
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 16),
              decoration: const BoxDecoration(color: AppColors.chip, shape: BoxShape.circle),
              child: const Icon(Icons.more_horiz, color: AppColors.brown),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(
            '${a.title}${course == null ? '' : ' (${course.name})'}',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.2),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: StatusPill(status: a.status, overdue: repo.isOverdue(a)),
          ),
          const SizedBox(height: 20),
          info('Mata Kuliah', course?.name ?? '-'),
          if (course != null) info('Semester / Tahun Akademik', 'Semester ${course.semester}  •  ${course.academicYear}'),
          info('Deskripsi', a.description.isEmpty ? '-' : a.description),
          if (a.assignedDate != null) info('Tanggal Diberikan', formatDate(a.assignedDate!)),
          info('Deadline', '${formatDate(a.deadline)}  (${deadlineText(repo.daysLeft(a))})'),
          info('Prioritas', a.priority.label),
          if (a.templateTitle != null) info('Template', a.templateTitle!),
          Row(
            children: [
              Expanded(child: info('Mode Pengerjaan', a.mode.label)),
              Icon(a.isGroup ? Icons.groups_2_outlined : Icons.person_outline, size: 34, color: AppColors.mocca),
            ],
          ),
          if (group != null) info('Kelompok', '${group.name}  •  ${groups.membersOf(group.id).length} anggota'),
          Text('Progres ${(progress * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ProgressBarSoft(value: progress, height: 10),
          const SizedBox(height: 6),
          Text('$templateDocs dokumen di Ruang Kerja', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          const SizedBox(height: 26),
          if (a.status == AssignmentStatus.selesai) ...[
            PrimaryButton(label: 'Arsipkan Penugasan', icon: Icons.inventory_2_outlined, onPressed: () => _archive(context)),
            const SizedBox(height: 10),
          ],
          PrimaryButton(
            label: a.isGroup ? 'Buka Ruang Kerja Kelompok' : 'Buka Ruang Kerja Pribadi',
            color: a.status == AssignmentStatus.selesai ? AppColors.brown : AppColors.moccaDark,
            onPressed: () => _openWorkspace(context),
          ),
        ],
      ),
    );
  }
}
