import 'dart:async';

import 'package:collabnote_app/data/repositories/asset_link_repository.dart';
import 'package:collabnote_app/domain/models/asset_link.dart';
import 'package:collabnote_app/ui/assets/assets_view_model.dart';

import 'package:flutter_test/flutter_test.dart';

/// Repository palsu: tidak memanggil Supabase sama sekali,
/// sehingga ViewModel bisa diuji sendirian.
class FakeAssetLinkRepository implements AssetLinkRepository {
  final List<AssetLink> items;
  final StreamController<List<AssetLink>> realtime =
      StreamController<List<AssetLink>>.broadcast();

  bool shouldFail = false;
  int _counter = 0;

  FakeAssetLinkRepository(this.items);

  @override
  Future<List<AssetLink>> getAssetLinks(String projectId) async {
    if (shouldFail) throw Exception('koneksi gagal');
    return List.of(items);
  }

  @override
  Stream<List<AssetLink>> watchAssetLinks(String projectId) {
    return realtime.stream;
  }

  @override
  Future<AssetLink> addAssetLink({
    required String projectId,
    required String title,
    required String url,
    required String category,
  }) async {
    if (shouldFail) throw Exception('koneksi gagal');

    _counter++;
    final link = AssetLink(
      id: 'baru-$_counter',
      projectId: projectId,
      title: title,
      url: url,
      category: category,
      createdAt: DateTime(2026, 11, 10),
    );
    items.add(link);
    return link;
  }

  @override
  Future<void> removeAssetLink(String assetLinkId) async {
    if (shouldFail) throw Exception('koneksi gagal');
    items.removeWhere((item) => item.id == assetLinkId);
  }
}

AssetLink buildLink(String id, String title) {
  return AssetLink(
    id: id,
    projectId: 'p1',
    title: title,
    url: 'https://example.com/$id',
    category: 'Dokumen',
    createdAt: DateTime(2026, 11, 1),
  );
}

void main() {
  late FakeAssetLinkRepository repository;
  late AssetsViewModel viewModel;

  setUp(() {
    repository = FakeAssetLinkRepository([
      buildLink('a1', 'Draft Laporan'),
      buildLink('a2', 'Desain Figma'),
    ]);
    viewModel = AssetsViewModel(repository);
  });

  tearDown(() {
    viewModel.dispose();
    repository.realtime.close();
  });

  test(
    'load() mengisi assetLinks dan mengembalikan isLoading ke false',
    () async {
      final loadingStates = <bool>[];
      viewModel.addListener(() => loadingStates.add(viewModel.isLoading));

      await viewModel.load('p1');

      expect(viewModel.assetLinks.length, 2);
      expect(viewModel.error, isNull);
      expect(viewModel.isLoading, isFalse);
      // isLoading sempat true saat memuat, lalu false.
      expect(loadingStates.first, isTrue);
      expect(loadingStates.last, isFalse);
    },
  );

  test('load() menyimpan pesan error saat repository gagal', () async {
    repository.shouldFail = true;

    await viewModel.load('p1');

    expect(viewModel.error, isNotNull);
    expect(viewModel.assetLinks, isEmpty);
    expect(viewModel.isLoading, isFalse);
  });

  test('addAssetLink() menambahkan tautan baru di urutan teratas', () async {
    await viewModel.load('p1');

    final success = await viewModel.addAssetLink(
      title: 'Repo GitHub',
      url: 'https://github.com/contoh/collabnote',
      category: 'Kode',
    );

    expect(success, isTrue);
    expect(viewModel.assetLinks.length, 3);
    expect(viewModel.assetLinks.first.title, 'Repo GitHub');
  });

  test('addAssetLink() gagal jika proyek belum dipilih', () async {
    final success = await viewModel.addAssetLink(
      title: 'Tanpa proyek',
      url: 'https://example.com',
      category: 'Lainnya',
    );

    expect(success, isFalse);
    expect(viewModel.error, isNotNull);
  });

  test('removeAssetLink() menghapus tautan dari daftar', () async {
    await viewModel.load('p1');

    final success = await viewModel.removeAssetLink('a1');

    expect(success, isTrue);
    expect(viewModel.assetLinks.map((item) => item.id), ['a2']);
  });

  test('data realtime dari anggota lain langsung memperbarui daftar', () async {
    await viewModel.load('p1');

    repository.realtime.add([
      buildLink('a3', 'Link dari teman'),
      ...repository.items,
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.assetLinks.length, 3);
    expect(viewModel.assetLinks.first.title, 'Link dari teman');
  });
}
