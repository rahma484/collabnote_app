import 'model_utils.dart';

enum ReviewStatus { pending, approved, revision }

extension ReviewStatusX on ReviewStatus {
  String get label {
    switch (this) {
      case ReviewStatus.pending:
        return 'Belum Diperiksa';
      case ReviewStatus.approved:
        return 'Approved';
      case ReviewStatus.revision:
        return 'Revision';
    }
  }
}

/// Hasil pekerjaan yang dikumpulkan anggota untuk satu bagian pekerjaan.
class SubmissionModel {
  final String id;
  final String workItemId;
  final String groupId;
  final String memberId;
  final String fileName;
  final String? localPath;
  final String note;
  final DateTime submittedAt;
  final ReviewStatus reviewStatus;
  final String reviewNote;

  const SubmissionModel({
    required this.id,
    required this.workItemId,
    required this.groupId,
    required this.memberId,
    required this.fileName,
    this.localPath,
    this.note = '',
    required this.submittedAt,
    this.reviewStatus = ReviewStatus.pending,
    this.reviewNote = '',
  });

  String get extension {
    final i = fileName.lastIndexOf('.');
    return i < 0 ? '' : fileName.substring(i + 1).toLowerCase();
  }

  factory SubmissionModel.fromJson(Map<String, dynamic> json) => SubmissionModel(
        id: json['id'] as String,
        workItemId: json['workItemId'] as String? ?? '',
        groupId: json['groupId'] as String? ?? '',
        memberId: json['memberId'] as String? ?? '',
        fileName: json['fileName'] as String? ?? '',
        localPath: json['localPath'] as String?,
        note: json['note'] as String? ?? '',
        submittedAt: DateTime.tryParse(json['submittedAt'] as String? ?? '') ?? DateTime.now(),
        reviewStatus: enumFromName(ReviewStatus.values, json['reviewStatus'], ReviewStatus.pending),
        reviewNote: json['reviewNote'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'workItemId': workItemId,
        'groupId': groupId,
        'memberId': memberId,
        'fileName': fileName,
        'localPath': localPath,
        'note': note,
        'submittedAt': submittedAt.toIso8601String(),
        'reviewStatus': reviewStatus.name,
        'reviewNote': reviewNote,
      };

  SubmissionModel copyWith({ReviewStatus? reviewStatus, String? reviewNote}) => SubmissionModel(
        id: id,
        workItemId: workItemId,
        groupId: groupId,
        memberId: memberId,
        fileName: fileName,
        localPath: localPath,
        note: note,
        submittedAt: submittedAt,
        reviewStatus: reviewStatus ?? this.reviewStatus,
        reviewNote: reviewNote ?? this.reviewNote,
      );
}
