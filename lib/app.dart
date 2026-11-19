import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/repositories/profile_repository.dart';
import 'ui/core/app_theme.dart';
import 'ui/core/theme_controller.dart';
import 'ui/splash/splash_screen.dart';

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
        // select: hanya membangun ulang bila ukuran teks berubah, bukan setiap profil berubah.
        final size = context.select<ProfileRepository, int>((p) => p.user.textSize);
        final dark = context.watch<ThemeController>().isDark(context);
        final scale = size == 0 ? 0.9 : (size == 2 ? 1.15 : 1.0);
        return DarkModeFilter(
          dark: dark,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}
