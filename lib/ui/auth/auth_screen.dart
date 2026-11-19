import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/collab_note_service.dart';
import '../core/app_colors.dart';
import '../splash/splash_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}
class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(), _email = TextEditingController(), _password = TextEditingController(), _nim = TextEditingController(), _university = TextEditingController(text: 'Universitas Nusa Putra'), _program = TextEditingController(text: 'Teknik Informatika'), _invite = TextEditingController();
  bool _register = false, _loading = false, _obscure = true;
  String? _error;
  @override
  void dispose() { for (final c in [_name,_email,_password,_nim,_university,_program,_invite]) { c.dispose(); } super.dispose(); }
  InputDecoration _dec(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none));
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final service = context.read<CollabNoteService>();
      bool ok;
      if (_register) {
        ok = await service.registerAccount(name: _name.text, email: _email.text, password: _password.text, nim: _nim.text, university: _university.text, studyProgram: _program.text) != null;
        if (!ok) _error = 'Email sudah terdaftar. Silakan login.';
      } else {
        ok = await service.loginAccount(email: _email.text, password: _password.text);
        if (!ok) _error = 'Email atau password tidak sesuai.';
      }
      if (!ok) return;
      if (_invite.text.trim().isNotEmpty) {
        final joined = await service.joinGroupByCode(_invite.text);
        if (!joined && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login berhasil, tetapi kode undangan tidak ditemukan.')));
      }
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SplashScreen()));
    } catch (e) { _error = 'Terjadi kesalahan: $e'; }
    finally { if (mounted) setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              elevation: 5,
              color: Colors.white.withValues(alpha: .95),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.groups_rounded, size: 58, color: AppColors.mocca),
                      const SizedBox(height: 8),
                      const Text('CollabNote', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.brown)),
                      const SizedBox(height: 4),
                      Text(_register ? 'Buat akun simulasi untuk memulai' : 'Masuk untuk melanjutkan kolaborasi', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 24),
                      if (_register) ...[
                        TextFormField(controller: _name, decoration: _dec('Nama lengkap', Icons.person_outline), validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: _dec('Email', Icons.email_outlined), validator: (v) => v == null || !v.contains('@') ? 'Masukkan email yang valid' : null),
                      const SizedBox(height: 12),
                      TextFormField(controller: _password, obscureText: _obscure, decoration: _dec('Password', Icons.lock_outline).copyWith(suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure = !_obscure))), validator: (v) => v == null || v.length < 6 ? 'Password minimal 6 karakter' : null),
                      if (_register) ...[
                        const SizedBox(height: 12),
                        TextFormField(controller: _nim, decoration: _dec('NIM', Icons.badge_outlined)),
                        const SizedBox(height: 12),
                        TextFormField(controller: _university, decoration: _dec('Universitas', Icons.school_outlined)),
                        const SizedBox(height: 12),
                        TextFormField(controller: _program, decoration: _dec('Program studi', Icons.menu_book_outlined)),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(controller: _invite, textCapitalization: TextCapitalization.characters, decoration: _dec('Kode undangan kelompok (opsional)', Icons.group_add_outlined)),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 50,
                        child: FilledButton(
                          onPressed: _loading ? null : _submit,
                          style: FilledButton.styleFrom(backgroundColor: AppColors.brown, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_register ? 'Daftar dan Masuk' : 'Masuk', style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(onPressed: _loading ? null : () => setState(() { _register = !_register; _error = null; }), child: Text(_register ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Registrasi')),
                      const Text('Mode simulasi • Data tersimpan di browser/perangkat ini', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.black45)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}