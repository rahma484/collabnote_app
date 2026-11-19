import 'package:flutter/material.dart';

import '../../domain/models/note_model.dart';
import '../core/app_colors.dart';
import '../core/app_widgets.dart';
import '../core/formatters.dart';
import 'workspace_view_model.dart';

/// Catatan Pribadi (individu) atau Catatan Bersama (kelompok).
class NotesScreen extends StatelessWidget {
  final WorkspaceViewModel viewModel;

  const NotesScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (!viewModel.hasWorkspace) return const Scaffold(body: Center(child: Text('Ruang kerja tidak tersedia.')));
        final notes = viewModel.notes;
        return Scaffold(
          appBar: AppBar(title: Text(viewModel.isGroup ? 'Catatan Bersama' : 'Catatan Pribadi')),
          floatingActionButton: FloatingActionButton(
            onPressed: () => showNoteEditor(context, viewModel),
            child: const Icon(Icons.add, size: 28),
          ),
          body: notes.isEmpty
              ? const EmptyState(icon: Icons.edit_note, message: 'Belum ada catatan. Ketuk + untuk menambah catatan.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                  itemCount: notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _NoteCard(viewModel: viewModel, note: notes[i]),
                ),
        );
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  final WorkspaceViewModel viewModel;
  final NoteModel note;

  const _NoteCard({required this.viewModel, required this.note});

  @override
  Widget build(BuildContext context) {
    return ExpandableCard(
      header: Row(
        children: [
          const Icon(Icons.sticky_note_2_outlined, color: AppColors.mocca),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                Text(
                  viewModel.isGroup && note.authorName.isNotEmpty
                      ? '${note.authorName}  •  ${formatDateShort(note.updatedAt)}'
                      : formatDateShort(note.updatedAt),
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Icon(Icons.expand_more, color: AppColors.mocca),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note.content.isEmpty ? '(Catatan kosong)' : note.content),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => showNoteEditor(context, viewModel, note: note),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: () async {
                  final ok = await showConfirmDialog(context, title: 'Hapus Catatan?', message: 'Catatan "${note.title}" akan dihapus.');
                  if (ok) await viewModel.deleteNote(note.id);
                },
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                label: const Text('Hapus', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet tambah / edit catatan.
Future<void> showNoteEditor(BuildContext context, WorkspaceViewModel vm, {NoteModel? note}) {
  final title = TextEditingController(text: note?.title ?? '');
  final content = TextEditingController(text: note?.content ?? '');
  final formKey = GlobalKey<FormState>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(note == null ? 'Tambah Catatan' : 'Edit Catatan', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              LabeledField(
                label: 'Judul',
                controller: title,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
              ),
              LabeledField(label: 'Isi Catatan', controller: content, maxLines: 6),
              PrimaryButton(
                label: 'Simpan Catatan',
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  if (note == null) {
                    await vm.addNote(title.text, content.text);
                  } else {
                    await vm.updateNote(note.id, title.text, content.text);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
