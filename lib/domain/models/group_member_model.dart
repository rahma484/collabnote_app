import 'model_utils.dart';

enum MemberRole { pemilik, anggota }

extension MemberRoleX on MemberRole {
  String get label => this == MemberRole.pemilik ? 'Pemilik Kelompok' : 'Anggota';
}

enum MemberStatus { aktif, diundang }

extension MemberStatusX on MemberStatus {
  String get label => this == MemberStatus.aktif ? 'Aktif' : 'Menunggu Konfirmasi';
}

/// Anggota kelompok (disimulasikan lokal). [isMe] menandai pemilik aplikasi.
class GroupMemberModel {
  final String id;
  final String groupId;
  final String name;
  final MemberRole role;
  final MemberStatus status;
  final bool isMe;
  final String? userId;
  final DateTime joinedAt;

  const GroupMemberModel({
    required this.id,
    required this.groupId,
    required this.name,
    required this.role,
    required this.status,
    this.isMe = false,
    this.userId,
    required this.joinedAt,
  });

  bool get isOwner => role == MemberRole.pemilik;

  String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) => GroupMemberModel(
        id: json['id'] as String,
        groupId: json['groupId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        role: enumFromName(MemberRole.values, json['role'], MemberRole.anggota),
        status: enumFromName(MemberStatus.values, json['status'], MemberStatus.aktif),
        isMe: json['isMe'] as bool? ?? false,
        userId: json['userId'] as String?,
        joinedAt: DateTime.tryParse(json['joinedAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'name': name,
        'role': role.name,
        'status': status.name,
        'isMe': isMe,
        'userId': userId,
        'joinedAt': joinedAt.toIso8601String(),
      };

  GroupMemberModel copyWith({MemberStatus? status}) => GroupMemberModel(
        id: id,
        groupId: groupId,
        name: name,
        role: role,
        status: status ?? this.status,
        isMe: isMe,
        userId: userId,
        joinedAt: joinedAt,
      );
}
