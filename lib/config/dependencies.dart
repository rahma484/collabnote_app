import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/services/supabase_collabnote_service.dart';
import '../data/repositories/project_note_repository.dart';
import '../data/repositories/task_item_repository.dart';
import '../data/repositories/project_update_repository.dart';

List<SingleChildWidget> get providers {
  return [
    // 1. Daftarkan Service
    Provider(create: (_) => SupabaseCollabNoteService()),

    // 2. Daftarkan Repositories dan suntikkan Service ke dalamnya
    ProxyProvider<SupabaseCollabNoteService, ProjectNoteRepository>(
      update: (_, service, _) => ProjectNoteRepository(service),
    ),

    // Khusus TaskItemRepository wajib jadi ChangeNotifier sesuai instruksi dosen
    ChangeNotifierProxyProvider<SupabaseCollabNoteService, TaskItemRepository>(
      create: (_) => TaskItemRepository(SupabaseCollabNoteService()),
      update: (_, service, previous) => previous!..updateService(service),
    ),

    ProxyProvider<SupabaseCollabNoteService, ProjectUpdateRepository>(
      update: (_, service, _) => ProjectUpdateRepository(service),
    ),
  ];
}
