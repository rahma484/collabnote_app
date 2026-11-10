import 'package:flutter/material.dart';

import '../../domain/models/project_template.dart';
import '../core/app_colors.dart';
import 'projects_view_model.dart';

class CreateProjectScreen extends StatefulWidget {
  final ProjectsViewModel viewModel;

  const CreateProjectScreen({
    super.key,
    required this.viewModel,
  });

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = ProjectTemplate.all.first.category;
  String _projectType = 'Individual';
  DateTime? _deadline;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  IconData _templateIcon(String category) {
    switch (category) {
      case ProjectTemplate.software:
        return Icons.code;
      case ProjectTemplate.business:
        return Icons.rocket_launch_outlined;
      case ProjectTemplate.academic:
        return Icons.menu_book_outlined;
      case ProjectTemplate.creative:
        return Icons.palette_outlined;
      default:
        return Icons.sticky_note_2_outlined;
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final description = _descriptionController.text.trim();

    final success = await widget.viewModel.createProject(
      title: _titleController.text.trim(),
      description: description.isEmpty ? null : description,
      category: _category,
      projectType: _projectType,
      deadline: _deadline,
    );

    if (!mounted) return;

    if (success) {
      // Kembali ke Beranda; AppShell memuat ulang data sehingga
      // proyek baru langsung muncul.
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan proyek: ${widget.viewModel.saveError}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final template = ProjectTemplate.byCategory(_category);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Proyek Baru',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Judul Proyek',
                hintText: 'Contoh: Aplikasi E-Commerce UMKM',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Judul proyek wajib diisi.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Deskripsi Singkat',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pilih Template',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ...ProjectTemplate.all.map(_buildTemplateCard),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tugas yang dibuat otomatis',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...template.defaultTasks.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(task)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tipe Proyek',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'Individual',
                  label: Text('Mandiri'),
                  icon: Icon(Icons.person_outline),
                ),
                ButtonSegment<String>(
                  value: 'Group',
                  label: Text('Kelompok'),
                  icon: Icon(Icons.groups_outlined),
                ),
              ],
              selected: {_projectType},
              onSelectionChanged: (selection) {
                setState(() {
                  _projectType = selection.first;
                });
              },
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.event_outlined,
                color: AppColors.primary,
              ),
              title: Text(
                _deadline == null
                    ? 'Deadline (opsional)'
                    : 'Deadline: ${_formatDate(_deadline!)}',
              ),
              trailing: _deadline == null
                  ? const Icon(Icons.chevron_right)
                  : IconButton(
                      onPressed: () {
                        setState(() {
                          _deadline = null;
                        });
                      },
                      icon: const Icon(Icons.close),
                    ),
              onTap: _pickDeadline,
            ),
            const SizedBox(height: 20),
            ListenableBuilder(
              listenable: widget.viewModel,
              builder: (context, child) {
                return FilledButton(
                  onPressed: widget.viewModel.isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: widget.viewModel.isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Simpan Proyek'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(ProjectTemplate template) {
    final selected = template.category == _category;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: selected ? AppColors.primarySoft : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            _category = template.category;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    selected ? Colors.white : AppColors.primarySoft,
                child: Icon(
                  _templateIcon(template.category),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.category,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      template.summary,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
