class Task {
  final String id;
  final String projectId;
  final String title;
  final String? assignee;
  final String status;
  final bool isCompleted;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.projectId,
    required this.title,
    this.assignee,
    required this.status,
    required this.isCompleted,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      title: json['title'] as String,
      assignee: json['assignee'] as String?,
      status: json['status'] as String? ?? 'To Do',
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'title': title,
      'assignee': assignee,
      'status': status,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Task copyWith({
    String? id,
    String? projectId,
    String? title,
    String? assignee,
    String? status,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      assignee: assignee ?? this.assignee,
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
