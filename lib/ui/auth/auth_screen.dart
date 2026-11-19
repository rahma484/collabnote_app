import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/collab_note_service.dart';
import '../core/app_colors.dart';
import '../core/app_widgets.dart';
import '../splash/splash_screen.dart';

/// Layar Masuk / Registrasi. Memakai logo CollabNote (bukan ikon), header bergelombang
/// (CustomClipper), dan Hero animation untuk logo yang terbang dari Splash Screen.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _email = TextEditingController(),
      _password = TextEditingController(),
      _nim = TextEditingController(),
      _university = TextEditingController(text: 'Universitas Nusa Putra'),
      _program = TextEditingController(text: 'Teknik Informatika'),
      _invite = TextEditingController();
  bool _register = false, _loading = false, _obscure = true;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _nim, _university, _program, _invite]) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: AppColors.field,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = context.read<CollabNoteService>();
      bool ok;
      if (_register) {
        ok = await service.registerAccount(
              name: _name.text,
              email: _email.text,
              password: _password.text,
              nim: _nim.text,
              university: _university.text,
              studyProgram: _program.text,
            ) !=
            null;
        if (!ok) _error = 'Email sudah terdaftar. Silakan login.';
      } else {
        ok = await service.loginAccount(email: _email.text, password: _password.text);
        if (!ok) _error = 'Email atau password tidak sesuai.';
      }
      if (!ok) return;
      if (_invite.text.trim().isNotEmpty) {
        final joined = await service.joinGroupByCode(_invite.text);
        if (!joined && mounted) {
          showSnack(context, 'Login berhasil, tetapi kode undangan tidak ditemukan.');
        }
      }
      if (mounted) Navigator.of(context).pushReplacement(fadeScaleRoute<void>(const SplashScreen(quick: true)));
    } catch (e) {
      _error = 'Terjadi kesalahan: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header gelombang + logo asli CollabNote di dalam lingkaran putih.
            WaveHeader(
              height: 250,
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 40),
              child: Center(
                child: Hero(
                  tag: 'app-logo',
                  child: Container(
                    width: 128,
                    height: 128,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.brown.withValues(alpha: 0.25), blurRadius: 22, offset: const Offset(0, 10))],
                    ),
                    child: Image.asset('assets/images/logo_collabnote.png', fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                            children: [
                              TextSpan(text: 'Collab', style: TextStyle(color: AppColors.brown)),
                              TextSpan(text: 'Note', style: TextStyle(color: AppColors.mocca)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            _register ? 'Buat akun untuk memulai' : 'Masuk untuk melanjutkan kolaborasi',
                            key: ValueKey(_register),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                        const SizedBox(height: 22),
                        // Kolom registrasi muncul dengan animasi ukuran halus.
                        AnimatedSize(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: _register
                              ? Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TextFormField(
                                    controller: _name,
                                    decoration: _dec('Nama lengkap', Icons.person_outline),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                                  ),
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _dec('Email', Icons.email_outlined),
                          validator: (v) => v == null || !v.contains('@') ? 'Masukkan email yang valid' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          decoration: _dec('Password', Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => v == null || v.length < 6 ? 'Password minimal 6 karakter' : null,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: _register
                              ? Column(
                                  children: [
                                    const SizedBox(height: 12),
                                    TextFormField(controller: _nim, decoration: _dec('NIM', Icons.badge_outlined)),
                                    const SizedBox(height: 12),
                                    TextFormField(controller: _university, decoration: _dec('Universitas', Icons.school_outlined)),
                                    const SizedBox(height: 12),
                                    TextFormField(controller: _program, decoration: _dec('Program studi', Icons.menu_book_outlined)),
                                  ],
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _invite,
                          textCapitalization: TextCapitalization.characters,
                          decoration: _dec('Kode undangan kelompok (opsional)', Icons.group_add_outlined),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          child: _error == null
                              ? const SizedBox(width: double.infinity)
                              : Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(_error!, style: const TextStyle(color: AppColors.danger), textAlign: TextAlign.center),
                                ),
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(
                          label: _register ? 'Daftar dan Masuk' : 'Masuk',
                          color: AppColors.brown,
                          loading: _loading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => setState(() {
                                    _register = !_register;
                                    _error = null;
                                  }),
                          child: Text(_register ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Registrasi'),
                        ),
                        const Text(
                          'Mode simulasi • Data tersimpan di browser/perangkat ini',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
