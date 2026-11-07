import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/dependencies.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hdekkyakizsuwjlqbtef.supabase.co/rest/v1/',
    publishableKey: 'sb_publishable_5BgUL9Zh4h8b5hL9T4tZJA_DtObXOUI',
  );

  runApp(MultiProvider(providers: providers, child: const CollabNoteApp()));
}
