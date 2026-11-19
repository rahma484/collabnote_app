import 'package:collab_note/data/services/draft_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DraftStore menyimpan, memuat, dan menghapus draf', () async {
    SharedPreferences.setMockInitialValues({});
    final store = DraftStore();

    expect(await store.load('catatan'), isNull);

    await store.save('catatan', {'title': 'Judul', 'content': 'Isi'});
    final loaded = await store.load('catatan');
    expect(loaded, {'title': 'Judul', 'content': 'Isi'});

    await store.clear('catatan');
    expect(await store.load('catatan'), isNull);
  });
}
