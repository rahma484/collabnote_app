import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/draft_store.dart';
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

/// Bottom sheet tambah / edit catatan. Isi disimpan otomatis sebagai draf lokal
/// (SharedPreferences) dan dipulihkan bila editor dibuka lagi sebelum disimpan.
Future<void> showNoteEditor(BuildContext context, WorkspaceViewModel vm, {NoteModel? note}) {
  final drafts = context.read<DraftStore>();
  final key = 'note_${vm.assignment?.id ?? 'x'}_${note?.id ?? 'baru'}';
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _NoteEditorSheet(vm: vm, note: note, drafts: drafts, draftKey: key),
  );
}

class _NoteEditorSheet extends StatefulWidget {
  final WorkspaceViewModel vm;
  final NoteModel? note;
  final DraftStore drafts;
  final String draftKey;

  const _NoteEditorSheet({required this.vm, required this.note, required this.drafts, required this.draftKey});

  @override
  State<_NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<_NoteEditorSheet> {
  late final TextEditingController _title = TextEditingController(text: widget.note?.title ?? '');
  late final TextEditingController _content = TextEditingController(text: widget.note?.content ?? '');
  final _formKey = GlobalKey<FormState>();
  bool _restored = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _restore();
    _title.addListener(_autoSave);
    _content.addListener(_autoSave);
  }

  Future<void> _restore() async {
    final d = await widget.drafts.load(widget.draftKey);
    if (d == null || !mounted) return;
    final t = d['title'] ?? '';
    final c = d['content'] ?? '';
    if (t.isEmpty && c.isEmpty) return;
    if (t == _title.text && c == _content.text) return;
    setState(() {
      _title.text = t;
      _content.text = c;
      _restored = true;
    });
  }

  void _autoSave() {
    if (_saved) return;
    widget.drafts.save(widget.draftKey, {'title': _title.text, 'content': _content.text});
  }

  Future<void> _discardDraft() async {
    await widget.drafts.clear(widget.draftKey);
    if (!mounted) return;
    setState(() {
      _title.text = widget.note?.title ?? '';
      _content.text = widget.note?.content ?? '';
      _restored = false;
    });
    // Hapus draf lagi: pengisian ulang di atas memicu auto-simpan.
    await widget.drafts.clear(widget.draftKey);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _saved = true;
    if (widget.note == null) {
      await widget.vm.addNote(_title.text, _content.text);
    } else {
      await widget.vm.updateNote(widget.note!.id, _title.text, _content.text);
    }
    await widget.drafts.clear(widget.draftKey);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.note == null ? 'Tambah Catatan' : 'Edit Catatan', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: _restored
                    ? Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                        decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.history, size: 18, color: AppColors.mocca),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('Draf yang belum disimpan dipulihkan.', style: TextStyle(fontSize: 12.5))),
                            TextButton(onPressed: _discardDraft, child: const Text('Buang')),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              LabeledField(
                label: 'Judul',
                controller: _title,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
              ),
              LabeledField(label: 'Isi Catatan', controller: _content, maxLines: 6),
              PrimaryButton(label: 'Simpan Catatan', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
