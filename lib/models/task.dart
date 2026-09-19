import 'dart:convert';

/// Yapılacaklar listesindeki bir görev.
/// İsteğe bağlı zaman, not ve fotoğraf içerebilir.
class Task {
  final String id;
  String title;
  bool done;
  DateTime? dueAt;
  String? note;
  String? imagePath; // cihazdaki yerel fotoğraf yolu
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.done = false,
    this.dueAt,
    this.note,
    this.imagePath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'done': done,
        'dueAt': dueAt?.toIso8601String(),
        'note': note,
        'imagePath': imagePath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: map['id'] as String,
        title: map['title'] as String? ?? '',
        done: map['done'] as bool? ?? false,
        dueAt: map['dueAt'] != null ? DateTime.tryParse(map['dueAt'] as String) : null,
        note: map['note'] as String?,
        imagePath: map['imagePath'] as String?,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
      );

  String toJson() => jsonEncode(toMap());

  factory Task.fromJson(String source) =>
      Task.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
