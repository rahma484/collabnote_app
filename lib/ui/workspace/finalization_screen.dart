import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/assignment_model.dart';
import '../core/app_colors.dart';
import '../core/app_widgets.dart';
import '../shell/navigation_controller.dart';
import 'workspace_view_model.dart';

/// Halaman Finalisasi: pemeriksaan kelengkapan, ringkasan hasil, lalu selesaikan dan arsipkan.
class FinalizationScreen extends StatefulWidget {
  final WorkspaceViewModel viewModel;

  const FinalizationScreen({super.key, required this.viewModel});

  @override
  State<FinalizationScreen> createState() => _FinalizationScreenState();
}

class _FinalizationScreenState extends State<FinalizationScreen> {
  late final TextEditingController _summary;
  bool _busy = false;

  WorkspaceViewModel get vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _summary = TextEditingController(text: vm.savedSummary);
  }

  @override
  void dispose() {
    _summary.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool archive}) async {
    final nav = context.read<NavigationController>();
    final ok = await showConfirmDialog(
      context,
      title: archive ? 'Selesaikan & Arsipkan?' : 'Tandai Selesai?',
      message: archive
          ? 'Penugasan akan dipindahkan ke Arsip. Dokumen dan referensi tetap tersimpan.'
          : 'Penugasan ditandai selesai dan tetap ada di daftar Penugasan sampai Anda mengarsipkannya.',
      confirmLabel: archive ? 'Arsipkan' : 'Tandai Selesai',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    await vm.finalize(summary: _summary.text, archive: archive);
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    nav.goTo(archive ? 3 : 1);
    showSnack(context, archive ? 'Penugasan diselesaikan dan masuk Arsip.' : 'Penugasan ditandai selesai.');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final a = vm.assignment;
        if (a == null || !vm.hasWorkspace) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final checks = vm.finalChecks;
        final finals = vm.finalDocuments;
        final alreadyDone = a.status == AssignmentStatus.selesai;
        return Scaffold(
          appBar: AppBar(
            title: Text(vm.isGroup ? 'Finalisasi Kelompok: ${a.title}' : 'Finalisasi: ${a.title}', maxLines: 2, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
            toolbarHeight: 72,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              for (final c in checks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.ok ? AppColors.beige : Colors.transparent,
                          border: Border.all(color: c.ok ? AppColors.beige : AppColors.mocca, width: 2),
                        ),
                        child: Icon(c.ok ? Icons.check : (c.required ? Icons.close : Icons.remove), size: 18, color: c.ok ? AppColors.moccaDark : AppColors.mocca),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Text(c.label, style: const TextStyle(fontSize: 17.5))),
                      Text(c.detail, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vm.isGroup ? 'Dokumen Akhir Kelompok' : 'Dokumen Hasil Akhir', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(finals.isEmpty ? 'Belum ada dokumen final. Tandai dokumen sebagai final di menu Dokumen.' : finals.map((d) => d.fileName).join('\n')),
                    const SizedBox(height: 14),
                    const Text('Total Referensi', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${vm.references.length}'),
                    if (vm.isGroup) ...[
                      const SizedBox(height: 14),
                      const Text('Anggota Kelompok', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(vm.members.map((m) => m.name).join(', ')),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Ringkasan Hasil Pekerjaan',
                controller: _summary,
                maxLines: 4,
                hint: vm.suggestedSummary,
              ),
              if (!vm.canFinalize)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Lengkapi semua butir wajib di atas agar penugasan dapat diselesaikan.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.danger),
                  ),
                ),
              PrimaryButton(
                label: alreadyDone ? 'Arsipkan Penugasan' : 'Selesaikan & Arsipkan Penugasan',
                onPressed: (!vm.canFinalize || _busy) ? null : () => _finish(archive: true),
              ),
              if (!alreadyDone)
                TextButton(
                  onPressed: (!vm.canFinalize || _busy) ? null : () => _finish(archive: false),
                  child: const Text('Tandai Selesai Saja (belum diarsipkan)'),
                ),
            ],
          ),
        );
      },
    );
  }
}
