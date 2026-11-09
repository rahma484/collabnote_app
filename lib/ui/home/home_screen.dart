import 'package:flutter/material.dart';

import '../../domain/models/project.dart';
import '../../domain/models/task.dart';
import 'home_view_model.dart';

class HomeScreen extends StatelessWidget {
  final HomeViewModel viewModel;

  const HomeScreen({
    super.key,
    required this.viewModel,
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
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
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
              child: Text('Gagal memuat data: ${viewModel.error}'),
            );
          }

          return RefreshIndicator(
            onRefresh: viewModel.load,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Workspace kamu',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF20243A),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Atur ide, proyek, dan progres pekerjaanmu.',
                  style: TextStyle(color: Color(0xFF85899A)),
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

                _buildSectionTitle('Proyek Terbaru'),
                const SizedBox(height: 12),

                if (viewModel.projects.isEmpty)
                  _buildEmptyMessage(
                    'Belum ada proyek. Mulai buat proyek pertamamu.',
                  )
                else
                  ...viewModel.projects.take(5).map(
                        (project) => _buildProjectCard(project),
                      ),

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
      color: const Color(0xFFEFEDFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF635BDB),
          size: 30,
        ),
        title: Text(
          title,
          style: const TextStyle(color: Color(0xFF85899A)),
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF635BDB),
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
        color: Color(0xFF20243A),
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE8E8F0)),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEFEDFF),
          child: Icon(
            Icons.folder_outlined,
            color: Color(0xFF635BDB),
          ),
        ),
        title: Text(
          project.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(project.category),
        trailing: const Icon(Icons.chevron_right),
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
          color: Color(0xFF635BDB),
        ),
        title: Text(task.title),
        subtitle: Text('Status: ${task.status}'),
      ),
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF85899A)),
        textAlign: TextAlign.center,
      ),
    );
  }
}