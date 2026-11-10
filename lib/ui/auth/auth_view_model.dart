import 'package:flutter/foundation.dart';

import '../../data/repositories/auth_repository.dart';
import '../../domain/models/profile.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  AuthViewModel(this._repository);

  bool _disposed = false;

  bool isLoading = false;
  String? error;

  Profile? profile;

  /// true jika setelah daftar Supabase meminta konfirmasi email.
  bool needsEmailConfirmation = false;

  String? get email => _repository.currentEmail;

  /// Memuat profil (Nama & Prodi) dari tabel `profiles`.
  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      profile = await _repository.getProfile();
    } catch (e) {
      error = _clean(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _repository.login(email: email, password: password);
      return true;
    } catch (e) {
      error = _clean(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String fullName,
    required String studyProgram,
    required String email,
    required String password,
  }) async {
    isLoading = true;
    error = null;
    needsEmailConfirmation = false;
    notifyListeners();

    try {
      final signedIn = await _repository.register(
        fullName: fullName,
        studyProgram: studyProgram,
        email: email,
        password: password,
      );

      needsEmailConfirmation = !signedIn;
      return true;
    } catch (e) {
      error = _clean(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> logout() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _repository.logout();
      return true;
    } catch (e) {
      error = _clean(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _clean(Object e) {
    return e.toString().replaceFirst('Exception: ', '');
  }

  // Setelah login berhasil, layar login langsung digantikan oleh
  // AppShell sehingga ViewModel bisa ter-dispose sebelum `finally` jalan.
  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
