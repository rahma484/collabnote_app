import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/assignment_model.dart';
import '../../data/repositories/archive_repository.dart';
import '../../data/repositories/assignment_repository.dart';
import '../../data/repositories/workspace_repository.dart';
import '../../data/services/local_file_service.dart';
import '../../domain/models/archive_model.dart';
import '../../domain/models/document_model.dart';
import '../core/app_colors.dart';
import '../core/app_widgets.dart';
import '../core/formatters.dart';
import '../shell/navigation_controller.dart';
import '../workspace/documents_screen.dart';
import '../workspace/references_screen.dart';

/// Detail Arsip: ringkasan, dokumen final, catatan, referensi, riwayat, ekspor, dan buka kembali.
class ArchiveDetailScreen extends StatelessWidget {
  final String archiveId;

  const ArchiveDetailScreen({super.key, required this.archiveId});

  Future<void> _export(BuildContext context, ArchiveModel a) async {
    final ws = context.read<WorkspaceRepository>();
    final buffer = StringBuffer()
      ..writeln('# ${a.title}')
      ..writeln()
      ..writeln('- Mata kuliah: ${a.courseName}')
      ..writeln('- Semester: ${a.semester} (${a.academicYear})')
      ..writeln('- Mode: ${a.mode.label}')
      ..writeln('- Deadline: ${formatDate(a.deadline)}')
      ..writeln('- Selesai: ${formatDate(a.completedAt)}')
      ..writeln('- Diarsipkan: ${formatDate(a.archivedAt)}');
    if (a.memberNames.isNotEmpty) {
      buffer.writeln('- Anggota: ${a.memberNames.join(', ')}');
    }
    buffer
      ..writeln()
      ..writeln('## Ringkasan')
      ..writeln(a.summary.isEmpty ? '-' : a.summary)
      ..writeln()
      ..writeln('## Dokumen Final');
    for (final d in ws.documentsOf(a.assignmentId).where((d) => d.isFinal)) {
      buffer.writeln('- ${d.fileName}');
    }
    buffer
      ..writeln()
      ..writeln('## Referensi');
    for (final r in ws.referencesOf(a.assignmentId)) {
      buffer.writeln('- ${r.title} (${r.url})');
    }
    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    final ok = await context
        .read<LocalFileService>()
        .exportBytes('${a.title} - Ringkasan.md', bytes);
    if (context.mounted) {
      showSnack(context, ok ? 'Ringkasan diekspor.' : 'Ekspor dibatalkan.');
    }
  }

  Future<void> _restore(BuildContext context, ArchiveModel a) async {
    final repo = context.read<AssignmentRepository>();
    final nav = context.read<NavigationController>();
    final ok = await showConfirmDialog(
      context,
      title: 'Kembalikan ke Penugasan?',
      message:
          'Penugasan akan aktif kembali di daftar Penugasan. Dokumen dan referensi tetap utuh.',
      confirmLabel: 'Kembalikan',
    );
    if (!ok || !context.mounted) return;
    await repo.restoreFromArchive(a.assignmentId);
    if (!context.mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    nav.goTo(1);
    showSnack(context, 'Penugasan dikembalikan ke daftar Penugasan.');
  }

  @override
  Widget build(BuildContext context) {
    final archives = context.watch<ArchiveRepository>();
    final ws = context.watch<WorkspaceRepository>();
    final a = archives.byId(archiveId);
    if (a == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final finalDocs =
        ws.documentsOf(a.assignmentId).where((d) => d.isFinal).toList();
    final allDocs = ws.documentsOf(a.assignmentId);
    final notes = ws.notesOf(a.assignmentId);
    final refs = ws.referencesOf(a.assignmentId);

    Widget row(String label, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PressableScale(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Expanded(
                      child: Text(label, style: const TextStyle(fontSize: 16))),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );

    Widget info(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  width: 118,
                  child: Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.mocca))),
              Expanded(child: Text(value)),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(toolbarHeight: 56),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text('Detail Arsip: ${a.title}',
              style: const TextStyle(
                  fontSize: 25, fontWeight: FontWeight.w800, height: 1.2)),
          const SizedBox(height: 10),
          const Align(
              alignment: Alignment.centerLeft,
              child: Pill(
                  label: 'Selesai',
                  background: AppColors.mint,
                  foreground: AppColors.mintText)),
          const SectionTitle('Ringkasan'),
          Text(a.summary.isEmpty ? '-' : a.summary),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                info('Mata Kuliah', a.courseName),
                info(
                    'Semester', 'Semester ${a.semester}  •  ${a.academicYear}'),
                info('Mode', a.mode.label),
                if (a.assignedDate != null)
                  info('Diberikan', formatDate(a.assignedDate!)),
                info('Deadline', formatDate(a.deadline)),
                info('Selesai', formatDate(a.completedAt)),
                info('Diarsipkan', formatDate(a.archivedAt)),
                if (a.templateTitle != null) info('Template', a.templateTitle!),
                if (a.memberNames.isNotEmpty)
                  info('Anggota', a.memberNames.join(', ')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          row(
              'Dokumen Final (${finalDocs.length} file)',
              () => pushSlideUp<void>(
                  context,
                  _DocumentsView(
                      title: 'Dokumen Final',
                      docs: finalDocs.isEmpty ? allDocs : finalDocs))),
          row('Catatan (${notes.length})',
              () => pushSlideUp<void>(context, _NotesView(archive: a))),
          row('Referensi (${refs.length})',
              () => pushSlideUp<void>(context, _ReferencesView(archive: a))),
          const SectionTitle('Riwayat Penyelesaian'),
          for (final e in a.history)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child:
                          Icon(Icons.circle, size: 10, color: AppColors.mocca)),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${formatDate(e.date)}  -  ${e.text}')),
                ],
              ),
            ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brown,
              side: const BorderSide(color: AppColors.mocca),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => _export(context, a),
            icon: const Icon(Icons.ios_share),
            label: const Text('Ekspor Ringkasan'),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
              label: 'Kembalikan ke Penugasan',
              onPressed: () => _restore(context, a)),
        ],
      ),
    );
  }
}

/// Daftar dokumen arsip (hanya lihat dan unduh).
class _DocumentsView extends StatelessWidget {
  final String title;
  final List<DocumentModel> docs;

  const _DocumentsView({required this.title, required this.docs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: docs.isEmpty
          ? const EmptyState(
              icon: Icons.folder_open, message: 'Tidak ada dokumen.')
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                for (final d in docs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Icon(documentIcon(d.extension),
                              color: AppColors.mocca, size: 30),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                Text(d.fileName,
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Unduh',
                            icon: const Icon(Icons.download_outlined),
                            onPressed: () async {
                              final bytes = await context
                                  .read<WorkspaceRepository>()
                                  .bytesOf(d);
                              if (!context.mounted) return;
                              if (bytes == null) {
                                showSnack(context, 'File tidak tersedia.');
                                return;
                              }
                              final ok = await context
                                  .read<LocalFileService>()
                                  .exportBytes(d.fileName, bytes);
                              if (context.mounted) {
                                showSnack(
                                    context,
                                    ok
                                        ? 'File disimpan.'
                                        : 'Unduhan dibatalkan.');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _NotesView extends StatelessWidget {
  final ArchiveModel archive;

  const _NotesView({required this.archive});

  @override
  Widget build(BuildContext context) {
    final notes =
        context.watch<WorkspaceRepository>().notesOf(archive.assignmentId);
    return Scaffold(
      appBar: AppBar(title: const Text('Catatan')),
      body: notes.isEmpty
          ? const EmptyState(
              icon: Icons.edit_note, message: 'Tidak ada catatan.')
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                for (final n in notes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ExpandableCard(
                      header: Row(
                        children: [
                          Expanded(
                              child: Text(n.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15.5))),
                          const Icon(Icons.expand_more, color: AppColors.mocca),
                        ],
                      ),
                      body: Text(n.content.isEmpty ? '-' : n.content),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ReferencesView extends StatelessWidget {
  final ArchiveModel archive;

  const _ReferencesView({required this.archive});

  @override
  Widget build(BuildContext context) {
    final refs =
        context.watch<WorkspaceRepository>().referencesOf(archive.assignmentId);
    return Scaffold(
      appBar: AppBar(title: const Text('Referensi')),
      body: refs.isEmpty
          ? const EmptyState(icon: Icons.link, message: 'Tidak ada referensi.')
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                for (final r in refs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PressableScale(
                      onTap: () async {
                        var url = r.url.trim();
                        if (!url.startsWith('http')) url = 'https://$url';
                        bool ok = false;
                        try {
                          ok = await launchUrl(Uri.parse(url),
                              mode: LaunchMode.externalApplication);
                        } catch (_) {}
                        if (!ok && context.mounted) {
                          showSnack(context, 'Tautan tidak dapat dibuka.');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            Icon(referenceIcon(r.type), color: AppColors.mocca),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  Text(r.url,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.moccaDark)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
