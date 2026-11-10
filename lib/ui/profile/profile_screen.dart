import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/auth_repository.dart';
import '../auth/auth_view_model.dart';
import '../core/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AuthViewModel(context.read<AuthRepository>());
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari CollabNote?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final success = await _viewModel.logout();

    if (!mounted) return;

    if (success) {
      // AuthGate sudah menampilkan halaman Login di bawah;
      // tutup semua halaman yang menumpuk di atasnya.
      navigator.popUntil((route) => route.isFirst);
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Gagal keluar. Coba lagi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          final profile = _viewModel.profile;
          final name = (profile?.fullName.isNotEmpty ?? false)
              ? profile!.fullName
              : (_viewModel.email ?? 'Pengguna');
          final program = (profile?.studyProgram.isNotEmpty ?? false)
              ? profile!.studyProgram
              : '-';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 12),
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              if (_viewModel.isLoading && profile == null)
                const Center(child: CircularProgressIndicator())
              else ...[
                _infoTile(Icons.school_outlined, 'Program Studi', program),
                _infoTile(
                  Icons.mail_outline,
                  'Email',
                  _viewModel.email ?? '-',
                ),
              ],
              if (_viewModel.error != null && profile == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Profil tambahan belum bisa dimuat.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: _viewModel.isLoading ? null : _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Keluar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
