import 'package:flutter/material.dart';

import '../../domain/models/project.dart';
import '../../domain/models/task.dart';
import '../core/app_colors.dart';
import 'home_view_model.dart';

class HomeScreen extends StatelessWidget {
  final HomeViewModel viewModel;
  final VoidCallback onCreateProject;
  final void Function(Project project) onOpenProject;
  final VoidCallback onOpenProfile;

  const HomeScreen({
    super.key,
    required this.viewModel,
    required this.onCreateProject,
    required this.onOpenProject,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CollabNote',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: viewModel.load,
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: onOpenProfile,
            tooltip: 'Profil',
            icon: const Icon(Icons.account_circle_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: onCreateProject,
        tooltip: 'Proyek baru',
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          if (viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (viewModel.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal memuat data: ${viewModel.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final projects = viewModel.filteredProjects;

          return RefreshIndicator(
            onRefresh: viewModel.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
              children: [
                const Text(
                  'Workspace kamu',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Atur ide, proyek, dan progres pekerjaanmu.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),

                _buildSummaryCard(
                  title: 'Total Proyek',
                  value: '${viewModel.projects.length}',
                  icon: Icons.folder_copy_outlined,
                ),
                const SizedBox(height: 12),

                _buildSummaryCard(
                  title: 'Tugas Belum Selesai',
                  value: '${viewModel.incompleteTasks.length}',
                  icon: Icons.pending_actions_outlined,
                ),
                const SizedBox(height: 28),

                _buildSectionTitle('Proyek Aktif'),
                const SizedBox(height: 12),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: HomeViewModel.categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: viewModel.selectedCategory == category,
                          onSelected: (_) {
                            viewModel.selectCategory(category);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                if (projects.isEmpty)
                  _buildEmptyMessage(
                    viewModel.projects.isEmpty
                        ? 'Belum ada proyek. Tekan + untuk membuat proyek pertamamu.'
                        : 'Belum ada proyek pada kategori ini.',
                  )
                else
                  ...projects.map(_buildProjectCard),

                const SizedBox(height: 28),

                _buildSectionTitle('Tugas yang Perlu Dikerjakan'),
                const SizedBox(height: 12),

                if (viewModel.incompleteTasks.isEmpty)
                  _buildEmptyMessage(
                    'Tidak ada tugas yang perlu diselesaikan.',
                  )
                else
                  ...viewModel.incompleteTasks.take(5).map(
                        (task) => _buildTaskCard(task),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      color: AppColors.primarySoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppColors.primary,
          size: 30,
        ),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textMuted),
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    final total = viewModel.totalTasksFor(project.id);
    final done = viewModel.completedTasksFor(project.id);
    final isGroup = project.projectType == 'Group';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onOpenProject(project),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(
                      Icons.folder_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${project.category} • ${isGroup ? 'Kelompok' : 'Mandiri'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: viewModel.progressFor(project.id),
                  minHeight: 6,
                  backgroundColor: AppColors.primarySoft,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                total == 0
                    ? 'Belum ada tugas'
                    : '$done dari $total tugas selesai',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(
          Icons.radio_button_unchecked,
          color: AppColors.primary,
        ),
        title: Text(task.title),
        subtitle: Text('Status: ${task.status}'),
      ),
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textMuted),
        textAlign: TextAlign.center,
      ),
    );
  }
}
