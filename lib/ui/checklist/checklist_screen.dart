import 'package:flutter/material.dart';

import '../../domain/models/task.dart';
import 'checklist_view_model.dart';

class ChecklistScreen extends StatelessWidget {
  final ChecklistViewModel viewModel;

  const ChecklistScreen({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checklist Tugas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: viewModel.load,
            icon: const Icon(Icons.refresh),
          ),
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

          if (viewModel.error != null &&
              viewModel.incompleteTasks.isEmpty &&
              viewModel.completedTasks.isEmpty) {
            return Center(
              child: Text('Gagal memuat tugas: ${viewModel.error}'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionTitle(
                'Belum Selesai',
                viewModel.incompleteTasks.length,
              ),

              const SizedBox(height: 10),

              if (viewModel.incompleteTasks.isEmpty)
                _buildEmptyMessage('Tidak ada tugas yang belum selesai.')
              else
                ...viewModel.incompleteTasks.map(
                  (task) => _buildTaskTile(
                    context,
                    task,
                    false,
                  ),
                ),

              const SizedBox(height: 28),

              _buildSectionTitle(
                'Selesai',
                viewModel.completedTasks.length,
              ),

              const SizedBox(height: 10),

              if (viewModel.completedTasks.isEmpty)
                _buildEmptyMessage('Belum ada tugas yang diselesaikan.')
              else
                ...viewModel.completedTasks.map(
                  (task) => _buildTaskTile(
                    context,
                    task,
                    true,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF20243A),
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 12,
          backgroundColor: const Color(0xFFEFEDFF),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF635BDB),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskTile(
    BuildContext context,
    Task task,
    bool isCompleted,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE8E8F0)),
      ),
      child: CheckboxListTile(
        value: isCompleted,
        activeColor: const Color(0xFF635BDB),
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          task.title,
          style: TextStyle(
            decoration: isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: isCompleted
                ? const Color(0xFF85899A)
                : const Color(0xFF20243A),
          ),
        ),
        subtitle: Text(
          task.assignee == null || task.assignee!.isEmpty
              ? 'Belum ada penanggung jawab'
              : 'Penanggung jawab: ${task.assignee}',
        ),
        onChanged: (value) async {
          if (value == null) return;

          final success = await viewModel.toggle(task, value);

          if (!context.mounted) return;

          if (!success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal menyimpan perubahan tugas.'),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF85899A)),
      ),
    );
  }
}