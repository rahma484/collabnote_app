import 'package:flutter/foundation.dart';

int _idCounter = 0;

/// Membuat ID unik, contoh: a-1731800000000000-1.
String newId(String prefix) {
  _idCounter++;
  return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_idCounter';
}

/// Dasar semua repository: ChangeNotifier + pemuatan data yang hanya dilakukan sekali.
/// Setiap perubahan data memanggil notifyListeners() sehingga seluruh halaman ikut berubah.
abstract class BaseRepository extends ChangeNotifier {
  bool _loaded = false;
  Future<void>? _loading;

  bool get isLoaded => _loaded;

  /// Diisi oleh subclass: mengambil data dari service.
  Future<void> loadData();

  Future<void> load({bool force = false}) {
    if (force && _loading == null) _loaded = false;
    if (_loaded) return Future.value();
    return _loading ??= _run();
  }

  Future<void> _run() async {
    try {
      await loadData();
      _loaded = true;
      notifyListeners();
    } finally {
      _loading = null;
    }
  }
}
