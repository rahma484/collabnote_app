import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/template_repository.dart';
import '../../domain/models/template_model.dart';
import '../core/app_colors.dart';
import '../core/app_widgets.dart';
import 'template_gallery_view_model.dart';
import 'template_preview_screen.dart';

IconData templateIcon(String format) {
  switch (format) {
    case 'DOCX':
      return Icons.description_outlined;
    case 'XLSX':
      return Icons.table_chart_outlined;
    case 'PPTX':
      return Icons.slideshow_outlined;
    case 'MD':
      return Icons.article_outlined;
    case 'Diagram':
      return Icons.account_tree_outlined;
    case 'Template Visual':
      return Icons.palette_outlined;
    default:
      return Icons.insert_drive_file_outlined;
  }
}

/// Smart Template Gallery. Bukan menu utama: dibuka saat membuat penugasan atau dari Ruang Kerja.
/// Mengembalikan [TemplateModel] yang dipilih lewat tombol "Gunakan Template", atau null bila ditutup.
class TemplateGalleryScreen extends StatefulWidget {
  final String confirmLabel;

  const TemplateGalleryScreen({super.key, this.confirmLabel = 'Gunakan Template'});

  @override
  State<TemplateGalleryScreen> createState() => _TemplateGalleryScreenState();
}

class _TemplateGalleryScreenState extends State<TemplateGalleryScreen> {
  late final TemplateGalleryViewModel _vm;

  static const Map<String, TemplateCategory?> _categories = {
    'Semua': null,
    'IT': TemplateCategory.it,
    'Design & Creative': TemplateCategory.design,
    'Business': TemplateCategory.business,
    'Academic & General': TemplateCategory.academic,
    'Template Saya': TemplateCategory.custom,
  };

  @override
  void initState() {
    super.initState();
    _vm = TemplateGalleryViewModel(context.read<TemplateRepository>());
    _vm.load();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _open(TemplateModel t) async {
    final chosen = await pushSlideUp<TemplateModel>(
      context,
      TemplatePreviewScreen(template: t, viewModel: _vm, confirmLabel: widget.confirmLabel),
    );
    if (chosen != null && mounted) Navigator.pop(context, chosen);
  }

  Future<void> _addCustom() async {
    final t = await _vm.addCustomTemplate();
    if (t != null && mounted) {
      showSnack(context, 'File "${t.title}" ditambahkan sebagai Template Saya.');
      _vm.setCategory(TemplateCategory.custom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Template Gallery')),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (_vm.isLoading && _vm.repository.all.isEmpty) return const ShimmerLoading();
          if (_vm.error != null) {
            return EmptyState(icon: Icons.error_outline, message: _vm.error!, actionLabel: 'Coba Lagi', onAction: _vm.load);
          }
          final list = _vm.filtered;
          final selectedCat = _categories.entries.firstWhere((e) => e.value == _vm.category).key;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              SearchField(hint: 'Cari template', onChanged: _vm.setQuery),
              const SizedBox(height: 12),
              PillFilterRow(
                options: _categories.keys.toList(),
                selected: selectedCat,
                onSelected: (v) => _vm.setCategory(_categories[v]),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: PillFilterRow(options: _vm.formats, selected: _vm.format, onSelected: _vm.setFormat),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Hanya favorit',
                    onPressed: _vm.toggleFavoritesOnly,
                    icon: Icon(_vm.favoritesOnly ? Icons.star_rounded : Icons.star_border_rounded, color: AppColors.mocca),
                  ),
                ],
              ),
              if (!_vm.hasFilter && _vm.recent.isNotEmpty) ...[
                const SectionTitle('Baru Digunakan'),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final t in _vm.recent)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            backgroundColor: AppColors.chip,
                            side: BorderSide.none,
                            avatar: Icon(templateIcon(t.format), size: 18, color: AppColors.brown),
                            label: Text(t.title),
                            onPressed: () => _open(t),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              PressableScale(
                onTap: _addCustom,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.mocca),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.upload_file_outlined, color: AppColors.mocca),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Custom Template: gunakan file milik sendiri', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: EmptyState(icon: Icons.search_off, message: 'Tidak ada template yang cocok.'),
                )
              else
                for (final t in list)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _TemplateCard(
                      template: t,
                      favorite: _vm.isFavorite(t.id),
                      onTap: () => _open(t),
                      onFavorite: () => _vm.toggleFavorite(t.id),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final TemplateModel template;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const _TemplateCard({required this.template, required this.favorite, required this.onTap, required this.onFavorite});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Hero(
              tag: 'template-${template.id}',
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: AppColors.beige.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
                  child: Icon(templateIcon(template.format), color: AppColors.brown),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(template.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      Pill(label: template.format, background: AppColors.mocca, foreground: Colors.white, fontSize: 11),
                      Pill(label: template.category.shortLabel, background: AppColors.chip, foreground: AppColors.brown, fontSize: 11),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onFavorite,
              icon: Icon(favorite ? Icons.star_rounded : Icons.star_border_rounded, color: AppColors.mocca),
            ),
          ],
        ),
      ),
    );
  }
}
