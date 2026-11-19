import 'package:flutter/material.dart';

import 'app.dart';
import 'config/dependencies.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppDependencies(child: CollabNoteApp()));
}
