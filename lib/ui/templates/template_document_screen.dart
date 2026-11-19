import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/local_file_service.dart';
import '../../data/repositories/template_repository.dart';
import '../../domain/models/template_model.dart';
import '../core/app_colors.dart';
import '../core/app_widgets.dart';

class TemplateDocumentScreen extends StatelessWidget {
  final TemplateModel template;

  const TemplateDocumentScreen({
    super.key,
    required this.template,
  });

  Future<void> _openOriginal(
    BuildContext context,
    Uint8List bytes,
  ) async {
    try {
      final extension = template.extension.toLowerCase();

      final result = await context
          .read<LocalFileService>()
          .openDocument(template.fileName, bytes);

      if (!context.mounted) return;

      if (kIsWeb) {
        if (['pdf', 'png', 'jpg', 'jpeg'].contains(extension)) {
          showSnack(
            context,
            result
                ? 'Dokumen berhasil dibuka di tab baru.'
                : 'Dokumen gagal dibuka.',
          );
        } else {
          showSnack(
            context,
            'Format Office tidak didukung untuk pratinjau browser. Dokumen diunduh.',
          );
        }
      } else {
        showSnack(
          context,
          'Dokumen berhasil dibuka.',
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      showSnack(context, 'Dokumen gagal dibuka: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final extension = template.extension.toLowerCase();

    final isImage = ['png', 'jpg', 'jpeg'].contains(extension);
    final isMarkdown = extension == 'md';

    return Scaffold(
      appBar: AppBar(
        title: Text(template.title),
      ),
      body: FutureBuilder<Uint8List?>(
        future: context.read<TemplateRepository>().bytesOf(template),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(
              child: Text('Template gagal dibuka.'),
            );
          }

          final bytes = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                template.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Format: ${template.extension.toUpperCase()}',
                style: TextStyle(
                  color: AppColors.textMuted,
                ),
              ),

              const SizedBox(height: 20),

              if (isImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                  ),
                )
              else if (isMarkdown)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SelectableText(
                    utf8.decode(bytes, allowMalformed: true),
                    style: const TextStyle(fontSize: 14),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 60,
                        color: AppColors.brown,
                      ),

                      const SizedBox(height: 14),

                      Text(
                        template.fileName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Dokumen asli tersedia. Tekan tombol di bawah untuk membuka file menggunakan aplikasi yang mendukung format dokumen ini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Buka dokumen asli.
              PrimaryButton(
                label: 'Buka Dokumen Asli',
                icon: Icons.open_in_new,
                onPressed: () => _openOriginal(context, bytes),
              ),

              const SizedBox(height: 10),

              // Gunakan template.
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Gunakan Template Ini'),
              ),

              const SizedBox(height: 10),

              // Unduh template.
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    final result = await context
                        .read<LocalFileService>()
                        .exportBytes(template.fileName, bytes);

                    if (!context.mounted) return;

                    showSnack(
                      context,
                      result
                          ? 'Template berhasil diunduh.'
                          : 'Unduhan dibatalkan.',
                    );
                  } catch (e) {
                    if (!context.mounted) return;

                    showSnack(
                      context,
                      'Template gagal diunduh: $e',
                    );
                  }
                },
                icon: const Icon(Icons.download),
                label: const Text('Unduh Template'),
              ),
            ],
          );
        },
      ),
    );
  }
}
