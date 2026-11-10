import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/asset_link.dart';
import '../core/app_colors.dart';

/// Widget dan helper yang dipakai bersama oleh tab Assets dan
/// tab Links di halaman detail proyek.

const List<String> assetCategories = [
  'Dokumen',
  'Desain',
  'Kode',
  'Presentasi',
  'Lainnya',
];

class AssetLinkInput {
  final String title;
  final String url;
  final String category;

  const AssetLinkInput({
    required this.title,
    required this.url,
    required this.category,
  });
}

IconData assetCategoryIcon(String category) {
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

/// Menambahkan https:// jika pengguna menempel URL tanpa skema.
String normalizeAssetUrl(String raw) {
  final text = raw.trim();

  if (text.isEmpty) return text;

  final hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*://').hasMatch(text);

  return hasScheme ? text : 'https://$text';
}

/// Membuka tautan di browser / aplikasi terkait (GitHub, Figma, Drive)
/// menggunakan url_launcher.
Future<void> openAssetLink(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final uri = Uri.tryParse(url.trim());

  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    messenger.showSnackBar(
      const SnackBar(content: Text('URL tidak valid.')),
    );
    return;
  }

  var success = false;

  try {
    success = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    success = false;
  }

  if (!success) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Tidak dapat membuka tautan.')),
    );
  }
}

Future<AssetLinkInput?> showAddAssetLinkDialog(BuildContext context) {
  return showDialog<AssetLinkInput>(
    context: context,
    builder: (_) => const _AddAssetLinkDialog(),
  );
}

Future<bool> confirmDeleteAssetLink(
  BuildContext context,
  AssetLink asset,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Hapus Tautan'),
      content: Text('Hapus "${asset.title}" dari daftar tautan?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );

  return confirmed == true;
}

class AssetLinkCard extends StatelessWidget {
  final AssetLink asset;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const AssetLinkCard({
    super.key,
    required this.asset,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: AppColors.primarySoft,
          child: Icon(
            assetCategoryIcon(asset.category),
            color: AppColors.primary,
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
        onTap: onOpen,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'open') {
              onOpen();
            } else if (value == 'delete') {
              onDelete();
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
}

class _AddAssetLinkDialog extends StatefulWidget {
  const _AddAssetLinkDialog();

  @override
  State<_AddAssetLinkDialog> createState() => _AddAssetLinkDialogState();
}

class _AddAssetLinkDialogState extends State<_AddAssetLinkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();

  String _category = assetCategories.first;

  // Controller dibuang di dispose() milik dialog ini sendiri, bukan
  // setelah showDialog selesai, agar aman saat animasi tutup berjalan.
  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      AssetLinkInput(
        title: _titleController.text.trim(),
        url: normalizeAssetUrl(_urlController.text),
        category: _category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Tautan'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul tautan',
                  hintText: 'Contoh: Draft Laporan Bab 1-3',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  hintText: 'https://',
                ),
                validator: (value) {
                  final url = normalizeAssetUrl(value ?? '');
                  if (url.isEmpty) return 'URL wajib diisi.';

                  final uri = Uri.tryParse(url);
                  if (uri == null || uri.host.isEmpty) {
                    return 'URL tidak valid.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: assetCategories
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
