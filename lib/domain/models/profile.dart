class Profile {
  final String id;
  final String fullName;
  final String studyProgram;

  const Profile({
    required this.id,
    required this.fullName,
    required this.studyProgram,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      studyProgram: json['study_program'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'study_program': studyProgram,
    };
  }
}
