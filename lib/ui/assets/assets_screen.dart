import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: unused_import
import '../../domain/models/project.dart';
import '../../domain/models/asset_link.dart';
import '../home/home_view_model.dart';
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
        backgroundColor: const Color(0xFF635BDB),
        foregroundColor: Colors.white,
        onPressed: _showAddLinkDialog,
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
                          style: TextStyle(color: Color(0xFF85899A)),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.viewModel.assetLinks.length,
                      itemBuilder: (context, index) {
                        final asset = widget.viewModel.assetLinks[index];

                        return _buildAssetCard(asset);
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

  Widget _buildAssetCard(AssetLink asset) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE8E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEFEDFF),
          child: Icon(
            _categoryIcon(asset.category),
            color: const Color(0xFF635BDB),
          ),
        ),
        title: Text(
          asset.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${asset.category}\n${asset.url}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        onTap: () => _openLink(asset.url),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'open') {
              _openLink(asset.url);
            } else if (value == 'delete') {
              _deleteLink(asset);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'open',
              child: Text('Buka tautan'),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text('Hapus tautan'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'dokumen':
        return Icons.description_outlined;
      case 'desain':
        return Icons.palette_outlined;
      case 'kode':
        return Icons.code;
      case 'presentasi':
        return Icons.slideshow_outlined;
      default:
        return Icons.link;
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL tidak valid.')),
      );
      return;
    }

    final success = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka tautan.')),
      );
    }
  }

  Future<void> _showAddLinkDialog() async {
    final projects = widget.homeViewModel.projects;

    if (projects.isEmpty) return;

    final titleController = TextEditingController();
    final urlController = TextEditingController();

    String category = 'Dokumen';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Tautan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Judul tautan',
                        hintText: 'Contoh: Draft Laporan Bab 1-3',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: urlController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'URL',
                        hintText: 'https://',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Dokumen',
                          child: Text('Dokumen'),
                        ),
                        DropdownMenuItem(
                          value: 'Desain',
                          child: Text('Desain'),
                        ),
                        DropdownMenuItem(
                          value: 'Kode',
                          child: Text('Kode'),
                        ),
                        DropdownMenuItem(
                          value: 'Presentasi',
                          child: Text('Presentasi'),
                        ),
                        DropdownMenuItem(
                          value: 'Lainnya',
                          child: Text('Lainnya'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            category = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      final title = titleController.text.trim();
      final url = urlController.text.trim();

      if (title.isEmpty || url.isEmpty) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Judul dan URL wajib diisi.'),
          ),
        );
      } else {
        final success = await widget.viewModel.addAssetLink(
          title: title,
          url: url,
          category: category,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Tautan berhasil ditambahkan.'
                    : 'Gagal menambahkan tautan.',
              ),
            ),
          );
        }
      }
    }

    titleController.dispose();
    urlController.dispose();
  }

  Future<void> _deleteLink(AssetLink asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tautan'),
        content: Text('Hapus "${asset.title}" dari daftar tautan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await widget.viewModel.removeAssetLink(asset.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Tautan berhasil dihapus.' : 'Gagal menghapus tautan.',
          ),
        ),
      );
    }
  }
}