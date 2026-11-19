import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/assignment_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/template_repository.dart';
import '../core/app_colors.dart';
import '../../data/services/collab_note_service.dart';
import '../auth/auth_screen.dart';
import '../core/app_widgets.dart';
import '../shell/app_shell.dart';

/// Splash Screen: logo, nama, tagline, dan indikator memuat. Data dimuat selagi splash tampil.
class SplashScreen extends StatefulWidget {
  /// quick = true setelah login/registrasi (tidak perlu menunggu animasi pembuka lama).
  final bool quick;

  const SplashScreen({super.key, this.quick = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    setState(() => _error = null);
    try {
      await Future.wait([
        Future.delayed(Duration(milliseconds: widget.quick ? 600 : 1800)),
        context.read<ProfileRepository>().load(force: true),
        context.read<GroupRepository>().load(force: true),
        context.read<TemplateRepository>().load(),
        context.read<AssignmentRepository>().load(),
      ]);
      if (!mounted) return;
      // Sudah ada sesi akun aktif -> langsung ke aplikasi; bila belum -> layar Masuk/Registrasi.
      final loggedIn = await context.read<CollabNoteService>().hasActiveAccount();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        fadeScaleRoute<void>(loggedIn ? const AppShell() : const AuthScreen()),
      );
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal memuat data. Coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOut,
          builder: (context, value, child) => Opacity(opacity: value, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(tag: 'app-logo', child: Image.asset('assets/images/logo_collabnote.png', height: 150)),
              const SizedBox(height: 14),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
                  children: [
                    TextSpan(text: 'Collab', style: TextStyle(color: AppColors.brown)),
                    TextSpan(text: 'Note', style: TextStyle(color: AppColors.mocca)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text('Plan  •  Create  •  Collaborate', style: TextStyle(color: AppColors.brown, fontSize: 14)),
              const SizedBox(height: 40),
              if (_error == null)
                const ShimmerBar(width: 150, height: 8)
              else ...[
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
                const SizedBox(height: 8),
                TextButton(onPressed: _boot, child: const Text('Coba Lagi')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
