import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/project_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/asset_link_repository.dart';
import '../../domain/models/project.dart';

import '../home/home_view_model.dart';
import '../home/home_screen.dart';

import '../projects/projects_view_model.dart';
import '../projects/projects_screen.dart';
import '../projects/create_project_screen.dart';

import '../project_detail/project_detail_screen.dart';
import '../profile/profile_screen.dart';

import '../checklist/checklist_view_model.dart';
import '../checklist/checklist_screen.dart';

import '../assets/assets_view_model.dart';
import '../assets/assets_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  late final HomeViewModel _homeViewModel;
  late final ProjectsViewModel _projectsViewModel;
  late final ChecklistViewModel _checklistViewModel;
  late final AssetsViewModel _assetsViewModel;

  @override
  void initState() {
    super.initState();

    final projectRepository = context.read<ProjectRepository>();
    final taskRepository = context.read<TaskRepository>();
    final assetLinkRepository = context.read<AssetLinkRepository>();

    // Buang sisa data akun sebelumnya (jika pengguna baru saja
    // keluar lalu masuk dengan akun lain).
    taskRepository.clear();

    _homeViewModel = HomeViewModel(
      projectRepository: projectRepository,
      taskRepository: taskRepository,
    );

    _projectsViewModel = ProjectsViewModel(projectRepository);

    _checklistViewModel = ChecklistViewModel(
      projectRepository: projectRepository,
      taskRepository: taskRepository,
    );

    _assetsViewModel = AssetsViewModel(assetLinkRepository);

    _reloadAll();
  }

  /// Memuat ulang Beranda, Proyek, dan Checklist.
  /// Tab Assets memuat sendiri setelah daftar proyek tersedia.
  Future<void> _reloadAll() async {
    await Future.wait([
      _homeViewModel.load(),
      _projectsViewModel.load(),
      _checklistViewModel.load(),
    ]);
  }

  Future<void> _openCreateProject() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateProjectScreen(
          viewModel: _projectsViewModel,
        ),
      ),
    );

    if (created == true && mounted) {
      setState(() {
        _selectedIndex = 0;
      });

      await _reloadAll();
    }
  }

  Future<void> _openProject(Project project) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(project: project),
      ),
    );

    if (deleted == true && mounted) {
      await _reloadAll();
    }
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _homeViewModel.dispose();
    _projectsViewModel.dispose();
    _checklistViewModel.dispose();
    _assetsViewModel.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        viewModel: _homeViewModel,
        onCreateProject: _openCreateProject,
        onOpenProject: _openProject,
        onOpenProfile: _openProfile,
      ),
      ProjectsScreen(
        viewModel: _projectsViewModel,
        onOpenProject: _openProject,
      ),
      ChecklistScreen(viewModel: _checklistViewModel),
      AssetsScreen(
        viewModel: _assetsViewModel,
        homeViewModel: _homeViewModel,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: context.read<TaskRepository>(),
        builder: (context, child) {
          final incompleteCount =
              context.read<TaskRepository>().incompleteTasks.length;

          return NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Beranda',
              ),
              const NavigationDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder_rounded),
                label: 'Proyek',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: incompleteCount > 0,
                  label: Text('$incompleteCount'),
                  child: const Icon(Icons.checklist_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: incompleteCount > 0,
                  label: Text('$incompleteCount'),
                  child: const Icon(Icons.checklist_rounded),
                ),
                label: 'Checklist',
              ),
              const NavigationDestination(
                icon: Icon(Icons.link_outlined),
                selectedIcon: Icon(Icons.link_rounded),
                label: 'Assets',
              ),
            ],
          );
        },
      ),
    );
  }
}
