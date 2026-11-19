import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_widgets.dart';
import 'profile_screen.dart';
import 'profile_view_model.dart';

class EditProfileScreen extends StatefulWidget {
  final ProfileViewModel viewModel;

  const EditProfileScreen({super.key, required this.viewModel});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _nim;
  late final TextEditingController _university;
  late final TextEditingController _faculty;
  late final TextEditingController _program;
  late int _semester;

  @override
  void initState() {
    super.initState();
    final u = widget.viewModel.user;
    _name = TextEditingController(text: u.name);
    _nim = TextEditingController(text: u.nim);
    _university = TextEditingController(text: u.university);
    _faculty = TextEditingController(text: u.faculty);
    _program = TextEditingController(text: u.studyProgram);
    _semester = u.semester;
  }

  @override
  void dispose() {
    _name.dispose();
    _nim.dispose();
    _university.dispose();
    _faculty.dispose();
    _program.dispose();
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = widget.viewModel;
    await vm.save(vm.user.copyWith(
      name: _name.text.trim(),
      nim: _nim.text.trim(),
      university: _university.text.trim(),
      faculty: _faculty.text.trim(),
      studyProgram: _program.text.trim(),
      semester: _semester,
    ));
    if (!mounted) return;
    Navigator.pop(context);
    showSnack(context, 'Profil disimpan.');
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          children: [
            ListenableBuilder(
              listenable: vm,
              builder: (context, _) => Column(
                children: [
                  ProfileAvatar(name: _name.text, photoPath: vm.user.photoPath, heroTag: 'profile-avatar'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final ok = await vm.changePhoto();
                          if (ok && context.mounted) showSnack(context, 'Foto profil diperbarui.');
                        },
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Ganti Foto'),
                      ),
                      if (vm.user.photoPath != null)
                        TextButton(
                          onPressed: vm.removePhoto,
                          child: const Text('Hapus Foto', style: TextStyle(color: AppColors.danger)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            LabeledField(label: 'Nama Mahasiswa', controller: _name, validator: _required),
            LabeledField(label: 'NIM', controller: _nim, keyboardType: TextInputType.number, validator: _required),
            LabeledField(label: 'Universitas', controller: _university, validator: _required),
            LabeledField(label: 'Fakultas', controller: _faculty, validator: _required),
            LabeledField(label: 'Program Studi', controller: _program, validator: _required),
            const Text('Semester', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              initialValue: _semester,
              items: [for (var s = 1; s <= 14; s++) DropdownMenuItem(value: s, child: Text('Semester $s'))],
              onChanged: (v) => setState(() => _semester = v ?? _semester),
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Simpan Profil', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
