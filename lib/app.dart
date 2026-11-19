import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/repositories/profile_repository.dart';
import 'ui/core/app_theme.dart';
import 'ui/auth/auth_screen.dart';

class CollabNoteApp extends StatelessWidget {
  const CollabNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CollabNote',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Pengaturan tampilan di Profil (ukuran teks) berlaku untuk seluruh aplikasi.
      builder: (context, child) {
        final size = context.watch<ProfileRepository>().user.textSize;
        final scale = size == 0 ? 0.9 : (size == 2 ? 1.15 : 1.0);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        );
      },
      home: const AuthScreen(),
    );
  }
}
