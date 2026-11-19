import 'package:flutter/foundation.dart';

import '../../data/repositories/template_repository.dart';
import '../../domain/models/template_model.dart';

/// ViewModel Smart Template Gallery: pencarian, filter kategori/format, favorit, dan template terbaru.
class TemplateGalleryViewModel extends ChangeNotifier {
  TemplateGalleryViewModel(this.repository) {
    repository.addListener(notifyListeners);
  }

  final TemplateRepository repository;

  bool isLoading = false;
  String? error;

  String query = '';
  TemplateCategory? category; // null = semua kategori
  String format = 'Semua';
  bool favoritesOnly = false;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await repository.load();
    } catch (e) {
      error = 'Gagal memuat template: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<String> get formats {
    final set = <String>{};
    for (final t in repository.all) {
      set.add(t.format);
    }
    return ['Semua', ...set];
  }

  bool get hasFilter => query.isNotEmpty || category != null || format != 'Semua' || favoritesOnly;

  List<TemplateModel> get filtered {
    final q = query.trim().toLowerCase();
    return repository.all.where((t) {
      if (category != null && t.category != category) return false;
      if (format != 'Semua' && t.format != format) return false;
      if (favoritesOnly && !repository.isFavorite(t.id)) return false;
      if (q.isNotEmpty && !('${t.title} ${t.description} ${t.format}'.toLowerCase().contains(q))) return false;
      return true;
    }).toList();
  }

  List<TemplateModel> get recent => repository.recent;

  void setQuery(String v) {
    query = v;
    notifyListeners();
  }

  void setCategory(TemplateCategory? v) {
    category = v;
    notifyListeners();
  }

  void setFormat(String v) {
    format = v;
    notifyListeners();
  }

  void toggleFavoritesOnly() {
    favoritesOnly = !favoritesOnly;
    notifyListeners();
  }

  bool isFavorite(String id) => repository.isFavorite(id);

  Future<void> toggleFavorite(String id) => repository.toggleFavorite(id);

  Future<TemplateModel?> addCustomTemplate() => repository.addCustomFromFile();

  @override
  void dispose() {
    repository.removeListener(notifyListeners);
    super.dispose();
  }
}
