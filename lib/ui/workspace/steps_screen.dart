import 'package:flutter/material.dart';

import '../../domain/models/task_step_model.dart';
import '../core/app_colors.dart';
import '../core/app_widgets.dart';
import 'workspace_view_model.dart';

Future<void> promptAddStep(BuildContext context, WorkspaceViewModel vm) async {
  final text = await showTextInputDialog(context, title: 'Tambah Tahapan', hint: 'Contoh: Menyusun draft');
  if (text != null) await vm.addStep(text);
}

/// Task Checklist (mode individu): tahapan pengerjaan. Yang dicentang pindah ke bagian Selesai.
class StepsScreen extends StatelessWidget {
  final WorkspaceViewModel viewModel;

  const StepsScreen({super.key, required this.viewModel});

  Future<void> _edit(BuildContext context, TaskStepModel step) async {
    final text = await showTextInputDialog(context, title: 'Edit Tahapan', initial: step.title);
    if (text != null) await viewModel.renameStep(step.id, text);
  }

  Future<void> _delete(BuildContext context, TaskStepModel step) async {
    final ok = await showConfirmDialog(context, title: 'Hapus Tahapan?', message: '"${step.title}" akan dihapus dari checklist.');
    if (ok) await viewModel.deleteStep(step.id);
  }

  Widget _menu(BuildContext context, TaskStepModel step) => PopupMenuButton<String>(
        color: AppColors.cream,
        onSelected: (v) => v == 'edit' ? _edit(context, step) : _delete(context, step),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'delete', child: Text('Hapus')),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (!viewModel.hasWorkspace) return const Scaffold(body: Center(child: Text('Ruang kerja tidak tersedia.')));
        final pending = viewModel.pendingSteps;
        final done = viewModel.doneSteps;
        return Scaffold(
          appBar: AppBar(title: const Text('Task Checklist')),
          floatingActionButton: FloatingActionButton(
            onPressed: () => promptAddStep(context, viewModel),
            child: const Icon(Icons.add, size: 28),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
            children: [
              Text('${viewModel.stepsDone} dari ${viewModel.stepsTotal} tahapan selesai', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ProgressBarSoft(value: viewModel.stepsTotal == 0 ? 0 : viewModel.stepsDone / viewModel.stepsTotal, height: 10),
              const SectionTitle('Belum Selesai'),
              if (pending.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Tidak ada tahapan yang tersisa.', style: TextStyle(color: AppColors.textMuted)),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text('Tahan dan geser untuk mengatur urutan pengerjaan.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ),
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                // ignore: deprecated_member_use
                onReorder: viewModel.reorderSteps,
                children: [
                  for (final step in pending)
                    Container(
                      key: ValueKey(step.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
                      child: CheckboxListTile(
                        value: false,
                        onChanged: (_) => viewModel.toggleStep(step.id),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(step.title),
                        secondary: _menu(context, step),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                ],
              ),
              SectionTitle('Selesai (${done.length})'),
              if (done.isEmpty)
                const Text('Centang tahapan untuk memindahkannya ke sini.', style: TextStyle(color: AppColors.textMuted)),
              for (final step in done)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: AppColors.mint.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(14)),
                  child: CheckboxListTile(
                    value: true,
                    onChanged: (_) => viewModel.toggleStep(step.id),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(step.title, style: const TextStyle(decoration: TextDecoration.lineThrough)),
                    secondary: _menu(context, step),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
