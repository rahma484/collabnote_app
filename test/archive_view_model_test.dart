import 'package:collab_note/data/repositories/archive_repository.dart';
import 'package:collab_note/data/services/collab_note_service.dart';
import 'package:collab_note/ui/archive/archive_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tes ViewModel Arsip: memuat data contoh, mencari, dan memfilter.
void main() {
  late ArchiveViewModel vm;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    vm = ArchiveViewModel(ArchiveRepository(CollabNoteService()));
    await vm.load();
  });

  test('load() mengisi daftar arsip dan mematikan isLoading', () {
    expect(vm.isLoading, false);
    expect(vm.error, isNull);
    expect(vm.all.length, greaterThanOrEqualTo(5));
  });

  test('pencarian judul bekerja', () {
    vm.setQuery('regresi');
    expect(vm.filtered.length, 1);
  });

  test('filter semester dan mode bekerja', () {
    vm.setFilter('Semester 4');
    expect(vm.filtered.length, 3);
    vm.setFilter('Kelompok');
    expect(vm.filtered.length, 1);
  });
}
