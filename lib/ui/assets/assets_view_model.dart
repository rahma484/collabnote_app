import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/repositories/asset_link_repository.dart';
import '../../domain/models/asset_link.dart';

class AssetsViewModel extends ChangeNotifier {
  final AssetLinkRepository _repository;

  AssetsViewModel(this._repository);

  List<AssetLink> _assetLinks = [];

  String? _projectId;
  StreamSubscription<List<AssetLink>>? _subscription;
  bool _disposed = false;

  bool isLoading = false;
  String? error;

  List<AssetLink> get assetLinks => List.unmodifiable(_assetLinks);

  Future<void> load(String projectId) async {
    _projectId = projectId;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final links = await _repository.getAssetLinks(projectId);

      // Abaikan hasil lama jika pengguna sudah pindah proyek.
      if (_projectId == projectId) {
        _assetLinks = links;
        _listenRealtime(projectId);
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Sinkronisasi real-time: tautan yang ditambah anggota lain
  /// langsung muncul tanpa refresh.
  void _listenRealtime(String projectId) {
    _subscription?.cancel();

    _subscription = _repository.watchAssetLinks(projectId).listen(
      (links) {
        _assetLinks = links;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('Realtime asset_links error: $e');
      },
    );
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

      final created = await _repository.addAssetLink(
        projectId: _projectId!,
        title: title,
        url: url,
        category: category,
      );

      // Stream realtime bisa saja sudah membawa tautan ini lebih dulu.
      if (!_assetLinks.any((item) => item.id == created.id)) {
        _assetLinks = [created, ..._assetLinks];
      }

      notifyListeners();
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

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
