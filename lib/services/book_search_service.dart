import 'dart:convert';

import 'package:http/http.dart' as http;

/// Google Books aramasından dönen tek bir sonuç.
class BookSearchResult {
  final String title;
  final String authors;
  final String? thumbnailUrl;
  final String? description;
  final int pageCount;

  BookSearchResult({
    required this.title,
    required this.authors,
    this.thumbnailUrl,
    this.description,
    this.pageCount = 0,
  });
}

/// Google Books API üzerinden kitap arar (ücretsiz, API anahtarı gerektirmez).
class BookSearchService {
  static const String _base = 'https://www.googleapis.com/books/v1/volumes';

  Future<List<BookSearchResult>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final uri = Uri.parse(
      '$_base?q=${Uri.encodeQueryComponent(q)}&maxResults=20&country=TR',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Arama başarısız (${res.statusCode})');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data['items'] as List?) ?? const [];

    return items.map((raw) {
      final info =
          (raw as Map<String, dynamic>)['volumeInfo'] as Map<String, dynamic>? ??
              const {};
      final authors =
          (info['authors'] as List?)?.cast<String>().join(', ') ?? '';
      var thumb =
          (info['imageLinks'] as Map<String, dynamic>?)?['thumbnail'] as String?;
      // Android http (cleartext) trafiğini engellediği için https'e çevir.
      thumb = thumb?.replaceFirst('http://', 'https://');

      return BookSearchResult(
        title: info['title'] as String? ?? 'Başlıksız',
        authors: authors,
        thumbnailUrl: thumb,
        description: info['description'] as String?,
        pageCount: (info['pageCount'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }
}
