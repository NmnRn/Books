import 'dart:convert';

/// Bir kitabın okuma durumu.
enum ReadingStatus { toRead, reading, read }

extension ReadingStatusLabel on ReadingStatus {
  String get label {
    switch (this) {
      case ReadingStatus.toRead:
        return 'Okunacak';
      case ReadingStatus.reading:
        return 'Okunuyor';
      case ReadingStatus.read:
        return 'Okundu';
    }
  }
}

/// Kütüphanedeki bir kitap. Bilgiler Google Books'tan otomatik doldurulur.
class Book {
  final String id;
  String title;
  String authors;
  String? thumbnailUrl;
  String? description;
  int pageCount;
  int currentPage;
  ReadingStatus status;
  int dailyGoalMinutes;
  final DateTime addedAt;
  DateTime? finishedAt;

  Book({
    required this.id,
    required this.title,
    this.authors = '',
    this.thumbnailUrl,
    this.description,
    this.pageCount = 0,
    this.currentPage = 0,
    this.status = ReadingStatus.toRead,
    this.dailyGoalMinutes = 0,
    DateTime? addedAt,
    this.finishedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  /// 0.0 – 1.0 arası okuma ilerlemesi.
  double get progress {
    if (pageCount <= 0) return status == ReadingStatus.read ? 1 : 0;
    return (currentPage / pageCount).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'authors': authors,
        'thumbnailUrl': thumbnailUrl,
        'description': description,
        'pageCount': pageCount,
        'currentPage': currentPage,
        'status': status.index,
        'dailyGoalMinutes': dailyGoalMinutes,
        'addedAt': addedAt.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
      };

  factory Book.fromMap(Map<String, dynamic> map) => Book(
        id: map['id'] as String,
        title: map['title'] as String? ?? '',
        authors: map['authors'] as String? ?? '',
        thumbnailUrl: map['thumbnailUrl'] as String?,
        description: map['description'] as String?,
        pageCount: (map['pageCount'] as num?)?.toInt() ?? 0,
        currentPage: (map['currentPage'] as num?)?.toInt() ?? 0,
        status: ReadingStatus.values[(map['status'] as num?)?.toInt() ?? 0],
        dailyGoalMinutes: (map['dailyGoalMinutes'] as num?)?.toInt() ?? 0,
        addedAt: DateTime.tryParse(map['addedAt'] as String? ?? ''),
        finishedAt: map['finishedAt'] != null
            ? DateTime.tryParse(map['finishedAt'] as String)
            : null,
      );

  String toJson() => jsonEncode(toMap());

  factory Book.fromJson(String source) =>
      Book.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
