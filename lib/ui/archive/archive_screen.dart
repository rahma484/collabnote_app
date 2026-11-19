import 'package:flutter/material.dart';

import '../../domain/models/archive_model.dart';
import '../core/app_colors.dart';
import '../core/app_widgets.dart';
import '../core/formatters.dart';
import 'archive_detail_screen.dart';
import 'archive_view_model.dart';
import '../../domain/models/assignment_model.dart';

class ArchiveScreen extends StatelessWidget {
  final ArchiveViewModel viewModel;

  const ArchiveScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Arsip', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800))),
                    if (!viewModel.isEmpty) const LogoCircleButton(),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(child: _body(context)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (viewModel.isLoading && viewModel.isEmpty) return const ShimmerLoading();
    if (viewModel.error != null) {
      return EmptyState(icon: Icons.error_outline, message: viewModel.error!, actionLabel: 'Coba Lagi', onAction: viewModel.load);
    }
    if (viewModel.isEmpty) {
      return const EmptyState(image: 'assets/images/empty_archive.png', message: 'Belum ada penugasan yang diarsipkan.');
    }
    final groups = viewModel.grouped;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SearchField(hint: 'Search', onChanged: viewModel.setQuery),
        const SizedBox(height: 12),
        PillFilterRow(options: viewModel.filterOptions, selected: viewModel.filter, onSelected: viewModel.setFilter),
        if (groups.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: EmptyState(icon: Icons.search_off, message: 'Tidak ada arsip yang cocok.'),
          ),
        for (final entry in groups.entries) ...[
          SectionTitle(entry.key),
          for (final a in entry.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ArchiveCard(archive: a, tinted: a == viewModel.filtered.first),
            ),
        ],
      ],
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  final ArchiveModel archive;
  final bool tinted;

  const _ArchiveCard({required this.archive, required this.tinted});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () => pushSlideUp<void>(context, ArchiveDetailScreen(archiveId: archive.id)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tinted ? const Color(0xFFEDDDCD) : AppColors.cream,
          border: Border.all(color: AppColors.beige),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(archive.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Semester ${archive.semester} - Selesai  •  ${archive.mode.label}'),
            Text('Tanggal Arsip: ${formatDate(archive.archivedAt)}'),
          ],
        ),
      ),
    );
  }
}
