import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/asset_link_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../domain/models/asset_link.dart';
import '../../domain/models/project.dart';
import '../../domain/models/project_template.dart';
import '../../domain/models/task.dart';
import '../assets/asset_link_widgets.dart';
import '../assets/assets_view_model.dart';
import '../core/app_colors.dart';
import 'project_detail_view_model.dart';

/// Halaman detail proyek: tab Catatan, Task Board (real-time),
/// dan Links (real-time). Mengembalikan `true` jika proyek dihapus.
class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ProjectDetailViewModel _viewModel;
  late final AssetsViewModel _assetsViewModel;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    _viewModel = ProjectDetailViewModel(
      project: widget.project,
      projectRepository: context.read<ProjectRepository>(),
      taskRepository: context.read<TaskRepository>(),
    );

    _assetsViewModel = AssetsViewModel(
      context.read<AssetLinkRepository>(),
    );

    _viewModel.load();
    _assetsViewModel.load(widget.project.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viewModel.dispose();
    _assetsViewModel.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // ------------------------------------------------------------------
  // Actions
  // ------------------------------------------------------------------

  Future<void> _deleteProject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Proyek'),
        content: Text(
          'Hapus "${widget.project.title}" beserta semua tugas dan '
          'tautannya? Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final navigator = Navigator.of(context);
    final success = await _viewModel.deleteProject();

    if (!mounted) return;

    if (success) {
      navigator.pop(true);
    } else {
      _showMessage('Gagal menghapus proyek.');
    }
  }

  Future<void> _addTask() async {
    final input = await showDialog<_TaskInput>(
      context: context,
      builder: (_) => const _AddTaskDialog(),
    );

    if (input == null || !mounted) return;

    final success = await _viewModel.addTask(
      title: input.title,
      assignee: input.assignee,
    );

    if (!mounted) return;

    if (!success) _showMessage('Gagal menambahkan tugas.');
  }

  Future<void> _moveTask(Task task, String status) async {
    final success = await _viewModel.moveTask(task, status);

    if (!mounted) return;

    if (!success) _showMessage('Gagal memindahkan tugas.');
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Tugas'),
        content: Text('Hapus "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await _viewModel.deleteTask(task);

    if (!mounted) return;

    if (!success) _showMessage('Gagal menghapus tugas.');
  }

  Future<void> _addLink() async {
    final input = await showAddAssetLinkDialog(context);

    if (input == null || !mounted) return;

    final success = await _assetsViewModel.addAssetLink(
      title: input.title,
      url: input.url,
      category: input.category,
    );

    if (!mounted) return;

    _showMessage(
      success ? 'Tautan berhasil ditambahkan.' : 'Gagal menambahkan tautan.',
    );
  }

  Future<void> _deleteLink(AssetLink asset) async {
    final confirmed = await confirmDeleteAssetLink(context, asset);

    if (!confirmed || !mounted) return;

    final success = await _assetsViewModel.removeAssetLink(asset.id);

    if (!mounted) return;

    _showMessage(
      success ? 'Tautan berhasil dihapus.' : 'Gagal menghapus tautan.',
    );
  }

  // ------------------------------------------------------------------
  // Build
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.project.title,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _deleteProject();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'delete',
                child: Text('Hapus proyek'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Catatan'),
            Tab(text: 'Task Board'),
            Tab(text: 'Links'),
          ],
        ),
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (context, child) {
          switch (_tabController.index) {
            case 1:
              return FloatingActionButton.extended(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                onPressed: _addTask,
                icon: const Icon(Icons.add),
                label: const Text('Tugas'),
              );
            case 2:
              return FloatingActionButton.extended(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                onPressed: _addLink,
                icon: const Icon(Icons.add_link),
                label: const Text('Tautan'),
              );
            default:
              return const SizedBox.shrink();
          }
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotesTab(),
          _buildBoardTab(),
          _buildLinksTab(),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Tab Catatan
  // ------------------------------------------------------------------

  Widget _buildNotesTab() {
    final project = widget.project;
    final template = ProjectTemplate.byCategory(project.category);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        final description = project.description;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progress Tugas',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _viewModel.progress,
                      minHeight: 10,
                      backgroundColor: AppColors.primarySoft,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_viewModel.completedCount} dari '
                    '${_viewModel.totalCount} tugas selesai',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (description == null || description.isEmpty)
                        ? 'Belum ada deskripsi.'
                        : description,
                    style: TextStyle(
                      color: (description == null || description.isEmpty)
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                children: [
                  _infoRow(Icons.category_outlined, 'Template', project.category),
                  _infoRow(
                    project.projectType == 'Group'
                        ? Icons.groups_outlined
                        : Icons.person_outline,
                    'Tipe',
                    project.projectType == 'Group' ? 'Kelompok' : 'Mandiri',
                  ),
                  _infoRow(
                    Icons.event_outlined,
                    'Deadline',
                    project.deadline == null
                        ? '-'
                        : _formatDate(project.deadline!),
                  ),
                  _infoRow(
                    Icons.schedule_outlined,
                    'Dibuat',
                    _formatDate(project.createdAt.toLocal()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
              color: AppColors.primarySoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Panduan Template',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.summary,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 10),
                  ...template.defaultTasks.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('${entry.key + 1}. ${entry.value}'),
                        ),
                      ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _card({required Widget child, Color color = Colors.white}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Tab Task Board
  // ------------------------------------------------------------------

  Widget _buildBoardTab() {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        if (_viewModel.isLoading && _viewModel.tasks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_viewModel.error != null && _viewModel.tasks.isEmpty) {
          return Center(
            child: Text('Gagal memuat tugas: ${_viewModel.error}'),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: constraints.maxHeight - 32,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final status in ProjectDetailViewModel.statuses)
                      _buildColumn(status),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildColumn(String status) {
    final items = _viewModel.tasksWithStatus(status);

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                status,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.white,
                child: Text(
                  '${items.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada tugas',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _buildTaskCard(items[index], status);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task, String status) {
    const statuses = ProjectDetailViewModel.statuses;
    final index = statuses.indexOf(status);
    final hasAssignee = task.assignee != null && task.assignee!.isNotEmpty;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                task.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),
            if (hasAssignee) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.assignee!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (index > 0)
                  IconButton(
                    tooltip: 'Pindah ke ${statuses[index - 1]}',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _moveTask(task, statuses[index - 1]),
                    icon: const Icon(Icons.arrow_back, size: 20),
                  ),
                if (index < statuses.length - 1)
                  IconButton(
                    tooltip: 'Pindah ke ${statuses[index + 1]}',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _moveTask(task, statuses[index + 1]),
                    icon: const Icon(Icons.arrow_forward, size: 20),
                  ),
                IconButton(
                  tooltip: 'Hapus tugas',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _deleteTask(task),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Tab Links
  // ------------------------------------------------------------------

  Widget _buildLinksTab() {
    return ListenableBuilder(
      listenable: _assetsViewModel,
      builder: (context, child) {
        if (_assetsViewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_assetsViewModel.error != null &&
            _assetsViewModel.assetLinks.isEmpty) {
          return Center(
            child: Text('Gagal memuat tautan: ${_assetsViewModel.error}'),
          );
        }

        if (_assetsViewModel.assetLinks.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada tautan untuk proyek ini.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          itemCount: _assetsViewModel.assetLinks.length,
          itemBuilder: (context, index) {
            final asset = _assetsViewModel.assetLinks[index];

            return AssetLinkCard(
              asset: asset,
              onOpen: () => openAssetLink(context, asset.url),
              onDelete: () => _deleteLink(asset),
            );
          },
        );
      },
    );
  }
}

class _TaskInput {
  final String title;
  final String? assignee;

  const _TaskInput({required this.title, this.assignee});
}

class _AddTaskDialog extends StatefulWidget {
  const _AddTaskDialog();

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _assigneeController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _assigneeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final assignee = _assigneeController.text.trim();

    Navigator.pop(
      context,
      _TaskInput(
        title: _titleController.text.trim(),
        assignee: assignee.isEmpty ? null : assignee,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Tugas'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Judul tugas',
                  hintText: 'Contoh: Desain wireframe',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul tugas wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _assigneeController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Penanggung jawab (opsional)',
                  hintText: 'Nama anggota',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
