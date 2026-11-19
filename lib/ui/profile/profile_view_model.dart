import 'package:flutter/foundation.dart';

import '../../data/repositories/group_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/services/collab_note_service.dart';
import '../../data/services/local_file_service.dart';
import '../../domain/models/user_model.dart';

/// ViewModel Profil: identitas, preferensi notifikasi/tampilan, dan reset data contoh.
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    required this.profile,
    required this.groups,
    required this.service,
    required this.files,
    required this.reloadAll,
  }) {
    profile.addListener(notifyListeners);
  }

  final ProfileRepository profile;
  final GroupRepository groups;
  final CollabNoteService service;
  final LocalFileService files;

  /// Memuat ulang semua repository (diisi oleh AppShell).
  final Future<void> Function() reloadAll;

  bool isLoading = false;
  String? error;

  UserModel get user => profile.user;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await profile.load();
    } catch (e) {
      error = 'Gagal memuat profil: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> save(UserModel updated) async {
    await profile.update(updated);
    await groups.renameCurrentUser(updated.name);
  }

  Future<void> setReminder(bool value) => profile.update(user.copyWith(deadlineReminder: value));

  Future<void> setTextSize(int size) => profile.update(user.copyWith(textSize: size));

  /// Memilih foto profil; disalin ke folder aplikasi supaya tidak hilang.
  Future<bool> changePhoto() async {
    final picked = await files.pickFile(imageOnly: true);
    if (picked == null) return false;
    final path = await files.saveBytes(picked.name, picked.bytes);
    await files.delete(user.photoPath);
    await profile.update(user.copyWith(photoPath: path));
    return true;
  }

  Future<void> removePhoto() async {
    await files.delete(user.photoPath);
    await profile.update(user.copyWith(clearPhoto: true));
  }

  Future<bool> joinGroup(String code) async {
    final joined = await service.joinGroupByCode(code);
    if (joined) await groups.load(force: true);
    return joined;
  }

  Future<void> resetSampleData() async {
    await service.resetToSampleData();
    await reloadAll();
  }

  @override
  void dispose() {
    profile.removeListener(notifyListeners);
    super.dispose();
  }
}
