import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/splash_wrapper_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ganti URL & AnonKey dengan kredensial Supabase milikmu
  await Supabase.initialize(
    url: 'https://YOUR_SUPABASE_URL.supabase.co',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  runApp(const CollabNoteApp());
}

class CollabNoteApp extends StatelessWidget {
  const CollabNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CollabNote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF7C3AED),
        scaffoldBackgroundColor: const Color(0xFFFAF9F6),
      ),
      home: const SplashWrapperScreen(),
    );
  }
}
