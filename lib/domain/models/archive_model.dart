import 'assignment_model.dart';
import 'model_utils.dart';

/// Satu baris riwayat penyelesaian pada arsip.
class ArchiveEvent {
  final DateTime date;
  final String text;

  const ArchiveEvent({required this.date, required this.text});

  factory ArchiveEvent.fromJson(Map<String, dynamic> json) => ArchiveEvent(
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        text: json['text'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'date': date.toIso8601String(), 'text': text};
}

/// Data informasi: arsip penugasan yang sudah selesai dan dikonfirmasi.
/// Dokumen, catatan, dan referensi TIDAK disalin; tetap terhubung lewat [assignmentId].
class ArchiveModel {
  final String id;
  final String assignmentId;
  final String title;
  final String courseName;
  final int semester;
  final String academicYear;
  final AssignmentMode mode;
  final DateTime? assignedDate;
  final DateTime deadline;
  final DateTime completedAt;
  final DateTime archivedAt;
  final List<String> memberNames;
  final String? templateTitle;
  final String summary;
  final List<ArchiveEvent> history;

  const ArchiveModel({
    required this.id,
    required this.assignmentId,
    required this.title,
    required this.courseName,
    required this.semester,
    required this.academicYear,
    required this.mode,
    this.assignedDate,
    required this.deadline,
    required this.completedAt,
    required this.archivedAt,
    this.memberNames = const [],
    this.templateTitle,
    this.summary = '',
    this.history = const [],
  });

  factory ArchiveModel.fromJson(Map<String, dynamic> json) => ArchiveModel(
        id: json['id'] as String,
        assignmentId: json['assignmentId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        courseName: json['courseName'] as String? ?? '',
        semester: (json['semester'] as num?)?.toInt() ?? 1,
        academicYear: json['academicYear'] as String? ?? '',
        mode: enumFromName(AssignmentMode.values, json['mode'], AssignmentMode.individu),
        assignedDate: parseDate(json['assignedDate']),
        deadline: parseDate(json['deadline']) ?? DateTime.now(),
        completedAt: parseDate(json['completedAt']) ?? DateTime.now(),
        archivedAt: parseDate(json['archivedAt']) ?? DateTime.now(),
        memberNames: parseStringList(json['memberNames']),
        templateTitle: json['templateTitle'] as String?,
        summary: json['summary'] as String? ?? '',
        history: (json['history'] is List)
            ? (json['history'] as List)
                .map((e) => ArchiveEvent.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList()
            : const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'assignmentId': assignmentId,
        'title': title,
        'courseName': courseName,
        'semester': semester,
        'academicYear': academicYear,
        'mode': mode.name,
        'assignedDate': assignedDate?.toIso8601String(),
        'deadline': deadline.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'archivedAt': archivedAt.toIso8601String(),
        'memberNames': memberNames,
        'templateTitle': templateTitle,
        'summary': summary,
        'history': history.map((e) => e.toJson()).toList(),
      };

  ArchiveModel copyWith({String? summary}) => ArchiveModel(
        id: id,
        assignmentId: assignmentId,
        title: title,
        courseName: courseName,
        semester: semester,
        academicYear: academicYear,
        mode: mode,
        assignedDate: assignedDate,
        deadline: deadline,
        completedAt: completedAt,
        archivedAt: archivedAt,
        memberNames: memberNames,
        templateTitle: templateTitle,
        summary: summary ?? this.summary,
        history: history,
      );
}
