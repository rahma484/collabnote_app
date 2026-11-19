/// Kelompok pada penugasan mode kelompok.
class GroupModel {
  final String id;
  final String assignmentId;
  final String name;
  final String inviteCode;
  final DateTime createdAt;

  const GroupModel({
    required this.id,
    required this.assignmentId,
    required this.name,
    required this.inviteCode,
    required this.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) => GroupModel(
        id: json['id'] as String,
        assignmentId: json['assignmentId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        inviteCode: json['inviteCode'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'assignmentId': assignmentId,
        'name': name,
        'inviteCode': inviteCode,
        'createdAt': createdAt.toIso8601String(),
      };

  GroupModel copyWith({String? name}) => GroupModel(
        id: id,
        assignmentId: assignmentId,
        name: name ?? this.name,
        inviteCode: inviteCode,
        createdAt: createdAt,
      );
}
