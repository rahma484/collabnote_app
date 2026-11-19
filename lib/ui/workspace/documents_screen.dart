import 'package:flutter/material.dart';

import '../../domain/models/document_model.dart';
import '../../domain/models/template_model.dart';
import '../core/app_colors.dart';
import '../core/app_widgets.dart';
import '../core/formatters.dart';
import '../templates/template_gallery_screen.dart';
import 'workspace_view_model.dart';

IconData documentIcon(String ext) {
  switch (ext.toLowerCase()) {
    case 'docx':
    case 'doc':
      return Icons.description_outlined;
    case 'xlsx':
    case 'xls':
    case 'csv':
      return Icons.table_chart_outlined;
    case 'pptx':
    case 'ppt':
      return Icons.slideshow_outlined;
    case 'pdf':
      return Icons.picture_as_pdf_outlined;
    case 'png':
    case 'jpg':
    case 'jpeg':
      return Icons.image_outlined;
    case 'md':
    case 'txt':
      return Icons.article_outlined;
    default:
      return Icons.insert_drive_file_outlined;
  }
}

/// Dokumen dan Lampiran Ruang Kerja: gunakan template, buat dokumen, unggah, unduh, dan tandai final.
class DocumentsScreen extends StatefulWidget {
  final WorkspaceViewModel viewModel;

  const DocumentsScreen({super.key, required this.viewModel});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  String _filter = 'Semua';
  static const _filters = ['Semua', 'Draft', 'Final', 'Lampiran'];

  WorkspaceViewModel get vm => widget.viewModel;

  List<DocumentModel> _filtered() {
    final all = vm.documents;
    switch (_filter) {
      case 'Draft':
        return all.where((d) => d.kind == DocumentKind.draft).toList();
      case 'Final':
        return all.where((d) => d.kind == DocumentKind.finalDoc).toList();
      case 'Lampiran':
        return all.where((d) => d.kind == DocumentKind.attachment || d.kind == DocumentKind.instruction).toList();
      default:
        return all;
    }
  }

  void _openActions(DocumentModel doc) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final canFinal = doc.kind == DocumentKind.draft || doc.kind == DocumentKind.finalDoc;
        Widget tile(IconData icon, String label, VoidCallback onTap, {Color? color}) => ListTile(
              leading: Icon(icon, color: color ?? AppColors.mocca),
              title: Text(label, style: TextStyle(color: color)),
              onTap: () {
                Navigator.pop(ctx);
                onTap();
              },
            );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(doc.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
              tile(Icons.download_outlined, 'Unduh File', () async {
                final msg = await vm.downloadDocument(doc);
                if (mounted) showSnack(context, msg);
              }),
              if (doc.isEditableInApp)
                tile(Icons.edit_outlined, 'Edit Isi Dokumen', () => pushSlideUp<void>(context, DocumentEditorScreen(viewModel: vm, document: doc)))
              else
                tile(Icons.upload_file_outlined, 'Unggah Versi Hasil Pengerjaan', () async {
                  final msg = await vm.replaceDocumentFile(doc);
                  if (msg != null && mounted) showSnack(context, msg);
                }),
              if (canFinal)
                tile(
                  doc.isFinal ? Icons.undo : Icons.verified_outlined,
                  doc.isFinal ? 'Batalkan Tanda Final' : 'Simpan sebagai Hasil Final',
                  () async {
                    await vm.setDocumentFinal(doc, !doc.isFinal);
                    if (mounted) showSnack(context, doc.isFinal ? 'Dokumen kembali menjadi draft.' : 'Dokumen ditandai sebagai hasil final.');
                  },
                ),
              tile(Icons.delete_outline, 'Hapus', () async {
                final ok = await showConfirmDialog(context, title: 'Hapus Dokumen?', message: '"${doc.title}" akan dihapus dari Ruang Kerja.');
                if (ok) await vm.deleteDocument(doc);
              }, color: AppColors.danger),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (!vm.hasWorkspace) return const Scaffold(body: Center(child: Text('Ruang kerja tidak tersedia.')));
        final docs = _filtered();
        return Scaffold(
          appBar: AppBar(title: Text(vm.isGroup ? 'Dokumen Kelompok' : 'Dokumen')),
          floatingActionButton: FloatingActionButton(
            onPressed: () => showAddDocumentSheet(context, vm),
            child: const Icon(Icons.add, size: 28),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
            children: [
              PillFilterRow(options: _filters, selected: _filter, onSelected: (v) => setState(() => _filter = v)),
              if (vm.isGroup && vm.isOwner) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brown,
                    side: const BorderSide(color: AppColors.mocca),
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final msg = await vm.mergeApprovedResults();
                    if (context.mounted) showSnack(context, msg);
                  },
                  icon: const Icon(Icons.merge_type),
                  label: const Text('Gabungkan Hasil Anggota'),
                ),
              ],
              const SizedBox(height: 12),
              if (docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: EmptyState(icon: Icons.folder_open, message: 'Belum ada dokumen. Ketuk + untuk memakai template atau mengunggah file.'),
                )
              else
                for (final d in docs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PressableScale(
                      onTap: () => _openActions(d),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: d.isFinal ? AppColors.mint.withValues(alpha: 0.6) : AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(documentIcon(d.extension), size: 30, color: AppColors.mocca),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                  Text(
                                    '${d.fileName}  •  ${_sourceLabel(d)}${d.size > 0 ? '  •  ${formatSize(d.size)}' : ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Pill(
                              label: d.kind.label,
                              background: d.isFinal ? AppColors.doneGreen : AppColors.chip,
                              foreground: d.isFinal ? Colors.white : AppColors.brown,
                              fontSize: 11,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  String _sourceLabel(DocumentModel d) {
    switch (d.source) {
      case DocumentSource.template:
        return 'Template';
      case DocumentSource.created:
        return 'Dibuat di aplikasi';
      case DocumentSource.uploaded:
        return 'Diunggah';
      case DocumentSource.merged:
        return 'Hasil gabungan';
    }
  }
}

/// Menu tambah dokumen: template, dokumen teks, unggah draft, unggah lampiran.
void showAddDocumentSheet(BuildContext context, WorkspaceViewModel vm) {
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) {
      Widget tile(IconData icon, String title, String subtitle, VoidCallback onTap) => ListTile(
            leading: Icon(icon, color: AppColors.mocca),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
            onTap: () {
              Navigator.pop(ctx);
              onTap();
            },
          );
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            tile(Icons.auto_awesome_motion_outlined, 'Gunakan Template', 'Pilih dari Smart Template Gallery', () async {
              final t = await pushSlideUp<TemplateModel>(context, const TemplateGalleryScreen());
              if (t == null) return;
              await vm.useTemplate(t);
              if (context.mounted) showSnack(context, 'Template "${t.title}" ditambahkan ke Ruang Kerja.');
            }),
            tile(Icons.edit_note, 'Buat Dokumen Teks', 'Tulis dan edit langsung di aplikasi (.md)', () {
              pushSlideUp<void>(context, DocumentEditorScreen(viewModel: vm));
            }),
            tile(Icons.upload_file_outlined, 'Unggah Dokumen Kerja', 'Simpan file draft dari perangkat', () async {
              final msg = await vm.uploadDocument(DocumentKind.draft);
              if (msg != null && context.mounted) showSnack(context, msg);
            }),
            tile(Icons.attach_file, 'Unggah Lampiran', 'Data, gambar, atau file pendukung', () async {
              final msg = await vm.uploadDocument(DocumentKind.attachment);
              if (msg != null && context.mounted) showSnack(context, msg);
            }),
          ],
        ),
      );
    },
  );
}

/// Editor dokumen teks sederhana.
class DocumentEditorScreen extends StatefulWidget {
  final WorkspaceViewModel viewModel;
  final DocumentModel? document;

  const DocumentEditorScreen({super.key, required this.viewModel, this.document});

  @override
  State<DocumentEditorScreen> createState() => _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends State<DocumentEditorScreen> {
  late final TextEditingController _title = TextEditingController(text: widget.document?.title ?? '');
  late final TextEditingController _text = TextEditingController(text: widget.document?.textContent ?? '');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = widget.viewModel;
    if (widget.document == null) {
      await vm.createTextDocument(_title.text, _text.text);
    } else {
      await vm.updateTextDocument(widget.document!.id, _title.text, _text.text);
    }
    if (!mounted) return;
    Navigator.pop(context);
    showSnack(context, 'Dokumen disimpan.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document == null ? 'Dokumen Baru' : 'Edit Dokumen'),
        actions: [TextButton(onPressed: _save, child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w700)))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            LabeledField(
              label: 'Judul Dokumen',
              controller: _title,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
            ),
            LabeledField(label: 'Isi Dokumen', controller: _text, maxLines: 16),
          ],
        ),
      ),
    );
  }
}
