class ProjectUpdate {
  final String id;
  final String info;
  final String author;

  ProjectUpdate({required this.id, required this.info, required this.author});

  factory ProjectUpdate.fromJson(Map<String, dynamic> json) {
    return ProjectUpdate(
      id: json['id'],
      info: json['info'],
      author: json['author'],
    );
  }
}
