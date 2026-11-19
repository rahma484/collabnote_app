/// Ruang Kerja. Setiap penugasan memiliki tepat satu workspace utama.
class WorkspaceModel {
  final String id;
  final String assignmentId;
  final String finalSummary; // ringkasan hasil pekerjaan (diisi saat finalisasi)
  final DateTime createdAt;

  const WorkspaceModel({
    required this.id,
    required this.assignmentId,
    this.finalSummary = '',
    required this.createdAt,
  });

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) => WorkspaceModel(
        id: json['id'] as String,
        assignmentId: json['assignmentId'] as String,
        finalSummary: json['finalSummary'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'assignmentId': assignmentId,
        'finalSummary': finalSummary,
        'createdAt': createdAt.toIso8601String(),
      };

  WorkspaceModel copyWith({String? finalSummary}) => WorkspaceModel(
        id: id,
        assignmentId: assignmentId,
        finalSummary: finalSummary ?? this.finalSummary,
        createdAt: createdAt,
      );
}
