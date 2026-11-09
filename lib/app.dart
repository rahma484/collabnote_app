import 'package:flutter/material.dart';

import 'ui/shell/app_shell.dart';

class CollabNoteApp extends StatelessWidget {
  const CollabNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CollabNote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF8F9FC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF635BDB),
          primary: const Color(0xFF635BDB),
          surface: const Color(0xFFF8F9FC),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F9FC),
          foregroundColor: Color(0xFF20243A),
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const AppShell(),
    );
  }
}