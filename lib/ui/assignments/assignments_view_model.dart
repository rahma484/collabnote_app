import 'package:flutter/foundation.dart';

import '../../data/repositories/assignment_repository.dart';
import '../../domain/models/assignment_model.dart';

enum AssignmentSegment { semua, individu, kelompok, mendesak }

/// ViewModel halaman Penugasan: pencarian, filter, dan pengelompokan daftar penugasan.
class AssignmentsViewModel extends ChangeNotifier {
  AssignmentsViewModel(this.assignments) {
    assignments.addListener(notifyListeners);
  }

  final AssignmentRepository assignments;

  static const List<String> statusOptions = [
    'Semua',
    'Belum Dimulai',
    'Sedang Dikerjakan',
    'Menunggu Pemeriksaan',
    'Selesai',
    'Terlambat',
  ];

  bool isLoading = false;
  String? error;

  // Infinite scroll: daftar ditampilkan bertahap (halaman demi halaman).
  static const int pageSize = 6;
  int visibleCount = pageSize;
  bool isLoadingMore = false;

  AssignmentSegment segment = AssignmentSegment.semua;
  String query = '';
  String? courseFilter; // null = semua mata kuliah
  int? semesterFilter; // null = semua semester
  String statusFilter = 'Semua';
  bool groupByCourse = false;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await assignments.load();
    } catch (e) {
      error = 'Gagal memuat penugasan: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Tarik-untuk-memuat-ulang: membaca ulang data dari sumber (service) lalu kembali ke halaman pertama.
  Future<void> refresh() async {
    try {
      await assignments.load(force: true);
      error = null;
    } catch (e) {
      error = 'Gagal memuat penugasan: $e';
    }
    visibleCount = pageSize;
    notifyListeners();
  }

  /// Bagian daftar yang sudah dimuat (infinite scroll).
  List<AssignmentModel> get visible => filtered.take(visibleCount).toList();

  bool get hasMore => visibleCount < filtered.length;

  Future<void> loadMore() async {
    if (isLoadingMore || !hasMore) return;
    isLoadingMore = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 600)); // simulasi permintaan jaringan
    visibleCount += pageSize;
    isLoadingMore = false;
    notifyListeners();
  }

  void _resetPaging() => visibleCount = pageSize;

  bool get hasAnyAssignment => assignments.activeAssignments.isNotEmpty;

  bool get hasAdvancedFilter => courseFilter != null || semesterFilter != null || statusFilter != 'Semua' || groupByCourse;

  List<String> get courseOptions {
    final set = <String>{};
    for (final a in assignments.activeAssignments) {
      set.add(assignments.courseName(a));
    }
    final list = set.toList()..sort();
    return list;
  }

  List<int> get semesterOptions {
    final set = <int>{};
    for (final a in assignments.activeAssignments) {
      set.add(assignments.semesterOf(a));
    }
    final list = set.toList()..sort();
    return list;
  }

  List<AssignmentModel> get filtered {
    final q = query.trim().toLowerCase();
    return assignments.activeAssignments.where((a) {
      switch (segment) {
        case AssignmentSegment.individu:
          if (a.mode != AssignmentMode.individu) return false;
          break;
        case AssignmentSegment.kelompok:
          if (a.mode != AssignmentMode.kelompok) return false;
          break;
        case AssignmentSegment.mendesak:
          if (!assignments.isUrgent(a)) return false;
          break;
        case AssignmentSegment.semua:
          break;
      }
      final course = assignments.courseName(a);
      if (courseFilter != null && course != courseFilter) return false;
      if (semesterFilter != null && assignments.semesterOf(a) != semesterFilter) return false;
      if (statusFilter == 'Terlambat') {
        if (!assignments.isOverdue(a)) return false;
      } else if (statusFilter != 'Semua' && a.status.label != statusFilter) {
        return false;
      }
      if (q.isNotEmpty && !('${a.title} $course'.toLowerCase().contains(q))) return false;
      return true;
    }).toList();
  }

  void setSegment(AssignmentSegment v) {
    segment = v;
    _resetPaging();
    notifyListeners();
  }

  void setQuery(String v) {
    query = v;
    _resetPaging();
    notifyListeners();
  }

  void setCourse(String? v) {
    courseFilter = v;
    _resetPaging();
    notifyListeners();
  }

  void setSemester(int? v) {
    semesterFilter = v;
    _resetPaging();
    notifyListeners();
  }

  void setStatus(String v) {
    statusFilter = v;
    _resetPaging();
    notifyListeners();
  }

  void setGroupByCourse(bool v) {
    groupByCourse = v;
    notifyListeners();
  }

  void resetAdvancedFilter() {
    courseFilter = null;
    semesterFilter = null;
    statusFilter = 'Semua';
    groupByCourse = false;
    notifyListeners();
  }

  @override
  void dispose() {
    assignments.removeListener(notifyListeners);
    super.dispose();
  }
}
