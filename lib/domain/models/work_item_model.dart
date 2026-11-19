import 'model_utils.dart';

enum WorkStatus { todo, inProgress, review, done }

extension WorkStatusX on WorkStatus {
  String get label {
    switch (this) {
      case WorkStatus.todo:
        return 'To Do';
      case WorkStatus.inProgress:
        return 'In Progress';
      case WorkStatus.review:
        return 'Review';
      case WorkStatus.done:
        return 'Done';
    }
  }
}

/// Bagian pekerjaan pada mode kelompok. Wajib punya penanggung jawab ([assigneeId]).
class WorkItemModel {
  final String id;
  final String groupId;
  final String assignmentId;
  final String title;
  final String description;
  final String assigneeId;
  final DateTime deadline;
  final WorkStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? attachmentPath;
  final String? attachmentName;

  const WorkItemModel({
    required this.id,
    required this.groupId,
    required this.assignmentId,
    required this.title,
    required this.description,
    required this.assigneeId,
    required this.deadline,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.attachmentPath,
    this.attachmentName,
  });

  factory WorkItemModel.fromJson(Map<String, dynamic> json) => WorkItemModel(
        id: json['id'] as String,
        groupId: json['groupId'] as String? ?? '',
        assignmentId: json['assignmentId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        assigneeId: json['assigneeId'] as String? ?? '',
        deadline: DateTime.tryParse(json['deadline'] as String? ?? '') ?? DateTime.now(),
        status: enumFromName(WorkStatus.values, json['status'], WorkStatus.todo),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
        attachmentPath: json['attachmentPath'] as String?,
        attachmentName: json['attachmentName'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'assignmentId': assignmentId,
        'title': title,
        'description': description,
        'assigneeId': assigneeId,
        'deadline': deadline.toIso8601String(),
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'attachmentPath': attachmentPath,
        'attachmentName': attachmentName,
      };

  WorkItemModel copyWith({
    String? title,
    String? description,
    String? assigneeId,
    DateTime? deadline,
    WorkStatus? status,
    DateTime? updatedAt,
    String? attachmentPath,
    String? attachmentName,
    bool clearAttachment = false,
  }) =>
      WorkItemModel(
        id: id,
        groupId: groupId,
        assignmentId: assignmentId,
        title: title ?? this.title,
        description: description ?? this.description,
        assigneeId: assigneeId ?? this.assigneeId,
        deadline: deadline ?? this.deadline,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        attachmentPath: clearAttachment ? null : (attachmentPath ?? this.attachmentPath),
        attachmentName: clearAttachment ? null : (attachmentName ?? this.attachmentName),
      );
}
