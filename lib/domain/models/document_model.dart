import 'model_utils.dart';

/// instruksi = lampiran dari dosen, draft = dokumen kerja, finalDoc = hasil akhir, attachment = lampiran lain.
enum DocumentKind { instruction, draft, finalDoc, attachment }

extension DocumentKindX on DocumentKind {
  String get label {
    switch (this) {
      case DocumentKind.instruction:
        return 'Instruksi';
      case DocumentKind.draft:
        return 'Draft';
      case DocumentKind.finalDoc:
        return 'Final';
      case DocumentKind.attachment:
        return 'Lampiran';
    }
  }
}

/// Asal dokumen: dari template, dibuat di aplikasi, diunggah, atau hasil penggabungan kelompok.
enum DocumentSource { template, created, uploaded, merged }

/// Dokumen di Ruang Kerja. Isinya berasal dari salah satu: textContent, localPath, atau assetPath.
class DocumentModel {
  final String id;
  final String workspaceId;
  final String assignmentId;
  final String title;
  final String fileName;
  final String extension;
  final DocumentKind kind;
  final DocumentSource source;
  final String? textContent;
  final String? localPath;
  final String? assetPath;
  final String? templateId;
  final int size;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DocumentModel({
    required this.id,
    required this.workspaceId,
    required this.assignmentId,
    required this.title,
    required this.fileName,
    required this.extension,
    required this.kind,
    required this.source,
    this.textContent,
    this.localPath,
    this.assetPath,
    this.templateId,
    this.size = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isFinal => kind == DocumentKind.finalDoc;

  /// Hanya dokumen teks (.md/.txt) yang dapat diedit di dalam aplikasi.
  bool get isEditableInApp => textContent != null;

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
        id: json['id'] as String,
        workspaceId: json['workspaceId'] as String? ?? '',
        assignmentId: json['assignmentId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        fileName: json['fileName'] as String? ?? '',
        extension: json['extension'] as String? ?? '',
        kind: enumFromName(DocumentKind.values, json['kind'], DocumentKind.draft),
        source: enumFromName(DocumentSource.values, json['source'], DocumentSource.created),
        textContent: json['textContent'] as String?,
        localPath: json['localPath'] as String?,
        assetPath: json['assetPath'] as String?,
        templateId: json['templateId'] as String?,
        size: (json['size'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'workspaceId': workspaceId,
        'assignmentId': assignmentId,
        'title': title,
        'fileName': fileName,
        'extension': extension,
        'kind': kind.name,
        'source': source.name,
        'textContent': textContent,
        'localPath': localPath,
        'assetPath': assetPath,
        'templateId': templateId,
        'size': size,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  DocumentModel copyWith({
    String? title,
    String? fileName,
    String? extension,
    DocumentKind? kind,
    String? textContent,
    String? localPath,
    int? size,
    DateTime? updatedAt,
  }) =>
      DocumentModel(
        id: id,
        workspaceId: workspaceId,
        assignmentId: assignmentId,
        title: title ?? this.title,
        fileName: fileName ?? this.fileName,
        extension: extension ?? this.extension,
        kind: kind ?? this.kind,
        source: source,
        textContent: textContent ?? this.textContent,
        localPath: localPath ?? this.localPath,
        assetPath: assetPath,
        templateId: templateId,
        size: size ?? this.size,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
