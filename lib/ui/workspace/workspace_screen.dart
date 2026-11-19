import 'package:flutter/material.dart';

import '../../domain/models/assignment_model.dart';
import '../../domain/models/work_item_model.dart';
import '../assignments/assignment_form_screen.dart';
import '../core/app_colors.dart';
import '../core/app_widgets.dart';
import '../core/formatters.dart';
import 'documents_screen.dart';
import 'finalization_screen.dart';
import 'kanban_screen.dart';
import 'members_sheet.dart';
import 'notes_screen.dart';
import 'references_screen.dart';
import 'steps_screen.dart';
import 'workspace_view_model.dart';

/// Tab Ruang Kerja. Menampilkan kondisi kosong bila belum ada penugasan yang dibuka,
/// atau Ruang Kerja Individu / Kelompok sesuai mode penugasan.
class WorkspaceScreen extends StatelessWidget {
  final WorkspaceViewModel viewModel;

  const WorkspaceScreen({super.key, required this.viewModel});

  void _pickAssignment(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final list = viewModel.openableAssignments;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Align(alignment: Alignment.centerLeft, child: Text('Pilih Penugasan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                ),
                Flexible(
                  child: list.isEmpty
                      ? const Padding(padding: EdgeInsets.all(24), child: Text('Belum ada penugasan.'))
                      : ListView(
                          shrinkWrap: true,
                          children: [
                            for (final a in list)
                              ListTile(
                                leading: Icon(a.isGroup ? Icons.groups_2_outlined : Icons.person_outline, color: AppColors.mocca),
                                title: Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text('${viewModel.assignments.courseName(a)}  •  ${a.mode.label}'),
                                selected: a.id == viewModel.assignmentId,
                                onTap: () {
                                  Navigator.pop(ctx);
                                  viewModel.open(a.id);
                                },
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (viewModel.isLoading && !viewModel.hasWorkspace) {
          return const ShimmerLoading();
        }
        if (viewModel.error != null) {
          return EmptyState(icon: Icons.error_outline, message: viewModel.error!, actionLabel: 'Coba Lagi', onAction: viewModel.load);
        }
        if (!viewModel.hasWorkspace) return _buildEmpty(context);

        final a = viewModel.assignment!;
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showQuickAdd(context),
            child: const Icon(Icons.add, size: 28),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ruang Kerja: ${a.title}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, height: 1.2),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ganti penugasan',
                      onPressed: () => _pickAssignment(context),
                      icon: const Icon(Icons.swap_horiz, color: AppColors.mocca),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (viewModel.isGroup) ..._groupContent(context, a) else ..._individualContent(context, a),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ruang Kerja', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            Expanded(
              child: EmptyState(
                icon: Icons.folder_open_outlined,
                message: 'Belum ada Ruang Kerja yang dibuka.\nPilih penugasan untuk mulai mengerjakan, atau buat penugasan baru.',
                actionLabel: 'Pilih Penugasan',
                onAction: () => _pickAssignment(context),
              ),
            ),
            TextButton(onPressed: () => startCreateAssignment(context), child: const Text('Buat Penugasan Baru')),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Individu

  List<Widget> _individualContent(BuildContext context, AssignmentModel a) {
    final vm = viewModel;
    final pct = (vm.progress * 100).round();
    return [
      Center(
        child: ProgressRing(
          value: vm.progress,
          size: 150,
          strokeWidth: 14,
          center: Text('$pct%', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w500)),
        ),
      ),
      const SizedBox(height: 16),
      _InfoCard(viewModel: vm, assignment: a),
      const SizedBox(height: 14),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.45,
        children: [
          MenuTile(
            icon: Icons.checklist_rtl,
            title: 'Task Checklist',
            subtitle: '${vm.stepsDone}/${vm.stepsTotal} done',
            onTap: () => pushSlideUp<void>(context, StepsScreen(viewModel: vm)),
          ),
          MenuTile(
            icon: Icons.edit_note,
            title: 'Catatan Pribadi',
            subtitle: '${vm.notes.length} notes',
            onTap: () => pushSlideUp<void>(context, NotesScreen(viewModel: vm)),
          ),
          MenuTile(
            icon: Icons.insert_drive_file_outlined,
            title: 'Dokumen',
            subtitle: '${vm.documents.length} files',
            onTap: () => pushSlideUp<void>(context, DocumentsScreen(viewModel: vm)),
          ),
          MenuTile(
            icon: Icons.link,
            title: 'Referensi',
            subtitle: '${vm.references.length} links',
            onTap: () => pushSlideUp<void>(context, ReferencesScreen(viewModel: vm)),
          ),
          MenuTile(
            icon: Icons.check,
            title: 'Finalisasi',
            subtitle: a.status == AssignmentStatus.selesai ? 'Siap diarsipkan' : '',
            onTap: () => pushSlideUp<void>(context, FinalizationScreen(viewModel: vm)),
          ),
        ],
      ),
    ];
  }

  // ---------------------------------------------------------------- Kelompok

  List<Widget> _groupContent(BuildContext context, AssignmentModel a) {
    final vm = viewModel;
    final group = vm.group;
    final pct = (vm.progress * 100).round();
    final members = vm.members;
    return [
      Row(
        children: [
          Expanded(child: ProgressBarSoft(value: vm.progress, height: 10)),
          const SizedBox(width: 12),
          Text('$pct%', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
      const SizedBox(height: 14),
      if (group != null)
        Container(
          padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
          decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(child: Text('Kode Undangan: ${group.inviteCode}', style: const TextStyle(fontWeight: FontWeight.w600))),
              InviteCopyButton(code: group.inviteCode),
            ],
          ),
        ),
      const SizedBox(height: 14),
      Text('Daftar Anggota', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      PressableScale(
        onTap: () => showMembersSheet(context, vm),
        child: Row(
          children: [
            SizedBox(
              height: 42,
              width: 42.0 + (members.length > 5 ? 5 : members.length - 1).clamp(0, 5) * 28,
              child: Stack(
                children: [
                  for (var i = 0; i < members.length && i < 6; i++)
                    Positioned(left: i * 28.0, child: MemberAvatar(name: members[i].name, size: 42, ring: true)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('${members.length} anggota', style: const TextStyle(fontSize: 12.5)),
            const Spacer(),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: AppColors.chip, shape: BoxShape.circle),
              child: Icon(vm.isOwner ? Icons.workspace_premium : Icons.group_outlined, color: AppColors.mocca),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _InfoCard(viewModel: vm, assignment: a),
      const SizedBox(height: 14),
      _BigCard(
        color: const Color(0xFFD9C2AB),
        onTap: () => pushSlideUp<void>(context, KanbanScreen(viewModel: vm)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pembagian Tugas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            _MiniKanban(viewModel: vm),
            const SizedBox(height: 8),
            Text(
              '${vm.itemsByStatus(WorkStatus.todo).length} To Do, ${vm.itemsByStatus(WorkStatus.inProgress).length} In Progress, '
              '${vm.itemsByStatus(WorkStatus.review).length} Review, ${vm.itemsByStatus(WorkStatus.done).length} Done',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _BigCard(
        color: const Color(0xFFD9C2AB),
        onTap: () => pushSlideUp<void>(context, NotesScreen(viewModel: vm)),
        child: _CardLabel('Catatan Bersama', '${vm.notes.length} catatan'),
      ),
      const SizedBox(height: 12),
      _BigCard(
        color: const Color(0xFF7E5B45),
        onTap: () => pushSlideUp<void>(context, DocumentsScreen(viewModel: vm)),
        child: _CardLabel('Dokumen Kelompok', '${vm.documents.length} file', light: true),
      ),
      const SizedBox(height: 12),
      _BigCard(
        color: AppColors.card,
        onTap: () => pushSlideUp<void>(context, ReferencesScreen(viewModel: vm)),
        child: _CardLabel('Referensi Bersama', '${vm.references.length} tautan'),
      ),
      const SizedBox(height: 12),
      _BigCard(
        color: AppColors.card,
        onTap: () => pushSlideUp<void>(context, FinalizationScreen(viewModel: vm)),
        child: _CardLabel('Finalisasi Kelompok', vm.canFinalize ? 'Siap difinalisasi' : 'Lengkapi pekerjaan'),
      ),
    ];
  }

  // ---------------------------------------------------------------- Tambah cepat

  void _showQuickAdd(BuildContext context) {
    final vm = viewModel;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        Widget tile(IconData icon, String label, VoidCallback onTap) => ListTile(
              leading: Icon(icon, color: AppColors.mocca),
              title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                onTap();
              },
            );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (vm.isGroup)
                tile(Icons.view_kanban_outlined, 'Tambah Bagian Pekerjaan', () => showWorkItemForm(context, vm))
              else
                tile(Icons.checklist_rtl, 'Tambah Tahapan', () => promptAddStep(context, vm)),
              tile(Icons.edit_note, vm.isGroup ? 'Tambah Catatan Bersama' : 'Tambah Catatan', () => showNoteEditor(context, vm)),
              tile(Icons.link, 'Tambah Referensi', () => showReferenceEditor(context, vm)),
              tile(Icons.note_add_outlined, 'Tambah Dokumen / Template', () => showAddDocumentSheet(context, vm)),
            ],
          ),
        );
      },
    );
  }
}

/// Informasi penugasan + instruksi dosen (kartu yang melebar dengan animasi pegas lembut).
class _InfoCard extends StatelessWidget {
  final WorkspaceViewModel viewModel;
  final AssignmentModel assignment;

  const _InfoCard({required this.viewModel, required this.assignment});

  @override
  Widget build(BuildContext context) {
    final days = viewModel.daysLeft;
    return ExpandableCard(
      header: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.mocca),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Informasi & Instruksi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text('${viewModel.courseName}  •  ${deadlineText(days)}', style: const TextStyle(fontSize: 12.5)),
              ],
            ),
          ),
          const Icon(Icons.expand_more, color: AppColors.mocca),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Deadline: ${formatDate(assignment.deadline)}'),
          Text('Prioritas: ${assignment.priority.label}'),
          if (assignment.templateTitle != null) Text('Template: ${assignment.templateTitle}'),
          const SizedBox(height: 6),
          const Text('Instruksi dosen:', style: TextStyle(fontWeight: FontWeight.w700)),
          Text(assignment.description.isEmpty ? '-' : assignment.description),
        ],
      ),
    );
  }
}

class _BigCard extends StatelessWidget {
  final Color color;
  final Widget child;
  final VoidCallback onTap;

  const _BigCard({required this.color, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
        child: child,
      ),
    );
  }
}

class _CardLabel extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool light;

  const _CardLabel(this.title, this.subtitle, {this.light = false});

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : AppColors.brown;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: color)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12.5, color: color.withValues(alpha: 0.85))),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: color),
      ],
    );
  }
}

/// Pratinjau mini papan Kanban pada kartu Pembagian Tugas.
class _MiniKanban extends StatelessWidget {
  final WorkspaceViewModel viewModel;

  const _MiniKanban({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    const colors = {
      WorkStatus.todo: Color(0xFFE9A98B),
      WorkStatus.inProgress: Color(0xFFB9A4D6),
      WorkStatus.review: Color(0xFF8FB5E0),
    };
    Widget column(WorkStatus s) {
      final count = viewModel.itemsByStatus(s).length;
      return Expanded(
        child: Container(
          height: 70,
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              for (var i = 0; i < count && i < 3; i++)
                Container(
                  height: 7,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(color: colors[s], borderRadius: BorderRadius.circular(4)),
                ),
            ],
          ),
        ),
      );
    }

    return Row(children: [column(WorkStatus.todo), column(WorkStatus.inProgress), column(WorkStatus.review)]);
  }
}
