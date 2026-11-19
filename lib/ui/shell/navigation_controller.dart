import 'package:flutter/foundation.dart';

/// Menyimpan tab yang aktif dan permintaan membuka Ruang Kerja sebuah penugasan.
class NavigationController extends ChangeNotifier {
  int _index = 0;
  String? _pendingWorkspaceId;

  int get index => _index;

  void goTo(int index) {
    _index = index;
    notifyListeners();
  }

  /// Pindah ke tab Ruang Kerja dan membuka ruang kerja penugasan [assignmentId].
  void openWorkspace(String assignmentId) {
    _pendingWorkspaceId = assignmentId;
    _index = 2;
    notifyListeners();
  }

  /// Dibaca satu kali oleh AppShell lalu dikosongkan.
  String? consumeWorkspaceRequest() {
    final id = _pendingWorkspaceId;
    _pendingWorkspaceId = null;
    return id;
  }
}
