import '../../domain/models/profile.dart';
import '../services/collab_note_service.dart';

class AuthRepository {
  final CollabNoteService _service;

  AuthRepository(this._service);

  bool get isLoggedIn => _service.isLoggedIn;

  String? get currentEmail => _service.currentUserEmail;

  Stream<bool> get authChanges => _service.authChanges;

  Future<void> login({
    required String email,
    required String password,
  }) {
    return _service.signIn(email: email, password: password);
  }

  /// true = langsung login, false = perlu konfirmasi email.
  Future<bool> register({
    required String fullName,
    required String studyProgram,
    required String email,
    required String password,
  }) {
    return _service.signUp(
      fullName: fullName,
      studyProgram: studyProgram,
      email: email,
      password: password,
    );
  }

  Future<void> logout() {
    return _service.signOut();
  }

  Future<Profile?> getProfile() {
    return _service.fetchProfile();
  }
}
