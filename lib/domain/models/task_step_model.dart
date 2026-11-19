/// Tahapan pengerjaan (data aksi): dapat dicentang selesai.
class TaskStepModel {
  final String id;
  final String workspaceId;
  final String assignmentId;
  final String title;
  final bool isDone;
  final int order;
  final DateTime createdAt;
  final DateTime? completedAt;

  const TaskStepModel({
    required this.id,
    required this.workspaceId,
    required this.assignmentId,
    required this.title,
    this.isDone = false,
    this.order = 0,
    required this.createdAt,
    this.completedAt,
  });

  factory TaskStepModel.fromJson(Map<String, dynamic> json) => TaskStepModel(
        id: json['id'] as String,
        workspaceId: json['workspaceId'] as String? ?? '',
        assignmentId: json['assignmentId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        isDone: json['isDone'] as bool? ?? false,
        order: (json['order'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'workspaceId': workspaceId,
        'assignmentId': assignmentId,
        'title': title,
        'isDone': isDone,
        'order': order,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  TaskStepModel copyWith({
    String? title,
    bool? isDone,
    int? order,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) =>
      TaskStepModel(
        id: id,
        workspaceId: workspaceId,
        assignmentId: assignmentId,
        title: title ?? this.title,
        isDone: isDone ?? this.isDone,
        order: order ?? this.order,
        createdAt: createdAt,
        completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      );
}
