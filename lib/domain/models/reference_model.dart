import 'model_utils.dart';

enum ReferenceType { jurnal, website, buku, dokumentasi, materi }

extension ReferenceTypeX on ReferenceType {
  String get label {
    switch (this) {
      case ReferenceType.jurnal:
        return 'Jurnal';
      case ReferenceType.website:
        return 'Website';
      case ReferenceType.buku:
        return 'Buku';
      case ReferenceType.dokumentasi:
        return 'Dokumentasi';
      case ReferenceType.materi:
        return 'Materi Pendukung';
    }
  }
}

/// Referensi (tautan jurnal, website, buku, dokumentasi, materi).
class ReferenceModel {
  final String id;
  final String workspaceId;
  final String assignmentId;
  final String title;
  final String url;
  final ReferenceType type;
  final String note;
  final DateTime createdAt;

  const ReferenceModel({
    required this.id,
    required this.workspaceId,
    required this.assignmentId,
    required this.title,
    required this.url,
    required this.type,
    this.note = '',
    required this.createdAt,
  });

  factory ReferenceModel.fromJson(Map<String, dynamic> json) => ReferenceModel(
        id: json['id'] as String,
        workspaceId: json['workspaceId'] as String? ?? '',
        assignmentId: json['assignmentId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        url: json['url'] as String? ?? '',
        type: enumFromName(ReferenceType.values, json['type'], ReferenceType.website),
        note: json['note'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'workspaceId': workspaceId,
        'assignmentId': assignmentId,
        'title': title,
        'url': url,
        'type': type.name,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  ReferenceModel copyWith({String? title, String? url, ReferenceType? type, String? note}) => ReferenceModel(
        id: id,
        workspaceId: workspaceId,
        assignmentId: assignmentId,
        title: title ?? this.title,
        url: url ?? this.url,
        type: type ?? this.type,
        note: note ?? this.note,
        createdAt: createdAt,
      );
}
