import 'model_utils.dart';

enum TemplateCategory { it, design, business, academic, custom }

extension TemplateCategoryX on TemplateCategory {
  String get label {
    switch (this) {
      case TemplateCategory.it:
        return 'Information Technology';
      case TemplateCategory.design:
        return 'Design & Creative';
      case TemplateCategory.business:
        return 'Business & Entrepreneurship';
      case TemplateCategory.academic:
        return 'Academic & General';
      case TemplateCategory.custom:
        return 'Template Saya';
    }
  }

  String get shortLabel {
    switch (this) {
      case TemplateCategory.it:
        return 'IT';
      case TemplateCategory.design:
        return 'Design';
      case TemplateCategory.business:
        return 'Business';
      case TemplateCategory.academic:
        return 'Academic';
      case TemplateCategory.custom:
        return 'Saya';
    }
  }
}

/// Template = file nyata (assetPath untuk bawaan, localPath untuk file milik sendiri).
class TemplateModel {
  final String id;
  final TemplateCategory category;
  final String title;
  final String format; // DOCX, XLSX, PPTX, MD, Diagram, Template Visual
  final String extension;
  final String description;
  final String usage;
  final String assetPath;
  final String? localPath;
  final List<String> previewLines;

  const TemplateModel({
    required this.id,
    required this.category,
    required this.title,
    required this.format,
    required this.extension,
    required this.description,
    required this.usage,
    this.assetPath = '',
    this.localPath,
    this.previewLines = const [],
  });

  bool get isCustom => category == TemplateCategory.custom;

  String get fileName => '$title.$extension';

  factory TemplateModel.fromJson(Map<String, dynamic> json) => TemplateModel(
        id: json['id'] as String,
        category: enumFromName(TemplateCategory.values, json['category'], TemplateCategory.custom),
        title: json['title'] as String? ?? '',
        format: json['format'] as String? ?? '',
        extension: json['extension'] as String? ?? '',
        description: json['description'] as String? ?? '',
        usage: json['usage'] as String? ?? '',
        assetPath: json['assetPath'] as String? ?? '',
        localPath: json['localPath'] as String?,
        previewLines: parseStringList(json['previewLines']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'title': title,
        'format': format,
        'extension': extension,
        'description': description,
        'usage': usage,
        'assetPath': assetPath,
        'localPath': localPath,
        'previewLines': previewLines,
      };
}
