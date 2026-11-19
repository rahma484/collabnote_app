import 'package:collab_note/data/repositories/archive_repository.dart';
import 'package:collab_note/data/repositories/assignment_repository.dart';
import 'package:collab_note/data/repositories/group_repository.dart';
import 'package:collab_note/data/repositories/task_step_repository.dart';
import 'package:collab_note/data/repositories/workspace_repository.dart';
import 'package:collab_note/data/services/collab_note_service.dart';
import 'package:collab_note/data/services/local_file_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tes progres: mencentang tahapan harus mengubah progres penugasan individu.
void main() {
  test('toggle tahapan mengubah progres penugasan a1', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final service = CollabNoteService();
    final files = LocalFileService();
    final steps = TaskStepRepository(service);
    final repo = AssignmentRepository(
      service,
      steps,
      WorkspaceRepository(service, files),
      GroupRepository(service, files),
      ArchiveRepository(service),
    );
    await steps.load();
    await repo.load();

    final a1 = repo.byId('a1')!;
    final before = repo.progressOf(a1);
    final pending = steps.stepsOf('a1').firstWhere((s) => !s.isDone);
    await steps.toggle(pending.id);
    expect(repo.progressOf(repo.byId('a1')!), greaterThan(before));
  });
}
