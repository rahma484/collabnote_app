import 'package:flutter/foundation.dart';

import '../../data/repositories/archive_repository.dart';
import '../../domain/models/archive_model.dart';
import '../../domain/models/assignment_model.dart';

/// ViewModel fitur Arsip (data informasi): daftar arsip, pencarian, dan filter.
class ArchiveViewModel extends ChangeNotifier {
  ArchiveViewModel(this.repository) {
    repository.addListener(notifyListeners);
  }

  final ArchiveRepository repository;

  bool isLoading = false;
  String? error;
  String query = '';
  String filter = 'Semua';

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await repository.load();
    } catch (e) {
      error = 'Gagal memuat arsip: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<ArchiveModel> get all => repository.all;

  bool get isEmpty => repository.all.isEmpty;

  /// Pilihan filter: Semua, mode pengerjaan, semester, dan tahun akademik.
  List<String> get filterOptions {
    final semesters = <int>{};
    final years = <String>{};
    for (final a in repository.all) {
      semesters.add(a.semester);
      years.add(a.academicYear);
    }
    final sortedSemesters = semesters.toList()..sort();
    final sortedYears = years.toList()..sort();
    return [
      'Semua',
      'Individu',
      'Kelompok',
      for (final s in sortedSemesters) 'Semester $s',
      for (final y in sortedYears) 'Tahun $y',
    ];
  }

  /// Hasil pencarian (judul, mata kuliah, semester) + filter terpilih.
  List<ArchiveModel> get filtered {
    final q = query.trim().toLowerCase();
    return repository.all.where((a) {
      if (filter == 'Individu' && a.mode != AssignmentMode.individu) return false;
      if (filter == 'Kelompok' && a.mode != AssignmentMode.kelompok) return false;
      if (filter.startsWith('Semester ') && 'Semester ${a.semester}' != filter) return false;
      if (filter.startsWith('Tahun ') && 'Tahun ${a.academicYear}' != filter) return false;
      if (q.isNotEmpty) {
        final text = '${a.title} ${a.courseName} semester ${a.semester}'.toLowerCase();
        if (!text.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  /// Pengelompokan: semester, lalu mata kuliah (urutan terbaru di atas).
  Map<String, List<ArchiveModel>> get grouped {
    final map = <String, List<ArchiveModel>>{};
    for (final a in filtered) {
      map.putIfAbsent('Semester ${a.semester}  -  ${a.courseName}', () => []).add(a);
    }
    return map;
  }

  void setQuery(String v) {
    query = v;
    notifyListeners();
  }

  void setFilter(String v) {
    filter = v;
    notifyListeners();
  }

  @override
  void dispose() {
    repository.removeListener(notifyListeners);
    super.dispose();
  }
}
