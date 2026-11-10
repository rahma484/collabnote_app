import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/services/collab_note_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/project_repository.dart';
import '../data/repositories/task_repository.dart';
import '../data/repositories/asset_link_repository.dart';

class AppDependencies extends StatelessWidget {
  final Widget child;

  const AppDependencies({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CollabNoteService>(
          create: (_) => CollabNoteService(
            Supabase.instance.client,
          ),
        ),

        Provider<AuthRepository>(
          create: (context) => AuthRepository(
            context.read<CollabNoteService>(),
          ),
        ),

        Provider<ProjectRepository>(
          create: (context) => ProjectRepository(
            context.read<CollabNoteService>(),
          ),
        ),

        ChangeNotifierProvider<TaskRepository>(
          create: (context) => TaskRepository(
            context.read<CollabNoteService>(),
          ),
        ),

        Provider<AssetLinkRepository>(
          create: (context) => AssetLinkRepository(
            context.read<CollabNoteService>(),
          ),
        ),
      ],
      child: child,
    );
  }
}