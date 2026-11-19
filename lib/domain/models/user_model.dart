/// Identitas pemilik aplikasi + preferensi sederhana (data Profil).
class UserModel {
  final String id;
  final String name;
  final String nim;
  final String university;
  final String faculty;
  final String studyProgram;
  final int semester;
  final String? photoPath;

  /// Preferensi notifikasi: tampilkan pengingat deadline di Beranda.
  final bool deadlineReminder;

  /// Preferensi tampilan: 0 = kecil, 1 = normal, 2 = besar.
  final int textSize;

  const UserModel({
    required this.id,
    required this.name,
    required this.nim,
    required this.university,
    required this.faculty,
    required this.studyProgram,
    required this.semester,
    this.photoPath,
    this.deadlineReminder = true,
    this.textSize = 1,
  });

  String get firstName {
    final parts = name.trim().split(' ');
    return parts.isEmpty || parts.first.isEmpty ? 'Mahasiswa' : parts.first;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        nim: json['nim'] as String? ?? '',
        university: json['university'] as String? ?? '',
        faculty: json['faculty'] as String? ?? '',
        studyProgram: json['studyProgram'] as String? ?? '',
        semester: (json['semester'] as num?)?.toInt() ?? 1,
        photoPath: json['photoPath'] as String?,
        deadlineReminder: json['deadlineReminder'] as bool? ?? true,
        textSize: (json['textSize'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nim': nim,
        'university': university,
        'faculty': faculty,
        'studyProgram': studyProgram,
        'semester': semester,
        'photoPath': photoPath,
        'deadlineReminder': deadlineReminder,
        'textSize': textSize,
      };

  UserModel copyWith({
    String? name,
    String? nim,
    String? university,
    String? faculty,
    String? studyProgram,
    int? semester,
    String? photoPath,
    bool clearPhoto = false,
    bool? deadlineReminder,
    int? textSize,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        nim: nim ?? this.nim,
        university: university ?? this.university,
        faculty: faculty ?? this.faculty,
        studyProgram: studyProgram ?? this.studyProgram,
        semester: semester ?? this.semester,
        photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
        deadlineReminder: deadlineReminder ?? this.deadlineReminder,
        textSize: textSize ?? this.textSize,
      );
}
