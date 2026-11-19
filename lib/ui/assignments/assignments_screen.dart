import 'package:flutter/material.dart';

import '../../data/repositories/assignment_repository.dart';
import '../../domain/models/assignment_model.dart';
import '../core/app_colors.dart';
import '../core/app_widgets.dart';
import '../core/formatters.dart';
import 'assignment_detail_screen.dart';
import 'assignment_form_screen.dart';
import 'assignments_view_model.dart';

class AssignmentsScreen extends StatelessWidget {
  final AssignmentsViewModel viewModel;

  const AssignmentsScreen({super.key, required this.viewModel});

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(viewModel: viewModel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => startCreateAssignment(context),
        child: const Icon(Icons.add, size: 28),
      ),
      body: SafeArea(
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
                      const Expanded(child: Text('Penugasan', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800))),
                      const LogoCircleButton(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SearchField(
                    hint: 'Search',
                    onChanged: viewModel.setQuery,
                    trailing: IconButton(
                      tooltip: 'Filter',
                      onPressed: () => _openFilterSheet(context),
                      icon: Icon(
                        Icons.tune,
                        color: viewModel.hasAdvancedFilter ? AppColors.moccaDark : AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<AssignmentSegment>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: AssignmentSegment.semua, label: Text('Semua')),
                        ButtonSegment(value: AssignmentSegment.individu, label: Text('Individu')),
                        ButtonSegment(value: AssignmentSegment.kelompok, label: Text('Kelompok')),
                        ButtonSegment(value: AssignmentSegment.mendesak, label: Text('Mendesak')),
                      ],
                      selected: {viewModel.segment},
                      onSelectionChanged: (s) => viewModel.setSegment(s.first),
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 4)),
                        textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        side: WidgetStateProperty.all(BorderSide.none),
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (s) => s.contains(WidgetState.selected) ? AppColors.mocca : AppColors.chip,
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith(
                          (s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.brown,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: _buildList(context)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    if (viewModel.isLoading && !viewModel.hasAnyAssignment) {
      return const ShimmerLoading();
    }
    if (viewModel.error != null) {
      return EmptyState(icon: Icons.error_outline, message: viewModel.error!, actionLabel: 'Coba Lagi', onAction: viewModel.load);
    }
    if (!viewModel.hasAnyAssignment) {
      return EmptyState(
        image: 'assets/images/empty_assignments.png',
        message: 'Belum ada penugasan. Catat tugas pertama Anda.',
        actionLabel: 'Buat Penugasan Baru',
        onAction: () => startCreateAssignment(context),
      );
    }
    final list = viewModel.filtered;
    if (list.isEmpty) {
      return const EmptyState(icon: Icons.search_off, message: 'Tidak ada penugasan yang cocok dengan pencarian atau filter.');
    }

    final repo = viewModel.assignments;
    final children = <Widget>[];
    if (viewModel.groupByCourse) {
      final byCourse = <String, List<AssignmentModel>>{};
      for (final a in list) {
        byCourse.putIfAbsent(repo.courseName(a), () => []).add(a);
      }
      final names = byCourse.keys.toList()..sort();
      for (final name in names) {
        children.add(SectionTitle(name));
        for (final a in byCourse[name]!) {
          children.add(_card(context, repo, a));
        }
      }
    } else {
      for (final a in list) {
        children.add(_card(context, repo, a));
      }
    }
    return ListView(padding: const EdgeInsets.only(bottom: 90), children: children);
  }

  Widget _card(BuildContext context, AssignmentRepository repo, AssignmentModel a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AssignmentCard(
        assignment: a,
        repo: repo,
        onTap: () => openAssignmentDetail(context, a.id),
      ),
    );
  }
}

/// Kartu penugasan. Warna mengikuti status: Belum Dimulai (mocca), Sedang (krem), Menunggu (kuning), Selesai (mint).
class AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final AssignmentRepository repo;
  final VoidCallback onTap;

  const AssignmentCard({super.key, required this.assignment, required this.repo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final overdue = repo.isOverdue(assignment);
    final status = assignment.status;
    final dark = status == AssignmentStatus.belumDimulai && !overdue;
    final onMint = status.isFinal;

    Color bg;
    if (dark) {
      bg = AppColors.mocca;
    } else if (onMint) {
      bg = const Color(0xFFC6E3DD);
    } else if (status == AssignmentStatus.menungguPemeriksaan) {
      bg = const Color(0xFFF3E7C4);
    } else {
      bg = AppColors.card;
    }
    final fg = dark ? Colors.white : AppColors.brown;

    return PressableScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${assignment.title} (${repo.courseName(assignment)})',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              status.isFinal ? 'Selesai: ${formatDate(assignment.completedAt ?? assignment.updatedAt)}' : 'Deadline: ${deadlineText(repo.daysLeft(assignment))}',
              style: TextStyle(color: fg, fontSize: 13.5),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Pill(label: assignment.mode.label, background: dark ? AppColors.brown : AppColors.mocca, foreground: Colors.white),
                const Spacer(),
                if (dark)
                  const Pill(label: 'Belum Dimulai', background: AppColors.brown, foreground: Colors.white)
                else
                  StatusPill(status: status, overdue: overdue, onMint: onMint),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  final AssignmentsViewModel viewModel;

  const _FilterSheet({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter Penugasan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              const Text('Mata Kuliah', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String?>(
                initialValue: viewModel.courseFilter,
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Semua mata kuliah')),
                  for (final c in viewModel.courseOptions) DropdownMenuItem<String?>(value: c, child: Text(c)),
                ],
                onChanged: viewModel.setCourse,
              ),
              const SizedBox(height: 12),
              const Text('Semester', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int?>(
                initialValue: viewModel.semesterFilter,
                isExpanded: true,
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Semua semester')),
                  for (final s in viewModel.semesterOptions) DropdownMenuItem<int?>(value: s, child: Text('Semester $s')),
                ],
                onChanged: viewModel.setSemester,
              ),
              const SizedBox(height: 12),
              const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: viewModel.statusFilter,
                isExpanded: true,
                items: [for (final s in AssignmentsViewModel.statusOptions) DropdownMenuItem<String>(value: s, child: Text(s))],
                onChanged: (v) => viewModel.setStatus(v ?? 'Semua'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Kelompokkan per mata kuliah'),
                value: viewModel.groupByCourse,
                onChanged: viewModel.setGroupByCourse,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brown,
                        side: const BorderSide(color: AppColors.mocca),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: viewModel.resetAdvancedFilter,
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: PrimaryButton(label: 'Terapkan', onPressed: () => Navigator.pop(context))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
