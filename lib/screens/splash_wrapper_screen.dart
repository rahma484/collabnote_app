import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_dashboard_screen.dart';
import 'login_screen.dart';

class SplashWrapperScreen extends StatefulWidget {
  const SplashWrapperScreen({super.key});

  @override
  State<SplashWrapperScreen> createState() => _SplashWrapperScreenState();
}

class _SplashWrapperScreenState extends State<SplashWrapperScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserSession();
  }

  // 1.a. Aplikasi Dibuka (Splash / Wrapper Check):
  // Mengecek apakah token sesi pengguna sudah tersimpan di perangkat
  Future<void> _checkUserSession() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    final session = Supabase.instance.client.auth.currentSession;

    if (!mounted) return;

    if (session != null) {
      // Jika sudah ada token sesi, langsung arahkan ke Home Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
      );
    } else {
      // Jika belum ada, arahkan ke Login Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Simpel, Lucu & Elegan
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFF472B6)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'CollabNote',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Smart Collaborative Journaling',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Color(0xFF7C3AED)),
          ],
        ),
      ),
    );
  }
}