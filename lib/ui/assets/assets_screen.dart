import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../home/home_view_model.dart';
import 'asset_link_widgets.dart';
import 'assets_view_model.dart';

class AssetsScreen extends StatefulWidget {
  final AssetsViewModel viewModel;
  final HomeViewModel homeViewModel;

  const AssetsScreen({
    super.key,
    required this.viewModel,
    required this.homeViewModel,
  });

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  String? _selectedProjectId;
  String? _loadedProjectId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Assets & Links Hub',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _addLink,
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: widget.homeViewModel,
        builder: (context, child) {
          final projects = widget.homeViewModel.projects;

          if (widget.homeViewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (projects.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada proyek. Buat proyek terlebih dahulu untuk menyimpan tautan.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final selectedId = projects.any(
            (project) => project.id == _selectedProjectId,
          )
              ? _selectedProjectId!
              : projects.first.id;

          if (_loadedProjectId != selectedId) {
            _loadedProjectId = selectedId;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                widget.viewModel.load(selectedId);
              }
            });
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text(
                  'Pilih Proyek',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DropdownButtonFormField<String>(
                  key: ValueKey(selectedId),
                  initialValue: selectedId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: projects.map((project) {
                    return DropdownMenuItem<String>(
                      value: project.id,
                      child: Text(
                        project.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _selectedProjectId = value;
                      _loadedProjectId = value;
                    });

                    widget.viewModel.load(value);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListenableBuilder(
                  listenable: widget.viewModel,
                  builder: (context, child) {
                    if (widget.viewModel.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (widget.viewModel.error != null &&
                        widget.viewModel.assetLinks.isEmpty) {
                      return Center(
                        child: Text(
                          'Gagal memuat tautan: ${widget.viewModel.error}',
                        ),
                      );
                    }

                    if (widget.viewModel.assetLinks.isEmpty) {
                      return const Center(
                        child: Text(
                          'Belum ada tautan untuk proyek ini.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.viewModel.assetLinks.length,
                      itemBuilder: (context, index) {
                        final asset = widget.viewModel.assetLinks[index];

                        return AssetLinkCard(
                          asset: asset,
                          onOpen: () => openAssetLink(context, asset.url),
                          onDelete: () async {
                            final confirmed = await confirmDeleteAssetLink(
                              context,
                              asset,
                            );

                            if (!confirmed || !mounted) return;

                            final success = await widget.viewModel
                                .removeAssetLink(asset.id);

                            if (!mounted) return;

                            _showMessage(
                              success
                                  ? 'Tautan berhasil dihapus.'
                                  : 'Gagal menghapus tautan.',
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addLink() async {
    if (widget.homeViewModel.projects.isEmpty) return;

    final input = await showAddAssetLinkDialog(context);

    if (input == null || !mounted) return;

    final success = await widget.viewModel.addAssetLink(
      title: input.title,
      url: input.url,
      category: input.category,
    );

    if (!mounted) return;

    _showMessage(
      success
          ? 'Tautan berhasil ditambahkan.'
          : 'Gagal menambahkan tautan.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
