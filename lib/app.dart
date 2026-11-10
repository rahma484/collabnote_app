import 'package:flutter/material.dart';

import 'ui/auth/auth_gate.dart';
import 'ui/core/app_theme.dart';

class CollabNoteApp extends StatelessWidget {
  const CollabNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CollabNote',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}
