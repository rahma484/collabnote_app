import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/group_member_model.dart';
import '../core/app_colors.dart';
import '../core/app_widgets.dart';
import 'workspace_view_model.dart';

/// Manajemen anggota: kode undangan, daftar anggota, peran, status, dan penghapusan (khusus pemilik).
/// Catatan: aktivitas anggota disimulasikan lokal (belum ada server).
void showMembersSheet(BuildContext context, WorkspaceViewModel vm) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _MembersSheet(viewModel: vm),
  );
}

class _MembersSheet extends StatelessWidget {
  final WorkspaceViewModel viewModel;

  const _MembersSheet({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final group = viewModel.group;
        if (group == null) return const SizedBox(height: 160, child: Center(child: Text('Kelompok tidak tersedia.')));
        final members = viewModel.members;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      Expanded(child: Text('Kode Undangan: ${group.inviteCode}', style: const TextStyle(fontWeight: FontWeight.w600))),
                      InviteCopyButton(code: group.inviteCode),
                    ],
                  ),
                ),
                const SectionTitle('Daftar Anggota'),
                for (final m in members)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          MemberAvatar(name: m.name, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.isMe ? '${m.name} (Anda)' : m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                Row(
                                  children: [
                                    if (m.isOwner) const Icon(Icons.workspace_premium, size: 15, color: AppColors.mocca),
                                    if (m.isOwner) const SizedBox(width: 3),
                                    Text('${m.role.label}  •  ${m.status.label}', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (viewModel.isOwner && m.status == MemberStatus.diundang)
                            TextButton(onPressed: () => viewModel.confirmMember(m.id), child: const Text('Konfirmasi')),
                          if (viewModel.isOwner && !m.isOwner)
                            IconButton(
                              tooltip: 'Hapus anggota',
                              icon: const Icon(Icons.person_remove_outlined, color: AppColors.danger),
                              onPressed: () async {
                                final ok = await showConfirmDialog(
                                  context,
                                  title: 'Hapus Anggota?',
                                  message: 'Pekerjaan ${m.name} akan dialihkan ke Pemilik Kelompok.',
                                );
                                if (ok) await viewModel.removeMember(m.id);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Undang Anggota (Simulasi)',
                  icon: Icons.person_add_alt_1_outlined,
                  onPressed: () async {
                    final name = await showTextInputDialog(
                      context,
                      title: 'Undang Anggota',
                      hint: 'Nama anggota yang bergabung dengan kode ${group.inviteCode}',
                      confirmLabel: 'Undang',
                    );
                    if (name != null) await viewModel.inviteMember(name);
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Undangan disimulasikan secara lokal. Sinkronisasi antarperangkat tersedia setelah backend diterapkan.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Tombol salin dengan umpan balik visual setelah kode berhasil disalin.
class InviteCopyButton extends StatefulWidget {
  final String code;
  const InviteCopyButton({super.key, required this.code});
  @override
  State<InviteCopyButton> createState() => _InviteCopyButtonState();
}

class _InviteCopyButtonState extends State<InviteCopyButton> {
  bool copied = false;
  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => copied = true);
    showSnack(context, 'Kode undangan berhasil disalin.');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => copied = false);
    });
  }
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: copied ? 'Tersalin' : 'Salin kode',
    onPressed: _copy,
    icon: AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Icon(copied ? Icons.check_circle_rounded : Icons.copy_outlined,
        key: ValueKey(copied), color: copied ? AppColors.mintText : AppColors.brown),
    ),
  );
}
