/// Catatan (pribadi pada mode individu, bersama pada mode kelompok).
class NoteModel {
  final String id;
  final String workspaceId;
  final String assignmentId;
  final String title;
  final String content;
  final String authorName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteModel({
    required this.id,
    required this.workspaceId,
    required this.assignmentId,
    required this.title,
    required this.content,
    this.authorName = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel(
        id: json['id'] as String,
        workspaceId: json['workspaceId'] as String? ?? '',
        assignmentId: json['assignmentId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        authorName: json['authorName'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'workspaceId': workspaceId,
        'assignmentId': assignmentId,
        'title': title,
        'content': content,
        'authorName': authorName,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  NoteModel copyWith({String? title, String? content, DateTime? updatedAt}) => NoteModel(
        id: id,
        workspaceId: workspaceId,
        assignmentId: assignmentId,
        title: title ?? this.title,
        content: content ?? this.content,
        authorName: authorName,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
