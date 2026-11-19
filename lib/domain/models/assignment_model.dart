import 'model_utils.dart';

enum AssignmentMode { individu, kelompok }

extension AssignmentModeX on AssignmentMode {
  String get label => this == AssignmentMode.individu ? 'Individu' : 'Kelompok';
}

enum AssignmentPriority { tinggi, sedang, rendah }

extension AssignmentPriorityX on AssignmentPriority {
  String get label {
    switch (this) {
      case AssignmentPriority.tinggi:
        return 'Tinggi';
      case AssignmentPriority.sedang:
        return 'Sedang';
      case AssignmentPriority.rendah:
        return 'Rendah';
    }
  }
}

/// Status tersimpan. Status "Terlambat" TIDAK disimpan: dihitung otomatis dari deadline.
enum AssignmentStatus { belumDimulai, sedangDikerjakan, menungguPemeriksaan, selesai, diarsipkan }

extension AssignmentStatusX on AssignmentStatus {
  String get label {
    switch (this) {
      case AssignmentStatus.belumDimulai:
        return 'Belum Dimulai';
      case AssignmentStatus.sedangDikerjakan:
        return 'Sedang Dikerjakan';
      case AssignmentStatus.menungguPemeriksaan:
        return 'Menunggu Pemeriksaan';
      case AssignmentStatus.selesai:
        return 'Selesai';
      case AssignmentStatus.diarsipkan:
        return 'Diarsipkan';
    }
  }

  bool get isFinal => this == AssignmentStatus.selesai || this == AssignmentStatus.diarsipkan;
}

/// Penugasan = induk dari seluruh data pengerjaan (workspace, catatan, dokumen, dst).
class AssignmentModel {
  final String id;
  final String title;
  final String courseId;
  final String description;
  final AssignmentMode mode;
  final AssignmentPriority priority;
  final DateTime? assignedDate;
  final DateTime deadline;
  final String? templateId;
  final String? templateTitle;
  final AssignmentStatus status;
  final String workspaceId;
  final String? groupId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? archivedAt;

  const AssignmentModel({
    required this.id,
    required this.title,
    required this.courseId,
    required this.description,
    required this.mode,
    required this.priority,
    this.assignedDate,
    required this.deadline,
    this.templateId,
    this.templateTitle,
    required this.status,
    required this.workspaceId,
    this.groupId,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.archivedAt,
  });

  bool get isGroup => mode == AssignmentMode.kelompok;

  factory AssignmentModel.fromJson(Map<String, dynamic> json) => AssignmentModel(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        courseId: json['courseId'] as String? ?? '',
        description: json['description'] as String? ?? '',
        mode: enumFromName(AssignmentMode.values, json['mode'], AssignmentMode.individu),
        priority: enumFromName(AssignmentPriority.values, json['priority'], AssignmentPriority.sedang),
        assignedDate: parseDate(json['assignedDate']),
        deadline: parseDate(json['deadline']) ?? DateTime.now(),
        templateId: json['templateId'] as String?,
        templateTitle: json['templateTitle'] as String?,
        status: enumFromName(AssignmentStatus.values, json['status'], AssignmentStatus.belumDimulai),
        workspaceId: json['workspaceId'] as String? ?? '',
        groupId: json['groupId'] as String?,
        createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
        updatedAt: parseDate(json['updatedAt']) ?? DateTime.now(),
        completedAt: parseDate(json['completedAt']),
        archivedAt: parseDate(json['archivedAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'courseId': courseId,
        'description': description,
        'mode': mode.name,
        'priority': priority.name,
        'assignedDate': assignedDate?.toIso8601String(),
        'deadline': deadline.toIso8601String(),
        'templateId': templateId,
        'templateTitle': templateTitle,
        'status': status.name,
        'workspaceId': workspaceId,
        'groupId': groupId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'archivedAt': archivedAt?.toIso8601String(),
      };

  AssignmentModel copyWith({
    String? title,
    String? courseId,
    String? description,
    AssignmentPriority? priority,
    DateTime? assignedDate,
    bool clearAssignedDate = false,
    DateTime? deadline,
    String? templateId,
    String? templateTitle,
    AssignmentStatus? status,
    String? groupId,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
  }) =>
      AssignmentModel(
        id: id,
        title: title ?? this.title,
        courseId: courseId ?? this.courseId,
        description: description ?? this.description,
        mode: mode,
        priority: priority ?? this.priority,
        assignedDate: clearAssignedDate ? null : (assignedDate ?? this.assignedDate),
        deadline: deadline ?? this.deadline,
        templateId: templateId ?? this.templateId,
        templateTitle: templateTitle ?? this.templateTitle,
        status: status ?? this.status,
        workspaceId: workspaceId,
        groupId: groupId ?? this.groupId,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
        archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
      );
}
