import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/reference_model.dart';
import '../core/app_colors.dart';
import '../core/app_widgets.dart';
import 'workspace_view_model.dart';

IconData referenceIcon(ReferenceType t) {
  switch (t) {
    case ReferenceType.jurnal:
      return Icons.menu_book_outlined;
    case ReferenceType.website:
      return Icons.language;
    case ReferenceType.buku:
      return Icons.auto_stories_outlined;
    case ReferenceType.dokumentasi:
      return Icons.integration_instructions_outlined;
    case ReferenceType.materi:
      return Icons.school_outlined;
  }
}

/// Referensi (pribadi atau bersama): tambah, edit, hapus, dan buka tautan.
class ReferencesScreen extends StatelessWidget {
  final WorkspaceViewModel viewModel;

  const ReferencesScreen({super.key, required this.viewModel});

  Future<void> _open(BuildContext context, ReferenceModel r) async {
    var url = r.url.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) url = 'https://$url';
    bool ok = false;
    try {
      ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) showSnack(context, 'Tautan tidak dapat dibuka.');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (!viewModel.hasWorkspace) return const Scaffold(body: Center(child: Text('Ruang kerja tidak tersedia.')));
        final refs = viewModel.references;
        return Scaffold(
          appBar: AppBar(title: Text(viewModel.isGroup ? 'Referensi Bersama' : 'Referensi')),
          floatingActionButton: FloatingActionButton(
            onPressed: () => showReferenceEditor(context, viewModel),
            child: const Icon(Icons.add, size: 28),
          ),
          body: refs.isEmpty
              ? const EmptyState(icon: Icons.link, message: 'Belum ada referensi. Simpan tautan jurnal, website, atau buku di sini.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                  itemCount: refs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final r = refs[i];
                    return PressableScale(
                      onTap: () => _open(context, r),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            Icon(referenceIcon(r.type), color: AppColors.mocca, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                  Text(r.url, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.moccaDark)),
                                  if (r.note.isNotEmpty) Text(r.note, style: const TextStyle(fontSize: 12.5)),
                                  const SizedBox(height: 4),
                                  Pill(label: r.type.label, background: AppColors.chip, foreground: AppColors.brown, fontSize: 11),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              color: AppColors.cream,
                              onSelected: (v) async {
                                if (v == 'open') {
                                  _open(context, r);
                                } else if (v == 'edit') {
                                  showReferenceEditor(context, viewModel, reference: r);
                                } else if (v == 'delete') {
                                  final ok = await showConfirmDialog(context, title: 'Hapus Referensi?', message: '"${r.title}" akan dihapus.');
                                  if (ok) await viewModel.deleteReference(r.id);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'open', child: Text('Buka Tautan')),
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'delete', child: Text('Hapus')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

Future<void> showReferenceEditor(BuildContext context, WorkspaceViewModel vm, {ReferenceModel? reference}) {
  final title = TextEditingController(text: reference?.title ?? '');
  final url = TextEditingController(text: reference?.url ?? '');
  final note = TextEditingController(text: reference?.note ?? '');
  var type = reference?.type ?? ReferenceType.website;
  final formKey = GlobalKey<FormState>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
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
                Text(reference == null ? 'Tambah Referensi' : 'Edit Referensi', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                LabeledField(
                  label: 'Judul',
                  controller: title,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
                ),
                LabeledField(
                  label: 'Tautan (URL)',
                  controller: url,
                  keyboardType: TextInputType.url,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Tautan wajib diisi' : null,
                ),
                const Text('Jenis', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                DropdownButtonFormField<ReferenceType>(
                  initialValue: type,
                  items: [for (final t in ReferenceType.values) DropdownMenuItem(value: t, child: Text(t.label))],
                  onChanged: (v) => setState(() => type = v ?? type),
                ),
                const SizedBox(height: 14),
                LabeledField(label: 'Catatan (opsional)', controller: note, maxLines: 2),
                PrimaryButton(
                  label: 'Simpan Referensi',
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    if (reference == null) {
                      await vm.addReference(title.text, url.text, type, note.text);
                    } else {
                      await vm.updateReference(reference.id, title.text, url.text, type, note.text);
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
