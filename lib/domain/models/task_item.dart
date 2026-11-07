class TaskItem {
  final String id;
  final String title;
  final bool isCompleted;

  TaskItem({
    required this.id,
    required this.title,
    required this.isCompleted,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'],
      title: json['title'],
      // Supabase mengirim boolean, default false jika null
      isCompleted: json['isCompleted'] ?? false, 
    );
  }

  // Wajib untuk update state lokal sebelum dikirim ke database
  TaskItem copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}