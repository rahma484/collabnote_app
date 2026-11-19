import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/local_file_service.dart';

import '../../domain/models/submission_model.dart';
import '../../domain/models/work_item_model.dart';
import '../core/app_colors.dart';
import '../core/app_widgets.dart';
import '../core/formatters.dart';
import 'documents_screen.dart';
import 'workspace_view_model.dart';

/// Pembagian Tugas (Kanban): To Do, In Progress, Review, Done.
class KanbanScreen extends StatelessWidget {
  final WorkspaceViewModel viewModel;

  const KanbanScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (!viewModel.hasWorkspace || !viewModel.isGroup) {
          return const Scaffold(body: Center(child: Text('Ruang kerja tidak tersedia.')));
        }
        final pct = (viewModel.progress * 100).round();
        return Scaffold(
          appBar: AppBar(title: const Text('Pembagian Tugas'), actions: const [Padding(padding: EdgeInsets.only(right: 16), child: LogoCircleButton())]),
          floatingActionButton: FloatingActionButton(
            onPressed: () => showWorkItemForm(context, viewModel),
            child: const Icon(Icons.add, size: 28),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Text('$pct%', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 12),
                    Expanded(child: ProgressBarSoft(value: viewModel.progress, height: 9)),
                    const SizedBox(width: 12),
                    Text('${viewModel.workDone}/${viewModel.workItems.length} Done', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: viewModel.workItems.isEmpty
                    ? const EmptyState(icon: Icons.view_kanban_outlined, message: 'Belum ada bagian pekerjaan. Ketuk + untuk membagi pekerjaan ke anggota.')
                    : ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                        children: [
                          for (final s in WorkStatus.values) _Column(viewModel: viewModel, status: s),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Column extends StatelessWidget {
  final WorkspaceViewModel viewModel;
  final WorkStatus status;

  const _Column({required this.viewModel, required this.status});

  @override
  Widget build(BuildContext context) {
    final items = viewModel.itemsByStatus(status);
    return Container(
      width: 205,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
            child: Row(
              children: [
                Expanded(child: Text(status.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                Pill(label: '${items.length}', background: AppColors.chip, foreground: AppColors.brown, fontSize: 11),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PressableScale(
                      onTap: () => showWorkItemSheet(context, viewModel, item.id),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                MemberAvatar(name: viewModel.memberName(item.assigneeId), size: 22),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(viewModel.memberName(item.assigneeId).split(' ').first, style: const TextStyle(fontSize: 12.5)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Deadline: ${formatDayMonth(item.deadline)}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Detail

void showWorkItemSheet(BuildContext context, WorkspaceViewModel vm, String itemId) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _WorkItemSheet(viewModel: vm, itemId: itemId),
  );
}

class _WorkItemSheet extends StatefulWidget {
  final WorkspaceViewModel viewModel;
  final String itemId;

  const _WorkItemSheet({required this.viewModel, required this.itemId});

  @override
  State<_WorkItemSheet> createState() => _WorkItemSheetState();
}

class _WorkItemSheetState extends State<_WorkItemSheet> {
  WorkStatus? _status;
  ReviewStatus? _review;
  final _reviewNote = TextEditingController();
  final _submitNote = TextEditingController();
  bool _initialized = false;

  WorkspaceViewModel get vm => widget.viewModel;

  @override
  void dispose() {
    _reviewNote.dispose();
    _submitNote.dispose();
    super.dispose();
  }

  WorkItemModel? _item() {
    for (final i in vm.workItems) {
      if (i.id == widget.itemId) return i;
    }
    return null;
  }

  void _showSubmission(SubmissionModel s) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.fileName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Diunggah oleh ${vm.memberName(s.memberId)}'),
            Text('Waktu: ${formatDateShort(s.submittedAt)}'),
            const SizedBox(height: 8),
            Text('Catatan: ${s.note.isEmpty ? '-' : s.note}'),
            const SizedBox(height: 8),
            Text('Status review: ${s.reviewStatus.label}', style: const TextStyle(fontWeight: FontWeight.w600)),
            if (s.reviewNote.isNotEmpty) Text('Catatan revisi: ${s.reviewNote}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final msg = await vm.downloadSubmission(s);
              // ignore: use_build_context_synchronously
              if (context.mounted) showSnack(context, msg);
            },
            child: const Text('Unduh'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final item = _item();
        if (item == null) return const SizedBox(height: 200, child: Center(child: Text('Pekerjaan tidak ditemukan.')));
        final subs = vm.submissionsOf(item.id);
        final latest = subs.isEmpty ? null : subs.first;
        if (!_initialized) {
          _initialized = true;
          _status = item.status;
          _review = latest?.reviewStatus ?? ReviewStatus.pending;
          _reviewNote.text = latest?.reviewNote ?? '';
        }
        final canEdit = vm.canEditItem(item);
        final statuses = WorkStatus.values.where((s) => s != WorkStatus.done || vm.isOwner || item.status == WorkStatus.done).toList();

        Widget field(String label, String value) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.mocca)),
                  Text(value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 15.5)),
                ],
              ),
            );

        return Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Detail Pekerjaan', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800))),
                    if (vm.isOwner) ...[
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () {
                          Navigator.pop(context);
                          showWorkItemForm(context, vm, item: item);
                        },
                      ),
                      IconButton(
                        tooltip: 'Hapus',
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                        onPressed: () async {
                          final ok = await showConfirmDialog(context, title: 'Hapus Pekerjaan?', message: '"${item.title}" beserta hasil yang dikumpulkan akan dihapus.');
                          if (!ok) return;
                          await vm.deleteWorkItem(item.id);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                field('Nama:', item.title),
                field('Deskripsi:', item.description),
                field('Anggota Bertanggung Jawab:', vm.memberName(item.assigneeId)),
                field('Deadline:', formatDate(item.deadline)),
                if (item.attachmentName != null) ...[
                  const SizedBox(height: 4),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.attach_file, color: AppColors.mocca),
                    title: Text(item.attachmentName!, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: const Text('Lampiran instruksi pekerjaan'),
                    trailing: IconButton(
                      tooltip: 'Unduh lampiran',
                      icon: const Icon(Icons.download_outlined),
                      onPressed: () async {
                        final message = await vm.downloadWorkAttachment(item);
                        if (context.mounted) showSnack(context, message);
                      },
                    ),
                  ),
                ],
                const Text('Status:', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.mocca)),
                const SizedBox(height: 4),
                DropdownButtonFormField<WorkStatus>(
                  initialValue: _status,
                  items: [for (final s in statuses) DropdownMenuItem(value: s, child: Text(s.label))],
                  onChanged: canEdit ? (v) => setState(() => _status = v) : null,
                ),
                const Divider(height: 30),
                const Text('Pengumpulan Anggota', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                if (subs.isEmpty)
                  const Text('Belum ada hasil yang dikumpulkan.', style: TextStyle(color: AppColors.textMuted)),
                for (final s in subs)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(documentIcon(s.extension), color: AppColors.danger, size: 30),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.fileName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  Text('Uploaded by ${vm.memberName(s.memberId)}', style: const TextStyle(fontSize: 12.5)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            MemberAvatar(name: vm.memberName(s.memberId), size: 26),
                            const SizedBox(width: 8),
                            Expanded(child: Text(vm.memberName(s.memberId).split(' ').first)),
                            Pill(label: s.reviewStatus.label, background: AppColors.chip, foreground: AppColors.brown, fontSize: 11),
                            const SizedBox(width: 8),
                            PressableScale(
                              onTap: () => _showSubmission(s),
                              child: const Pill(label: 'Lihat', background: AppColors.mocca, foreground: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                if (canEdit) ...[
                  LabeledField(label: 'Catatan hasil (opsional)', controller: _submitNote, maxLines: 2),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brown,
                      side: const BorderSide(color: AppColors.mocca),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final msg = await vm.submitResult(item, _submitNote.text);
                      if (msg == null) return;
                      _submitNote.clear();
                      setState(() {
                        _initialized = false;
                      });
                      if (context.mounted) showSnack(context, msg);
                    },
                    icon: const Icon(Icons.upload_file_outlined),
                    label: Text(item.assigneeId == vm.me?.id ? 'Unggah Hasil' : 'Unggah Hasil (simulasi anggota)'),
                  ),
                ],
                const SizedBox(height: 18),
                const Text('Status Review', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                DropdownButtonFormField<ReviewStatus>(
                  initialValue: _review,
                  items: [for (final r in ReviewStatus.values) DropdownMenuItem(value: r, child: Text(r.label))],
                  onChanged: (vm.canReview && latest != null) ? (v) => setState(() => _review = v) : null,
                ),
                if (!vm.canReview)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Hanya Pemilik Kelompok yang dapat memeriksa hasil.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  )
                else if (latest == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Pemeriksaan tersedia setelah ada hasil yang dikumpulkan.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ),
                if (vm.canReview && latest != null) ...[
                  const SizedBox(height: 12),
                  LabeledField(label: 'Catatan revisi', controller: _reviewNote, maxLines: 2),
                ],
                const SizedBox(height: 14),
                PrimaryButton(
                  label: 'Simpan Perubahan',
                  onPressed: canEdit || vm.canReview
                      ? () async {
                          await vm.applyItemChanges(
                            item,
                            status: _status ?? item.status,
                            review: _review ?? ReviewStatus.pending,
                            reviewNote: _reviewNote.text.trim(),
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            showSnack(context, 'Perubahan disimpan.');
                          }
                        }
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ----------------------------------------------------------------- Form

/// Bottom sheet tambah / edit bagian pekerjaan. Penanggung jawab wajib dipilih.
Future<void> showWorkItemForm(BuildContext context, WorkspaceViewModel vm, {WorkItemModel? item}) {
  final title = TextEditingController(text: item?.title ?? '');
  final desc = TextEditingController(text: item?.description ?? '');
  final formKey = GlobalKey<FormState>();
  final members = vm.members.where((m) => m.status.name == 'aktif').toList();
  String? assignee = item?.assigneeId ?? (members.isNotEmpty ? (vm.me?.id ?? members.first.id) : null);
  if (assignee != null && !members.any((m) => m.id == assignee)) {
    assignee = members.isNotEmpty ? members.first.id : null;
  }
  DateTime deadline = item?.deadline ?? DateTime.now().add(const Duration(days: 7));
  WorkStatus status = item?.status ?? WorkStatus.todo;
  PickedFileData? attachment;
  bool removeAttachment = false;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item == null ? 'Tambah Bagian Pekerjaan' : 'Edit Bagian Pekerjaan', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                LabeledField(
                  label: 'Nama Pekerjaan',
                  controller: title,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama pekerjaan wajib diisi' : null,
                ),
                LabeledField(label: 'Deskripsi', controller: desc, maxLines: 3),
                const Text('Penanggung Jawab', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: assignee,
                  validator: (v) => v == null ? 'Pilih penanggung jawab' : null,
                  items: [for (final m in members) DropdownMenuItem(value: m.id, child: Text(m.name))],
                  onChanged: (v) => setState(() => assignee = v),
                ),
                const SizedBox(height: 14),
                const Text('Deadline Bagian', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                PressableScale(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: deadline,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                    );
                    if (picked != null) setState(() => deadline = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.beige)),
                    child: Row(
                      children: [
                        Expanded(child: Text(formatDate(deadline))),
                        const Icon(Icons.calendar_today_outlined, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Dokumen/Lampiran Pekerjaan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.beige)),
                  child: Row(children: [
                    const Icon(Icons.attach_file, color: AppColors.mocca),
                    const SizedBox(width: 8),
                    Expanded(child: Text(attachment?.name ?? item?.attachmentName ?? 'Belum ada dokumen', maxLines: 1, overflow: TextOverflow.ellipsis)),
                    TextButton.icon(
                      onPressed: () async {
                        final selected = await ctx.read<LocalFileService>().pickFile();
                        if (selected != null) setState(() => attachment = selected);
                      },
                      icon: const Icon(Icons.upload_file_outlined, size: 18),
                      label: const Text('Pilih'),
                    ),
                    if (attachment != null || item?.attachmentName != null)
                      IconButton(
                        tooltip: 'Hapus lampiran',
                        onPressed: () => setState(() { attachment = null; removeAttachment = true; }),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                  ]),
                ),
                const SizedBox(height: 14),
                const Text('Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                DropdownButtonFormField<WorkStatus>(
                  initialValue: status,
                  items: [
                    for (final s in WorkStatus.values)
                      if (s != WorkStatus.done || vm.isOwner) DropdownMenuItem(value: s, child: Text(s.label)),
                  ],
                  onChanged: (v) => setState(() => status = v ?? status),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Simpan Pekerjaan',
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    String? attachmentPath = removeAttachment ? null : item?.attachmentPath;
                    String? attachmentName = removeAttachment ? null : item?.attachmentName;
                    if (attachment != null) {
                      attachmentPath = await ctx.read<LocalFileService>().saveBytes(attachment!.name, attachment!.bytes);
                      attachmentName = attachment!.name;
                    }
                    if (item == null) {
                      await vm.addWorkItem(
                        title: title.text,
                        description: desc.text,
                        assigneeId: assignee!,
                        deadline: deadline,
                        status: status,
                        attachmentPath: attachmentPath,
                        attachmentName: attachmentName,
                      );
                    } else {
                      final updated = item.copyWith(
                        title: title.text.trim(),
                        description: desc.text.trim(),
                        assigneeId: assignee,
                        deadline: deadline,
                        status: status,
                        attachmentPath: attachmentPath,
                        attachmentName: attachmentName,
                        clearAttachment: removeAttachment,
                      );
                      await vm.saveWorkItem(updated);
                      // ignore: use_build_context_synchronously
                      if (attachment != null || removeAttachment) await ctx.read<LocalFileService>().delete(item.attachmentPath);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
