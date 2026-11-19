import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/assignment_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/template_repository.dart';
import '../../data/services/local_file_service.dart';
import '../../domain/models/assignment_model.dart';
import '../../domain/models/template_model.dart';
import '../core/app_colors.dart';
import '../core/app_widgets.dart';
import '../core/formatters.dart';
import '../shell/navigation_controller.dart';
import '../templates/template_gallery_screen.dart';

/// Membuka form "Buat Penugasan Baru". Setelah tersimpan, pindah ke tab Penugasan
/// dan menawarkan tombol untuk membuka Ruang Kerja yang baru dibuat.
Future<void> startCreateAssignment(BuildContext context) async {
  final nav = context.read<NavigationController>();
  final id = await pushSlideUp<String>(context, const AssignmentFormScreen());
  if (id == null || !context.mounted) return;
  nav.goTo(1);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: const Text('Penugasan disimpan. Ruang Kerja sudah dibuat.'),
      action: SnackBarAction(label: 'Buka', textColor: Colors.white, onPressed: () => nav.openWorkspace(id)),
    ));
}

/// Form tambah / edit penugasan. Mengembalikan ID penugasan saat berhasil disimpan.
class AssignmentFormScreen extends StatefulWidget {
  final String? editId;

  const AssignmentFormScreen({super.key, this.editId});

  @override
  State<AssignmentFormScreen> createState() => _AssignmentFormScreenState();
}

class _AssignmentFormScreenState extends State<AssignmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _course = TextEditingController();
  final _description = TextEditingController();
  final _assignedText = TextEditingController();
  final _deadlineText = TextEditingController();
  final _groupName = TextEditingController();

  DateTime? _assigned;
  DateTime? _deadline;
  AssignmentPriority _priority = AssignmentPriority.sedang;
  AssignmentMode _mode = AssignmentMode.individu;
  int _semester = 1;
  TemplateModel? _template;
  final List<PickedFileData> _attachments = [];
  bool _saving = false;

  bool get _isEdit => widget.editId != null;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileRepository>().user;
    _semester = profile.semester;
    if (_isEdit) {
      final repo = context.read<AssignmentRepository>();
      final a = repo.byId(widget.editId!);
      if (a != null) {
        _title.text = a.title;
        _course.text = repo.courseName(a);
        _semester = repo.semesterOf(a) == 0 ? _semester : repo.semesterOf(a);
        _description.text = a.description;
        _assigned = a.assignedDate;
        _deadline = a.deadline;
        _priority = a.priority;
        _mode = a.mode;
        if (_assigned != null) _assignedText.text = formatDate(_assigned!);
        _deadlineText.text = formatDate(a.deadline);
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _course.dispose();
    _description.dispose();
    _assignedText.dispose();
    _deadlineText.dispose();
    _groupName.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isDeadline}) async {
    final now = DateTime.now();
    final initial = (isDeadline ? _deadline : _assigned) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (isDeadline) {
        _deadline = picked;
        _deadlineText.text = formatDate(picked);
      } else {
        _assigned = picked;
        _assignedText.text = formatDate(picked);
      }
    });
  }

  Future<void> _pickTemplate() async {
    final t = await pushSlideUp<TemplateModel>(context, const TemplateGalleryScreen());
    if (t != null) setState(() => _template = t);
  }

  Future<void> _pickAttachment() async {
    final file = await context.read<LocalFileService>().pickFile();
    if (file != null) setState(() => _attachments.add(file));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = context.read<AssignmentRepository>();
    final profile = context.read<ProfileRepository>().user;
    setState(() => _saving = true);
    try {
      String id;
      if (_isEdit) {
        await repo.update(
          id: widget.editId!,
          title: _title.text,
          courseName: _course.text,
          semester: _semester,
          description: _description.text,
          priority: _priority,
          assignedDate: _assigned,
          deadline: _deadline!,
        );
        id = widget.editId!;
      } else {
        final created = await repo.create(
          title: _title.text,
          courseName: _course.text,
          semester: _semester,
          description: _description.text,
          mode: _mode,
          priority: _priority,
          assignedDate: _assigned,
          deadline: _deadline!,
          template: _template,
          groupName: _groupName.text,
          ownerName: profile.name,
          instructionFiles: _attachments,
        );
        id = created.id;
        if (_template != null && mounted) {
          await context.read<TemplateRepository>().markUsed(_template!.id);
        }
      }
      if (mounted) Navigator.pop(context, id);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showSnack(context, 'Gagal menyimpan: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AssignmentRepository>();
    final courseNames = repo.courses.map((c) => c.name).toList();

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Penugasan' : 'Buat Penugasan Baru')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            LabeledField(
              label: 'Nama Penugasan',
              controller: _title,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama penugasan wajib diisi' : null,
            ),
            LabeledField(
              label: 'Mata Kuliah',
              controller: _course,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Mata kuliah wajib diisi' : null,
            ),
            if (courseNames.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final name in courseNames)
                      ActionChip(
                        label: Text(name, style: const TextStyle(fontSize: 12)),
                        backgroundColor: AppColors.chip,
                        side: BorderSide.none,
                        onPressed: () => setState(() {
                          _course.text = name;
                          final c = repo.courses.firstWhere((c) => c.name == name);
                          _semester = c.semester;
                        }),
                      ),
                  ],
                ),
              ),
            const Text('Semester', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              initialValue: _semester,
              items: [for (var s = 1; s <= 14; s++) DropdownMenuItem(value: s, child: Text('Semester $s'))],
              onChanged: (v) => setState(() => _semester = v ?? _semester),
            ),
            const SizedBox(height: 14),
            LabeledField(label: 'Deskripsi/Instruksi', controller: _description, maxLines: 4),
            LabeledField(
              label: 'Tanggal Diberikan (opsional)',
              controller: _assignedText,
              readOnly: true,
              onTap: () => _pickDate(isDeadline: false),
              suffix: _assigned == null
                  ? const Icon(Icons.calendar_today_outlined, size: 20)
                  : IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => setState(() {
                        _assigned = null;
                        _assignedText.clear();
                      }),
                    ),
            ),
            LabeledField(
              label: 'Tanggal Tenggat',
              controller: _deadlineText,
              readOnly: true,
              onTap: () => _pickDate(isDeadline: true),
              suffix: const Icon(Icons.calendar_today_outlined, size: 20),
              validator: (v) => (v == null || v.isEmpty) ? 'Tanggal tenggat wajib dipilih' : null,
            ),
            const Text('Prioritas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final p in AssignmentPriority.values)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: p == AssignmentPriority.rendah ? 0 : 8),
                      child: PressableScale(
                        onTap: () => setState(() => _priority = p),
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _priority == p ? AppColors.mocca : AppColors.field,
                            border: Border.all(color: AppColors.beige),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            p.label,
                            style: TextStyle(
                              color: _priority == p ? Colors.white : AppColors.brown,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Mode Pengerjaan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Row(
              children: [
                Switch(
                  value: _mode == AssignmentMode.individu,
                  onChanged: _isEdit ? null : (_) => setState(() => _mode = AssignmentMode.individu),
                ),
                const Text('Individu'),
                const SizedBox(width: 18),
                Switch(
                  value: _mode == AssignmentMode.kelompok,
                  onChanged: _isEdit ? null : (_) => setState(() => _mode = AssignmentMode.kelompok),
                ),
                const Text('Kelompok'),
              ],
            ),
            if (_isEdit)
              const Padding(
                padding: EdgeInsets.only(top: 2, bottom: 6),
                child: Text('Mode pengerjaan tidak dapat diubah setelah penugasan dibuat.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ),
            if (!_isEdit && _mode == AssignmentMode.kelompok) ...[
              const SizedBox(height: 10),
              LabeledField(
                label: 'Nama Kelompok',
                controller: _groupName,
                hint: 'Contoh: Tim Wirausaha Muda',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama kelompok wajib diisi' : null,
              ),
              const Text(
                'Anda menjadi Pemilik Kelompok. Kode undangan dibuat otomatis dan dapat dibagikan dari Ruang Kerja.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
            if (!_isEdit) ...[
              const SizedBox(height: 18),
              const Text('Template (opsional)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              PressableScale(
                onTap: _pickTemplate,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.beige)),
                  child: Row(
                    children: [
                      Icon(_template == null ? Icons.note_add_outlined : templateIcon(_template!.format), color: AppColors.mocca),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _template == null ? 'Mulai dari Kosong (ketuk untuk memilih template)' : '${_template!.title} (${_template!.format})',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (_template != null)
                        IconButton(
                          tooltip: 'Mulai dari kosong',
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _template = null),
                        )
                      else
                        const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Lampiran Instruksi (opsional)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              for (var i = 0; i < _attachments.length; i++)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.attach_file, color: AppColors.mocca),
                  title: Text(_attachments[i].name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(formatSize(_attachments[i].bytes.length)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _attachments.removeAt(i)),
                  ),
                ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brown,
                  side: const BorderSide(color: AppColors.mocca),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _pickAttachment,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Tambah Lampiran'),
              ),
            ],
            const SizedBox(height: 26),
            PrimaryButton(
              label: _saving ? 'Menyimpan...' : 'Simpan Penugasan',
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
