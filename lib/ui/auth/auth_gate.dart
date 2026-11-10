import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/auth_repository.dart';
import '../shell/app_shell.dart';
import 'login_screen.dart';

/// Wrapper check saat aplikasi dibuka: jika sesi tersimpan di perangkat
/// langsung ke Beranda, jika belum ke halaman Login.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthRepository _repository;
  late final Stream<bool> _authChanges;

  @override
  void initState() {
    super.initState();

    _repository = context.read<AuthRepository>();
    _authChanges = _repository.authChanges;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      initialData: _repository.isLoggedIn,
      stream: _authChanges,
      builder: (context, snapshot) {
        final isLoggedIn = snapshot.data ?? false;

        return isLoggedIn ? const AppShell() : const LoginScreen();
      },
    );
  }
}
