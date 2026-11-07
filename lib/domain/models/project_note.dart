class ProjectNote {
  final String id;
  final String title;
  final String category;
  final String date;

  ProjectNote({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
  });

  factory ProjectNote.fromJson(Map<String, dynamic> json) {
    return ProjectNote(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      date: json['date'],
    );
  }
}