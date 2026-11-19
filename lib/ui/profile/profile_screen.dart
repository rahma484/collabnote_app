import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/local_file_service.dart';
import '../../data/services/collab_note_service.dart';
import '../auth/auth_screen.dart';

import '../core/app_colors.dart';
import '../core/app_widgets.dart';
import 'edit_profile_screen.dart';
import 'profile_view_model.dart';

class ProfileAvatar extends StatelessWidget {
  final String name;
  final String? photoPath;
  final double size;

  const ProfileAvatar({super.key, required this.name, this.photoPath, this.size = 96});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size, height: size, alignment: Alignment.center,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.mocca),
      child: Text(name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
        style: TextStyle(color: Colors.white, fontSize: size * 0.42, fontWeight: FontWeight.w700)),
    );
    if (photoPath == null || photoPath!.isEmpty) return fallback;
    return FutureBuilder<Uint8List?>(
      future: context.read<LocalFileService>().readBytes(photoPath),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return fallback;
        return ClipOval(child: Image.memory(bytes, width: size, height: size, fit: BoxFit.cover));
      },
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final ProfileViewModel viewModel;

  const ProfileScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          if (viewModel.error != null) {
            return EmptyState(icon: Icons.error_outline, message: viewModel.error!, actionLabel: 'Coba Lagi', onAction: viewModel.load);
          }
          final u = viewModel.user;
          Widget infoRow(String label, String value) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 110, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.mocca))),
                    Expanded(child: Text(value.isEmpty ? '-' : value)),
                  ],
                ),
              );
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Profil', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800))),
                  const LogoCircleButton(),
                ],
              ),
              const SizedBox(height: 20),
              Center(child: ProfileAvatar(name: u.name, photoPath: u.photoPath)),
              const SizedBox(height: 12),
              Center(child: Text(u.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
              Center(child: Text('NIM ${u.nim.isEmpty ? '-' : u.nim}')),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  children: [
                    infoRow('Universitas', u.university),
                    infoRow('Fakultas', u.faculty),
                    infoRow('Program Studi', u.studyProgram),
                    infoRow('Semester', '${u.semester}'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'Edit Profil',
                icon: Icons.edit_outlined,
                onPressed: () => pushSlideUp<void>(context, EditProfileScreen(viewModel: viewModel)),
              ),
              const SectionTitle('Pengaturan Notifikasi'),
              Container(
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                child: SwitchListTile(
                  title: const Text('Pengingat deadline di Beranda'),
                  subtitle: const Text('Tampilkan pengingat untuk tugas yang deadline-nya 2 hari lagi atau terlambat.', style: TextStyle(fontSize: 12)),
                  value: u.deadlineReminder,
                  onChanged: viewModel.setReminder,
                ),
              ),
              const SectionTitle('Pengaturan Tampilan'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ukuran teks', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<int>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: 0, label: Text('Kecil')),
                          ButtonSegment(value: 1, label: Text('Normal')),
                          ButtonSegment(value: 2, label: Text('Besar')),
                        ],
                        selected: {u.textSize},
                        onSelectionChanged: (s) => viewModel.setTextSize(s.first),
                        style: ButtonStyle(
                          side: WidgetStateProperty.all(BorderSide.none),
                          backgroundColor: WidgetStateProperty.resolveWith(
                            (s) => s.contains(WidgetState.selected) ? AppColors.mocca : AppColors.chip,
                          ),
                          foregroundColor: WidgetStateProperty.resolveWith(
                            (s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.brown,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SectionTitle('Lainnya'),
              Container(
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.group_add_outlined, color: AppColors.mocca),
                      title: const Text('Gabung dengan Kode Undangan'),
                      subtitle: const Text('Masukkan kode dari pemilik kelompok.', style: TextStyle(fontSize: 12)),
                      onTap: () async {
                        final controller = TextEditingController();
                        final code = await showDialog<String>(context: context, builder: (dialogContext) => AlertDialog(
                          title: const Text('Gabung Kelompok'),
                          content: TextField(controller: controller, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Kode undangan', hintText: 'Contoh: A7K2P')),
                          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text), child: const Text('Gabung'))],
                        ));
                        if (code == null || code.trim().isEmpty || !context.mounted) return;
                        final joined = await viewModel.joinGroup(code);
                        if (!context.mounted) return;
                        showSnack(context, joined ? 'Berhasil bergabung ke kelompok.' : 'Kode undangan tidak ditemukan.');
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info_outline, color: AppColors.mocca),
                      title: const Text('Informasi Aplikasi'),
                      onTap: () => showAboutCollabNote(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout, color: AppColors.danger),
                      title: const Text('Keluar dari Akun', style: TextStyle(color: AppColors.danger)),
                      subtitle: const Text('Akun simulasi tetap tersimpan dan bisa digunakan untuk login kembali.', style: TextStyle(fontSize: 12)),
                      onTap: () async {
                        final ok = await showConfirmDialog(context, title: 'Keluar dari akun?', message: 'Kamu dapat masuk kembali menggunakan email dan password yang sama.', confirmLabel: 'Keluar');
                        if (!ok || !context.mounted) return;
                        await context.read<CollabNoteService>().logoutAccount();
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AuthScreen()), (route) => false);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.restore, color: AppColors.danger),
                      title: const Text('Reset ke Data Contoh', style: TextStyle(color: AppColors.danger)),
                      subtitle: const Text('Mengembalikan seluruh data ke kondisi awal.', style: TextStyle(fontSize: 12)),
                      onTap: () async {
                        final ok = await showConfirmDialog(
                          context,
                          title: 'Reset Data?',
                          message: 'Semua penugasan, dokumen, dan arsip Anda akan diganti dengan data contoh.',
                          confirmLabel: 'Reset',
                        );
                        if (!ok) return;
                        await viewModel.resetSampleData();
                        if (context.mounted) showSnack(context, 'Data dikembalikan ke data contoh.');
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
