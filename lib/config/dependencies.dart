import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/archive_repository.dart';
import '../data/repositories/assignment_repository.dart';
import '../data/repositories/group_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/task_step_repository.dart';
import '../data/repositories/template_repository.dart';
import '../data/repositories/workspace_repository.dart';
import '../data/services/collab_note_service.dart';
import '../data/services/local_file_service.dart';
import '../ui/shell/navigation_controller.dart';

/// Pendaftaran Service dan semua Repository (Dependency Injection dengan Provider).
/// Diambil di mana pun dengan context.read<Tipe>().
class AppDependencies extends StatelessWidget {
  final Widget child;

  const AppDependencies({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Service
        Provider<CollabNoteService>(create: (_) => CollabNoteService()),
        Provider<LocalFileService>(create: (_) => LocalFileService()),

        // Repository (semuanya ChangeNotifier supaya seluruh halaman ikut berubah)
        ChangeNotifierProvider<ProfileRepository>(
          create: (c) => ProfileRepository(c.read<CollabNoteService>()),
        ),
        ChangeNotifierProvider<TaskStepRepository>(
          create: (c) => TaskStepRepository(c.read<CollabNoteService>()),
        ),
        ChangeNotifierProvider<WorkspaceRepository>(
          create: (c) => WorkspaceRepository(c.read<CollabNoteService>(), c.read<LocalFileService>()),
        ),
        ChangeNotifierProvider<GroupRepository>(
          create: (c) => GroupRepository(c.read<CollabNoteService>(), c.read<LocalFileService>()),
        ),
        ChangeNotifierProvider<ArchiveRepository>(
          create: (c) => ArchiveRepository(c.read<CollabNoteService>()),
        ),
        ChangeNotifierProvider<TemplateRepository>(
          create: (c) => TemplateRepository(c.read<CollabNoteService>(), c.read<LocalFileService>()),
        ),
        ChangeNotifierProvider<AssignmentRepository>(
          create: (c) => AssignmentRepository(
            c.read<CollabNoteService>(),
            c.read<TaskStepRepository>(),
            c.read<WorkspaceRepository>(),
            c.read<GroupRepository>(),
            c.read<ArchiveRepository>(),
          ),
        ),

        // Status navigasi antar tab
        ChangeNotifierProvider<NavigationController>(create: (_) => NavigationController()),
      ],
      child: child,
    );
  }
}
