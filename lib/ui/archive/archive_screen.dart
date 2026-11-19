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
    return _ArchiveList(viewModel: viewModel);
  }
}

/// Daftar arsip dengan tarik-untuk-memuat-ulang dan infinite scroll.
class _ArchiveList extends StatefulWidget {
  final ArchiveViewModel viewModel;

  const _ArchiveList({required this.viewModel});

  @override
  State<_ArchiveList> createState() => _ArchiveListState();
}

class _ArchiveListState extends State<_ArchiveList> {
  final ScrollController _scroll = ScrollController();

  ArchiveViewModel get vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) vm.loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = vm.grouped;
    var index = 0;
    return RefreshIndicator(
      color: AppColors.mocca,
      onRefresh: vm.refresh,
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SearchField(hint: 'Search', onChanged: vm.setQuery),
          const SizedBox(height: 12),
          PillFilterRow(options: vm.filterOptions, selected: vm.filter, onSelected: vm.setFilter),
          if (groups.isEmpty)
            const SizedBox(
              height: 320,
              child: EmptyState(icon: Icons.search_off, title: 'Tidak ada hasil', message: 'Tidak ada arsip yang cocok.'),
            ),
          for (final entry in groups.entries) ...[
            SectionTitle(entry.key),
            for (final a in entry.value)
              AnimatedAppear(
                index: index++,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ArchiveCard(archive: a, tinted: a == vm.filtered.first),
                ),
              ),
          ],
          if (vm.isLoadingMore)
            const SizedBox(height: 104, child: SkeletonList(count: 1, padding: EdgeInsets.zero))
          else if (!vm.hasMore && vm.filtered.length > ArchiveViewModel.pageSize)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: Text('Semua arsip sudah ditampilkan', style: TextStyle(fontSize: 12, color: AppColors.textMuted))),
            ),
        ],
      ),
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
      onTap: () => pushSlideUp<void>(context, ArchiveDetailScreen(archiveId: archive.id, heroTag: 'archive-${archive.id}')),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tinted ? const Color(0xFFEDDDCD) : AppColors.cream,
          border: Border.all(color: AppColors.beige),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
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
            const SizedBox(width: 10),
            ModeBadge(icon: Icons.inventory_2_outlined, size: 42, heroTag: 'archive-${archive.id}'),
          ],
        ),
      ),
    );
  }
}
