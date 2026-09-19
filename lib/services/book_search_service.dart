import 'dart:convert';

import 'package:http/http.dart' as http;

/// Kitap aramasından dönen tek bir sonuç.
class BookSearchResult {
  final String title;
  final String authors;
  final String? thumbnailUrl;
  final String? description;
  final int pageCount;
  final String source; // hangi kaynaktan geldiği (kullanıcıya gösterilir)

  BookSearchResult({
    required this.title,
    required this.authors,
    this.thumbnailUrl,
    this.description,
    this.pageCount = 0,
    this.source = '',
  });
}

/// Birden fazla ücretsiz/anahtarsız kaynaktan kitap arar ve sonuçları
/// birleştirir: **Google Books + Open Library + Apple Books (iTunes)**.
///
/// Üç kaynak paralel sorgulanır; biri hata verirse (ör. Google'ın günlük
/// kotası dolarsa) diğerleri yine de sonuç döndürür. Sonuçlar başlık+yazara
/// göre tekilleştirilir; en zengin veriyi veren kaynak (Google) önceliklidir.
class BookSearchService {
  static const Duration _timeout = Duration(seconds: 12);

  Future<List<BookSearchResult>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final lists = await Future.wait([
      _safe(_searchGoogle(q)),
      _safe(_searchOpenLibrary(q)),
      _safe(_searchAppleBooks(q)),
    ]);

    return _merge(lists);
  }

  /// Hata veren kaynağı boş listeye çevirir (diğerleri etkilenmesin).
  Future<List<BookSearchResult>> _safe(Future<List<BookSearchResult>> f) async {
    try {
      return await f;
    } catch (_) {
      return const [];
    }
  }

  /// Kaynakları öncelik sırasıyla birleştirir, kopyaları eler.
  List<BookSearchResult> _merge(List<List<BookSearchResult>> lists) {
    final seen = <String>{};
    final out = <BookSearchResult>[];
    for (final list in lists) {
      for (final r in list) {
        if (seen.add(_dedupeKey(r))) out.add(r);
      }
    }
    return out.take(40).toList();
  }

  String _dedupeKey(BookSearchResult r) {
    String norm(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    return '${norm(r.title)}|${norm(r.authors.split(',').first)}';
  }

  // ---- Google Books (en zengin: açıklama + sayfa) ----
  Future<List<BookSearchResult>> _searchGoogle(String q) async {
    final uri = Uri.parse(
      'https://www.googleapis.com/books/v1/volumes'
      '?q=${Uri.encodeQueryComponent(q)}&maxResults=20&country=TR',
    );
    final res = await http.get(uri).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Google Books ${res.statusCode}');
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
      thumb = thumb?.replaceFirst('http://', 'https://');
      return BookSearchResult(
        title: info['title'] as String? ?? 'Başlıksız',
        authors: authors,
        thumbnailUrl: thumb,
        description: info['description'] as String?,
        pageCount: (info['pageCount'] as num?)?.toInt() ?? 0,
        source: 'Google Books',
      );
    }).toList();
  }

  // ---- Open Library (anahtarsız, kotasız) ----
  Future<List<BookSearchResult>> _searchOpenLibrary(String q) async {
    final uri = Uri.parse(
      'https://openlibrary.org/search.json'
      '?q=${Uri.encodeQueryComponent(q)}&limit=20'
      '&fields=title,author_name,cover_i,number_of_pages_median',
    );
    final res = await http.get(uri).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Open Library ${res.statusCode}');
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
        source: 'Open Library',
      );
    }).toList();
  }

  // ---- Apple Books / iTunes Search (anahtarsız, kotasız) ----
  Future<List<BookSearchResult>> _searchAppleBooks(String q) async {
    final uri = Uri.parse(
      'https://itunes.apple.com/search'
      '?term=${Uri.encodeQueryComponent(q)}&media=ebook&country=TR&limit=20',
    );
    final res = await http.get(uri).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Apple Books ${res.statusCode}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (data['results'] as List?) ?? const [];
    return results.map((raw) {
      final m = raw as Map<String, dynamic>;
      // 100x100 kapağı daha büyük sürümle değiştir.
      final art =
          (m['artworkUrl100'] as String?)?.replaceFirst('100x100bb', '400x400bb');
      return BookSearchResult(
        title: m['trackName'] as String? ?? 'Başlıksız',
        authors: m['artistName'] as String? ?? '',
        thumbnailUrl: art,
        description: m['description'] as String?,
        source: 'Apple Books',
      );
    }).toList();
  }
}
