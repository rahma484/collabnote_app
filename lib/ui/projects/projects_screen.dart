import 'package:flutter/material.dart';

import 'projects_view_model.dart';

class ProjectsScreen extends StatelessWidget {
  final ProjectsViewModel viewModel;

  const ProjectsScreen({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Proyek',
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

          if (viewModel.error != null) {
            return Center(
              child: Text('Gagal memuat proyek: ${viewModel.error}'),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text(
                  'Pilih kategori proyek',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<String>(
                  segments: ProjectsViewModel.categories.map((category) {
                    return ButtonSegment<String>(
                      value: category,
                      label: Text(category),
                    );
                  }).toList(),
                  selected: {viewModel.selectedCategory},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) {
                    viewModel.selectCategory(selection.first);
                  },
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: viewModel.projects.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada proyek pada kategori ini.',
                          style: TextStyle(color: Color(0xFF85899A)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: viewModel.projects.length,
                        itemBuilder: (context, index) {
                          final project = viewModel.projects[index];

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                color: Color(0xFFE8E8F0),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFEFEDFF),
                                child: Icon(
                                  Icons.folder_open,
                                  color: Color(0xFF635BDB),
                                ),
                              ),
                              title: Text(
                                project.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(project.category),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tipe: ${project.projectType}',
                                    ),
                                    if (project.deadline != null)
                                      Text(
                                        'Deadline: ${project.deadline!.day}/${project.deadline!.month}/${project.deadline!.year}',
                                      ),
                                  ],
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF85899A),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}