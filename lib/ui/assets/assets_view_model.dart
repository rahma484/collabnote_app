import 'package:flutter/foundation.dart';

import '../../data/repositories/asset_link_repository.dart';
import '../../domain/models/asset_link.dart';

class AssetsViewModel extends ChangeNotifier {
  final AssetLinkRepository _repository;

  AssetsViewModel(this._repository);

  List<AssetLink> _assetLinks = [];

  String? _projectId;

  bool isLoading = false;
  String? error;

  List<AssetLink> get assetLinks => List.unmodifiable(_assetLinks);

  Future<void> load(String projectId) async {
    _projectId = projectId;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      _assetLinks = await _repository.getAssetLinks(projectId);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAssetLink({
    required String title,
    required String url,
    required String category,
  }) async {
    if (_projectId == null) {
      error = 'Proyek belum dipilih.';
      notifyListeners();
      return false;
    }

    try {
      error = null;

      await _repository.addAssetLink(
        projectId: _projectId!,
        title: title,
        url: url,
        category: category,
      );

      await load(_projectId!);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeAssetLink(String assetLinkId) async {
    try {
      error = null;

      await _repository.removeAssetLink(assetLinkId);

      _assetLinks = _assetLinks
          .where((item) => item.id != assetLinkId)
          .toList();

      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}