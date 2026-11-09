class AssetLink {
  final String id;
  final String projectId;
  final String title;
  final String url;
  final String category;
  final DateTime createdAt;

  const AssetLink({
    required this.id,
    required this.projectId,
    required this.title,
    required this.url,
    required this.category,
    required this.createdAt,
  });

  factory AssetLink.fromJson(Map<String, dynamic> json) {
    return AssetLink(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'title': title,
      'url': url,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
