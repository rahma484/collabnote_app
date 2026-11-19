import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/archive_repository.dart';
import '../../data/repositories/assignment_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/task_step_repository.dart';
import '../../data/repositories/template_repository.dart';
import '../../data/repositories/workspace_repository.dart';
import '../../data/services/collab_note_service.dart';
import '../../data/services/local_file_service.dart';
import '../archive/archive_screen.dart';
import '../archive/archive_view_model.dart';
import '../assignments/assignments_screen.dart';
import '../assignments/assignments_view_model.dart';
import '../home/home_screen.dart';
import '../home/home_view_model.dart';
import '../profile/profile_screen.dart';
import '../profile/profile_view_model.dart';
import '../workspace/workspace_screen.dart';
import '../workspace/workspace_view_model.dart';
import 'navigation_controller.dart';

/// Kerangka utama: 5 tab pada NavigationBar (Beranda, Penugasan, Ruang Kerja, Arsip, Profil).
/// ViewModel setiap halaman dibuat di sini lalu di-load().
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final NavigationController _nav;
  late final AssignmentRepository _assignments;
  late final HomeViewModel _home;
  late final AssignmentsViewModel _assignmentsVm;
  late final WorkspaceViewModel _workspace;
  late final ArchiveViewModel _archive;
  late final ProfileViewModel _profile;

  @override
  void initState() {
    super.initState();
    _nav = context.read<NavigationController>();
    _assignments = context.read<AssignmentRepository>();
    final profileRepo = context.read<ProfileRepository>();

    _home = HomeViewModel(assignments: _assignments, profile: profileRepo);
    _assignmentsVm = AssignmentsViewModel(_assignments);
    _workspace = WorkspaceViewModel(
      assignments: _assignments,
      steps: context.read<TaskStepRepository>(),
      workspaces: context.read<WorkspaceRepository>(),
      groups: context.read<GroupRepository>(),
      profile: profileRepo,
      templates: context.read<TemplateRepository>(),
      files: context.read<LocalFileService>(),
    );
    _archive = ArchiveViewModel(context.read<ArchiveRepository>());
    _profile = ProfileViewModel(
      profile: profileRepo,
      groups: context.read<GroupRepository>(),
      service: context.read<CollabNoteService>(),
      files: context.read<LocalFileService>(),
      reloadAll: _reloadAll,
    );

    _nav.addListener(_onNavigation);
    _home.load();
    _assignmentsVm.load();
    _workspace.load();
    _archive.load();
    _profile.load();
  }

  /// Dipakai oleh "Reset ke Data Contoh": semua repository memuat ulang dari service.
  Future<void> _reloadAll() async {
    _workspace.close();
    await Future.wait([
      context.read<ProfileRepository>().load(force: true),
      context.read<TaskStepRepository>().load(force: true),
      context.read<WorkspaceRepository>().load(force: true),
      context.read<GroupRepository>().load(force: true),
      context.read<ArchiveRepository>().load(force: true),
      context.read<TemplateRepository>().load(force: true),
    ]);
    await _assignments.load(force: true);
  }

  void _onNavigation() {
    final id = _nav.consumeWorkspaceRequest();
    if (id != null) _workspace.open(id);
  }

  @override
  void dispose() {
    _nav.removeListener(_onNavigation);
    _home.dispose();
    _assignmentsVm.dispose();
    _workspace.dispose();
    _archive.dispose();
    _profile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(viewModel: _home, onOpenWorkspace: _nav.openWorkspace),
      AssignmentsScreen(viewModel: _assignmentsVm),
      WorkspaceScreen(viewModel: _workspace),
      ArchiveScreen(viewModel: _archive),
      ProfileScreen(viewModel: _profile),
    ];

    return ListenableBuilder(
      listenable: _nav,
      builder: (context, _) {
        return Scaffold(
          body: IndexedStack(index: _nav.index, children: pages),
          bottomNavigationBar: ListenableBuilder(
            listenable: _assignments,
            builder: (context, _) {
              final pending = _assignments.pendingActionCount;
              return ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: NavigationBar(
                selectedIndex: _nav.index,
                onDestinationSelected: _nav.goTo,
                destinations: [
                  const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Beranda'),
                  const NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Penugasan'),
                  NavigationDestination(
                    icon: Badge(isLabelVisible: pending > 0, label: Text('$pending'), child: const Icon(Icons.folder_outlined)),
                    selectedIcon: Badge(isLabelVisible: pending > 0, label: Text('$pending'), child: const Icon(Icons.folder)),
                    label: 'Ruang Kerja',
                  ),
                  const NavigationDestination(icon: Icon(Icons.archive_outlined), selectedIcon: Icon(Icons.archive), label: 'Arsip'),
                  const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
                ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
