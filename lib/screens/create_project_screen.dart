import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 3. Smart Template Universal
class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedTemplate = 'software'; // default

  final List<Map<String, dynamic>> _templates = [
    {
      'id': 'software',
      'title': 'Software / App Development',
      'tasks': [
        {'title': 'Inisialisasi Project Flutter & Supabase', 'status': 'done'},
        {'title': 'Rancang UI/UX di Figma', 'status': 'in_progress'},
        {'title': 'Testing API & Database Integration', 'status': 'todo'},
      ],
      'notes': '# 💻 Blueprint Software Development\n## Tech Stack\n- Flutter\n- Supabase\n## Milestone UTS\n- Auth & Task Board'
    },
    {
      'id': 'business',
      'title': 'Business Plan & Startup',
      'tasks': [
        {'title': 'Mengisi 9 Blok Business Model Canvas', 'status': 'done'},
        {'title': 'Wawancara Validasi Calon Customer', 'status': 'in_progress'},
        {'title': 'Susun Slide Pitch Deck', 'status': 'todo'},
      ],
      'notes': '# 🚀 Blueprint Business Plan\n## Value Proposition\nSolusi smart journaling mahasiswa.'
    },
    {
      'id': 'academic',
      'title': 'Makalah, Proposal, & Riset Ilmiah',
      'tasks': [
        {'title': 'Latar Belakang & Identifikasi Masalah', 'status': 'done'},
        {'title': 'Kumpulkan 10 Jurnal Internasional', 'status': 'in_progress'},
        {'title': 'Metodologi Penelitian', 'status': 'todo'},
      ],
      'notes': '# 📚 Blueprint Makalah & Riset\n## Bab 1 Pendahuluan\n## Bab 2 Tinjauan Pustaka'
    },
    {
      'id': 'creative',
      'title': 'Creative, Media, / Desain',
      'tasks': [
        {'title': 'Moodboard & Visual Asset', 'status': 'done'},
        {'title': 'Storyboard Video / Animasi', 'status': 'in_progress'},
        {'title': 'Finishing & Rendering', 'status': 'todo'},
      ],
      'notes': '# 🎨 Blueprint Media & Desain\n## Moodboard & Deliverables'
    },
    {
      'id': 'general',
      'title': 'Catatan Bebas / General',
      'tasks': [
        {'title': 'Rangkum Kisi-kisi UTS', 'status': 'todo'},
        {'title': 'Latihan Soal Ujian', 'status': 'todo'},
      ],
      'notes': '# 📝 Catatan Bebas Proyek'
    },
  ];

  Future<void> _saveProject() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final template = _templates.firstWhere((t) => t['id'] == _selectedTemplate);

    // 1. Simpan proyek ke tabel projects di Supabase
    final projectRes = await Supabase.instance.client.from('projects').insert({
      'title': title,
      'description': _descController.text.trim(),
      'category': _selectedTemplate,
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    final projectId = projectRes['id'];

    // 2. Sistem otomatis membuat struktur catatan default (workspace notes)
    await Supabase.instance.client.from('project_notes').insert({
      'project_id': projectId,
      'title': 'Blueprint ${template['title']}',
      'content': template['notes'],
      'updated_at': DateTime.now().toIso8601String(),
    });

    // 3. Sistem otomatis membuat default tasks agar pengguna tidak mulai dari halaman kosong
    final tasksList = (template['tasks'] as List).map((t) => {
      'project_id': projectId,
      'title': t['title'],
      'status': t['status'],
      'priority': 'high',
      'created_at': DateTime.now().toIso8601String(),
    }).toList();

    await Supabase.instance.client.from('tasks').insert(tasksList);

    // 4. Arahkan kembali ke Home Dashboard
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Proyek Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Judul Proyek')),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Deskripsi Singkat')),
            const SizedBox(height: 20),
            const Text('Pilih Template Universal:', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._templates.map((tmpl) => RadioListTile<String>(
              value: tmpl['id'],
              groupValue: _selectedTemplate,
              title: Text(tmpl['title']),
              onChanged: (val) => setState(() => _selectedTemplate = val!),
            )),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveProject, child: const Text('Simpan & Generate Otomatis')),
          ],
        ),
      ),
    );
  }
}