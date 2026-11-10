import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint(
    'SUPABASE_URL = [${const String.fromEnvironment('SUPABASE_URL')}]',
  );

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    publishableKey: const String.fromEnvironment('SUPABASE_KEY'),
  );

  runApp(const AppDependencies(child: CollabNoteApp()));
}
