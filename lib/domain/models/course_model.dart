/// Mata kuliah. Setiap penugasan terhubung ke satu mata kuliah lewat [id].
class CourseModel {
  final String id;
  final String name;
  final int semester;
  final String academicYear; // contoh: 2026/2027

  const CourseModel({
    required this.id,
    required this.name,
    required this.semester,
    required this.academicYear,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        semester: (json['semester'] as num?)?.toInt() ?? 1,
        academicYear: json['academicYear'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'semester': semester,
        'academicYear': academicYear,
      };

  CourseModel copyWith({String? name, int? semester, String? academicYear}) => CourseModel(
        id: id,
        name: name ?? this.name,
        semester: semester ?? this.semester,
        academicYear: academicYear ?? this.academicYear,
      );
}
