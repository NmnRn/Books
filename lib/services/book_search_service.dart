import 'dart:convert';

import 'package:http/http.dart' as http;

/// Kitap aramasından dönen tek bir sonuç.
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

/// Kitap arar. Önce Google Books (daha zengin veri: açıklama vb.),
/// başarısız olursa veya sonuç boşsa Open Library'ye düşer.
///
/// Google Books anahtarsız kullanımda paylaşılan bir günlük kotaya tabidir
/// ve sık sık 429 döndürür; Open Library ise anahtarsız ve kotasızdır.
/// Bu ikili yapı aramanın her zaman çalışmasını sağlar.
class BookSearchService {
  Future<List<BookSearchResult>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    try {
      final google = await _searchGoogle(q);
      if (google.isNotEmpty) return google;
    } catch (_) {
      // Kota/ağ hatası — Open Library'ye düş.
    }
    return _searchOpenLibrary(q);
  }

  // ---- Google Books ----
  Future<List<BookSearchResult>> _searchGoogle(String q) async {
    final uri = Uri.parse(
      'https://www.googleapis.com/books/v1/volumes'
      '?q=${Uri.encodeQueryComponent(q)}&maxResults=20&country=TR',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Google Books ${res.statusCode}');
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
      // Android http (cleartext) engellediği için https'e çevir.
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

  // ---- Open Library (yedek) ----
  Future<List<BookSearchResult>> _searchOpenLibrary(String q) async {
    final uri = Uri.parse(
      'https://openlibrary.org/search.json'
      '?q=${Uri.encodeQueryComponent(q)}&limit=20'
      '&fields=title,author_name,cover_i,number_of_pages_median',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Open Library ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final docs = (data['docs'] as List?) ?? const [];
    return docs.map((raw) {
      final doc = raw as Map<String, dynamic>;
      final authors =
          (doc['author_name'] as List?)?.cast<String>().join(', ') ?? '';
      final coverId = (doc['cover_i'] as num?)?.toInt();
      final thumb = coverId != null
          ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
          : null;
      return BookSearchResult(
        title: doc['title'] as String? ?? 'Başlıksız',
        authors: authors,
        thumbnailUrl: thumb,
        pageCount: (doc['number_of_pages_median'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }
}
