
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/template_repository.dart';
import '../../data/services/local_file_service.dart';
import '../../domain/models/template_model.dart';
import '../core/app_colors.dart';
import '../core/app_widgets.dart';
import '../viewer/document_viewer_screen.dart';
import 'template_gallery_screen.dart';
import 'template_gallery_view_model.dart';

/// Preview template: deskripsi, kegunaan, isi/kerangka, unduh, favorit, dan gunakan.
class TemplatePreviewScreen extends StatelessWidget {
  final TemplateModel template;
  final TemplateGalleryViewModel viewModel;
  final String confirmLabel;

  const TemplatePreviewScreen({
    super.key,
    required this.template,
    required this.viewModel,
    required this.confirmLabel,
  });

  Future<void> _download(BuildContext context) async {
    try {
      final bytes = await context.read<TemplateRepository>().bytesOf(template);
      if (!context.mounted) return;
      if (bytes == null) {
        showSnack(context, 'File template tidak ditemukan.');
        return;
      }
      final ok = await context.read<LocalFileService>().exportBytes(template.fileName, bytes);
      if (!context.mounted) return;
      showSnack(context, ok ? 'Template diunduh: ${template.fileName}' : 'Unduhan dibatalkan.');
    } catch (e) {
      if (context.mounted) showSnack(context, 'Template gagal diunduh: $e');
    }
  }

  // Membuka template langsung di dalam aplikasi (tanpa mengunduh).
  Future<void> _openTemplate(BuildContext context) async {
    try {
      final bytes = await context.read<TemplateRepository>().bytesOf(template);
      if (!context.mounted) return;
      if (bytes == null) {
        showSnack(context, 'File template tidak ditemukan.');
        return;
      }
      await openFileInApp(context, fileName: template.fileName, bytes: bytes, title: template.title);
    } catch (e) {
      if (context.mounted) showSnack(context, 'Template gagal dibuka: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImage = ['png', 'jpg', 'jpeg'].contains(template.extension.toLowerCase());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Template'),
        actions: [
          ListenableBuilder(
            listenable: viewModel,
            builder: (context, _) => IconButton(
              onPressed: () => viewModel.toggleFavorite(template.id),
              icon: Icon(
                viewModel.isFavorite(template.id) ? Icons.star_rounded : Icons.star_border_rounded,
                color: AppColors.mocca,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Row(
            children: [
              Hero(
                tag: 'template-${template.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.chip,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(templateIcon(template.format), color: AppColors.brown, size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, children: [
                      Pill(label: template.format, background: AppColors.mocca, foreground: Colors.white),
                      Pill(label: template.category.label, background: AppColors.chip, foreground: AppColors.brown),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          if (isImage) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: template.assetPath.isNotEmpty
                  ? Image.asset(template.assetPath, fit: BoxFit.contain)
                  : FutureBuilder<Uint8List?>(
                      future: context.read<TemplateRepository>().bytesOf(template),
                      builder: (context, snapshot) => snapshot.data == null
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('Pratinjau gambar tidak tersedia.'),
                            )
                          : Image.memory(snapshot.data!, fit: BoxFit.contain),
                    ),
            ),
          ],
          const SectionTitle('Deskripsi'),
          Text(template.description),
          const SectionTitle('Kegunaan'),
          Text(template.usage),
          const SectionTitle('Pratinjau Isi Template'),
          if (!isImage)
            const Text(
              'Pratinjau menampilkan kerangka dan struktur dokumen. Tekan "Buka Template" untuk melihat isi file aslinya, atau "Unduh Template" untuk menyimpannya.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < template.previewLines.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${i + 1}.  ', style: const TextStyle(fontWeight: FontWeight.w700)),
                        Expanded(child: Text(template.previewLines[i])),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Tombol gunakan template
          PrimaryButton(
            label: confirmLabel,
            icon: Icons.check_circle_outline,
            onPressed: () => Navigator.pop(context, template),
          ),

          const SizedBox(height: 10),

          // Tombol buka template
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brown,
              side: const BorderSide(color: AppColors.mocca),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _openTemplate(context),
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Buka Template'),
          ),

          const SizedBox(height: 10),

          // Tombol unduh template
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brown,
              side: const BorderSide(color: AppColors.mocca),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => _download(context),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Unduh Template'),
          ),

          if (template.isCustom) ...[
            const SizedBox(height: 6),
            TextButton(
              onPressed: () async {
                final ok = await showConfirmDialog(
                  context,
                  title: 'Hapus Template?',
                  message: 'File template milik Anda akan dihapus dari aplikasi.',
                );
                if (ok && context.mounted) {
                  await context.read<TemplateRepository>().deleteCustom(template.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text(
                'Hapus Template Saya',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
