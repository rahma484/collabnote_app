import 'package:flutter/foundation.dart';

import '../../data/repositories/assignment_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/models/assignment_model.dart';

/// ViewModel Beranda: hanya merangkum data dari repository (tidak mengelola data).
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required this.assignments, required this.profile}) {
    assignments.addListener(notifyListeners);
    profile.addListener(notifyListeners);
  }

  final AssignmentRepository assignments;
  final ProfileRepository profile;

  bool isLoading = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await Future.wait([profile.load(), assignments.load()]);
    } catch (e) {
      error = 'Gagal memuat Beranda: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Tarik-untuk-memuat-ulang: membaca ulang profil dan penugasan dari sumber data.
  Future<void> refresh() async {
    try {
      await Future.wait([profile.load(force: true), assignments.load(force: true)]);
      error = null;
    } catch (e) {
      error = 'Gagal memuat Beranda: $e';
    }
    notifyListeners();
  }

  /// Jumlah deadline (penugasan belum selesai) untuk 7 hari ke depan, mulai hari ini.
  List<int> get weekCounts {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final counts = List<int>.filled(7, 0);
    for (final a in assignments.assignments.where((a) => !a.status.isFinal)) {
      final d = DateTime(a.deadline.year, a.deadline.month, a.deadline.day);
      final diff = d.difference(start).inDays;
      if (diff >= 0 && diff < 7) counts[diff]++;
    }
    return counts;
  }

  List<String> get weekLabels {
    const names = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    final today = DateTime.now();
    return [for (var i = 0; i < 7; i++) i == 0 ? 'Hari ini' : names[today.add(Duration(days: i)).weekday % 7]];
  }

  String get userFirstName => profile.user.firstName;

  int get total => assignments.totalCount;
  int get notStarted => assignments.notStartedCount;
  int get inProgress => assignments.inProgressCount;
  int get completed => assignments.completedCount;
  int get overdue => assignments.overdueCount;

  bool get isEmpty => assignments.totalCount == 0;

  /// Tiga deadline terdekat dari penugasan yang belum selesai.
  List<AssignmentModel> get upcoming =>
      assignments.assignments.where((a) => !a.status.isFinal).take(3).toList();

  /// Penugasan terbaru (belum diarsipkan), berdasarkan waktu pembaruan.
  List<AssignmentModel> get recent {
    final list = assignments.activeAssignments;
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list.take(3).toList();
  }

  /// Pekerjaan yang perlu segera dikerjakan (gabungan tahapan individu + bagian kelompok).
  List<PendingAction> get actions => assignments.pendingActions().take(5).toList();

  /// Pengingat deadline (preferensi di Profil): deadline <= 2 hari atau terlambat.
  List<AssignmentModel> get reminders {
    if (!profile.user.deadlineReminder) return const [];
    return assignments.assignments.where((a) => !a.status.isFinal && assignments.daysLeft(a) <= 2).toList();
  }
}
