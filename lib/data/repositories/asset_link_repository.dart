import '../../domain/models/asset_link.dart';
import '../services/collab_note_service.dart';

class AssetLinkRepository {
  final CollabNoteService _service;

  AssetLinkRepository(this._service);

  Future<List<AssetLink>> getAssetLinks(String projectId) {
    return _service.fetchAssetLinks(projectId);
  }

  Future<AssetLink> addAssetLink({
    required String projectId,
    required String title,
    required String url,
    required String category,
  }) {
    return _service.createAssetLink(
      projectId: projectId,
      title: title,
      url: url,
      category: category,
    );
  }

  Future<void> removeAssetLink(String assetLinkId) {
    return _service.deleteAssetLink(assetLinkId);
  }
}
