import 'package:flutter/material.dart';

import '../../data/repositories/assignment_repository.dart';
import '../../domain/models/assignment_model.dart';
import '../assignments/assignment_detail_screen.dart';
import '../assignments/assignment_form_screen.dart';
import '../core/app_colors.dart';
import '../core/app_widgets.dart';
import '../core/formatters.dart';
import 'home_view_model.dart';

class HomeScreen extends StatelessWidget {
  final HomeViewModel viewModel;
  final void Function(String assignmentId) onOpenWorkspace;

  const HomeScreen({super.key, required this.viewModel, required this.onOpenWorkspace});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          if (viewModel.isLoading && viewModel.total == 0) {
            return const ShimmerLoading();
          }
          if (viewModel.error != null) {
            return EmptyState(
              icon: Icons.error_outline,
              message: viewModel.error!,
              actionLabel: 'Coba Lagi',
              onAction: viewModel.load,
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Beranda', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800))),
                  const LogoCircleButton(),
                ],
              ),
              const SizedBox(height: 18),
              Text('Halo, ${viewModel.userFirstName}!', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(formatLongDate(DateTime.now()), style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 14),
              _SummaryGrid(viewModel: viewModel),
              if (viewModel.overdue > 0) ...[
                const SizedBox(height: 12),
                _Banner(
                  icon: Icons.warning_amber_rounded,
                  text: '${viewModel.overdue} tugas terlambat',
                  background: AppColors.dangerSoft,
                  foreground: AppColors.danger,
                ),
              ],
              if (viewModel.isEmpty) _buildEmpty(context) else ..._buildPopulated(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 28),
        Image.asset('assets/images/empty_assignments.png', height: 190),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Buat Penugasan Baru',
          color: AppColors.brown,
          onPressed: () => startCreateAssignment(context),
        ),
      ],
    );
  }

  List<Widget> _buildPopulated(BuildContext context) {
    final repo = viewModel.assignments;
    final upcoming = viewModel.upcoming;
    final recent = viewModel.recent;
    final actions = viewModel.actions;
    final reminders = viewModel.reminders;

    return [
      if (reminders.isNotEmpty) ...[
        const SizedBox(height: 12),
        _Banner(
          icon: Icons.notifications_active_outlined,
          text: 'Pengingat: ${reminders.first.title} - ${deadlineText(repo.daysLeft(reminders.first))}',
          background: AppColors.yellow,
          foreground: AppColors.brown,
        ),
      ],
      if (upcoming.isNotEmpty) ...[
        const SectionTitle('Upcoming Deadlines'),
        for (var i = 0; i < upcoming.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DeadlineCard(
              assignment: upcoming[i],
              repo: repo,
              highlighted: i == 0,
              onTap: () => openAssignmentDetail(context, upcoming[i].id),
            ),
          ),
      ],
      if (actions.isNotEmpty) ...[
        const SectionTitle('Perlu Segera Dikerjakan'),
        for (final action in actions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ActionRow(action: action, onTap: () => onOpenWorkspace(action.assignmentId)),
          ),
      ],
      if (recent.isNotEmpty) ...[
        const SectionTitle('Recent Assignments'),
        for (final a in recent)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RecentCard(
              assignment: a,
              repo: repo,
              onTap: () => openAssignmentDetail(context, a.id),
            ),
          ),
      ],
      const SizedBox(height: 14),
      PrimaryButton(
        label: 'Buat Penugasan Baru',
        color: AppColors.brown,
        onPressed: () => startCreateAssignment(context),
      ),
    ];
  }
}

class _SummaryGrid extends StatelessWidget {
  final HomeViewModel viewModel;
  const _SummaryGrid({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    Widget tile(String label, int value, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 2),
                Text('$value', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        );

    return Column(
      children: [
        Row(children: [
          tile('Total Penugasan', viewModel.total, AppColors.tileTotal),
          const SizedBox(width: 10),
          tile('Belum Dimulai', viewModel.notStarted, AppColors.tileNotStarted),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          tile('Sedang Dikerjakan', viewModel.inProgress, AppColors.tileProgress),
          const SizedBox(width: 10),
          tile('Selesai', viewModel.completed, AppColors.tileDone),
        ]),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;

  const _Banner({required this.icon, required this.text, required this.background, required this.foreground});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: foreground, fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}

class _DeadlineCard extends StatelessWidget {
  final AssignmentModel assignment;
  final AssignmentRepository repo;
  final bool highlighted;
  final VoidCallback onTap;

  const _DeadlineCard({required this.assignment, required this.repo, required this.highlighted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = highlighted ? Colors.white : AppColors.brown;
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: highlighted ? AppColors.mocca : AppColors.card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${assignment.title} (${repo.courseName(assignment)})',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Deadline: ${deadlineText(repo.daysLeft(assignment))}',
              style: TextStyle(color: fg, fontSize: 13.5),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 90,
              child: ProgressBarSoft(
                value: repo.progressOf(assignment),
                color: highlighted ? Colors.white : AppColors.mocca,
                track: highlighted ? Colors.white30 : AppColors.beige,
                height: 7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final AssignmentRepository repo;
  final VoidCallback onTap;

  const _RecentCard({required this.assignment, required this.repo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${assignment.title} (${repo.courseName(assignment)})',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Pill(label: assignment.mode.label, background: AppColors.mocca, foreground: Colors.white),
                const Spacer(),
                StatusPill(status: assignment.status, overdue: repo.isOverdue(assignment)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final PendingAction action;
  final VoidCallback onTap;

  const _ActionRow({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final days = daysUntilText(action.deadline);
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(action.isGroupWork ? Icons.groups_outlined : Icons.check_box_outline_blank, color: AppColors.mocca),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(action.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(action.assignmentTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            Text(days, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
