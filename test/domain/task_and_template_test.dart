import 'package:collabnote_app/domain/models/project_template.dart';
import 'package:collabnote_app/domain/models/task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Task', () {
    final json = {
      'id': 't1',
      'project_id': 'p1',
      'title': 'Desain wireframe',
      'assignee': 'Rahma',
      'status': 'In Progress',
      'is_completed': false,
      'created_at': '2026-11-01T08:00:00Z',
    };

    test('fromJson() membaca semua field', () {
      final task = Task.fromJson(json);

      expect(task.id, 't1');
      expect(task.projectId, 'p1');
      expect(task.assignee, 'Rahma');
      expect(task.status, 'In Progress');
      expect(task.isCompleted, isFalse);
    });

    test('copyWith() hanya mengubah field yang diberikan', () {
      final task = Task.fromJson(json);
      final done = task.copyWith(status: 'Done', isCompleted: true);

      expect(done.isCompleted, isTrue);
      expect(done.status, 'Done');
      expect(done.title, task.title);
      expect(done.id, task.id);
    });
  });

  group('ProjectTemplate', () {
    test('setiap template punya tugas default', () {
      for (final template in ProjectTemplate.all) {
        expect(template.defaultTasks, isNotEmpty);
      }
    });

    test('byCategory() jatuh ke template General jika tidak dikenal', () {
      expect(
        ProjectTemplate.byCategory('Tidak ada').category,
        ProjectTemplate.general,
      );
    });
  });
}
