class Project {
  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final String category;
  final String projectType;
  final DateTime? deadline;
  final DateTime createdAt;

  const Project({
    required this.id,
    required this.ownerId,
    required this.title,
    this.description,
    required this.category,
    required this.projectType,
    this.deadline,
    required this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      projectType: json['project_type'] as String? ?? 'Individual',
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'category': category,
      'project_type': projectType,
      'deadline': deadline?.toIso8601String().split('T').first,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
