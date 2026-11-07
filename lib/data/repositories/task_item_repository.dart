import 'package:flutter/foundation.dart';
import '../../domain/models/task_item.dart';
import '../services/supabase_collabnote_service.dart';

class TaskItemRepository extends ChangeNotifier {
  SupabaseCollabNoteService _service;

  TaskItemRepository(this._service);

  void updateService(SupabaseCollabNoteService newService) {
    _service = newService;
    notifyListeners();
  }

  Future<List<TaskItem>> getTasks() async {
    return await _service.fetchTaskItems();
  }

  Future<void> toggleTaskStatus(String id, bool currentStatus) async {
    // Balikkan status dari true ke false, atau false ke true
    await _service.updateTaskCompletion(id, !currentStatus);
    
    // Memberi tahu UI (Beranda & badge tab) untuk merender ulang sesuai instruksi tugas
    notifyListeners(); 
  }
}