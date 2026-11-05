import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 4. Real-Time Task Board (To Do, In Progress, Done)
class TaskBoardScreen extends StatefulWidget {
  final String projectId;
  const TaskBoardScreen({super.key, required this.projectId});

  @override
  State<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends State<TaskBoardScreen> {
  // Stream realtime dari tabel tasks Supabase
  late final Stream<List<Map<String, dynamic>>> _tasksStream;

  @override
  void initState() {
    super.initState();
    // Sinkronisasi Real-Time: Ketika rekan tim mengubah status tugas di HP mereka,
    // tampilan berubah seketika tanpa perlu refresh halaman!
    _tasksStream = Supabase.instance.client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('project_id', widget.projectId)
        .order('created_at');
  }

  Future<void> _updateTaskStatus(String taskId, String newStatus) async {
    await Supabase.instance.client
        .from('tasks')
        .update({'status': newStatus})
        .eq('id', taskId);
  }

  Future<void> _addNewTask(String title, String assignee) async {
    await Supabase.instance.client.from('tasks').insert({
      'project_id': widget.projectId,
      'title': title,
      'assignee_name': assignee,
      'status': 'todo', // default To Do
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _tasksStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final allTasks = snapshot.data!;

        final todoList = allTasks.where((t) => t['status'] == 'todo').toList();
        final inProgressList = allTasks.where((t) => t['status'] == 'in_progress').toList();
        final doneList = allTasks.where((t) => t['status'] == 'done').toList();

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _buildStatusColumn('To Do (Belum Dikerjakan)', todoList, Colors.amber, 'in_progress'),
            _buildStatusColumn('In Progress (Sedang Dikerjakan)', inProgressList, Colors.blue, 'done'),
            _buildStatusColumn('Done (Sudah Selesai)', doneList, Colors.green, 'todo'),
          ],
        );
      },
    );
  }

  Widget _buildStatusColumn(String title, List<Map<String, dynamic>> tasks, Color color, String nextStatus) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$title (${tasks.length})', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            const Divider(),
            ...tasks.map((task) => ListTile(
              title: Text(task['title']),
              subtitle: Text('PIC: ${task['assignee_name'] ?? 'Belum ada'}'),
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: () => _updateTaskStatus(task['id'], nextStatus),
              ),
            )),
          ],
        ),
      ),
    );
  }
}