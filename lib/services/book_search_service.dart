import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/app_repository.dart';

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
/// birleştirir:
///   * Google Books   (en zengin; anahtar varsa kotasız)
///   * Open Library   (anahtarsız, kotasız)
///   * Internet Archive (archive.org; Türkçe kapsamı iyi)
///   * Apple Books    (iTunes; zayıf, en sonda)
///
/// Kaynaklar paralel sorgulanır; biri hata verse (ör. Google kotası) diğerleri
/// yine sonuç döndürür. Sonuçlar başlık+yazara göre tekilleştirilir.
class BookSearchService {
  static const Duration _timeout = Duration(seconds: 12);

  /// Derleme zamanı varsayılanı (`--dart-define=GOOGLE_BOOKS_API_KEY=...`).
  static const String _envKey = String.fromEnvironment('GOOGLE_BOOKS_API_KEY');

  /// Etkin anahtar: önce kullanıcının Ayarlar'dan girdiği, yoksa derleme
  /// zamanı verilen; ikisi de boşsa anahtarsız (paylaşılan kota → sık 429).
  String get _googleKey {
    final runtime = AppRepository.instance.googleApiKey;
    return runtime.isNotEmpty ? runtime : _envKey;
  }

  Future<List<BookSearchResult>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    // Öncelik sırası = birleştirme sırası.
    final lists = await Future.wait([
      _safe(_searchGoogle(q)),
      _safe(_searchOpenLibrary(q)),
      _safe(_searchArchive(q)),
      _safe(_searchAppleBooks(q)),
    ]);

    return _merge(lists);
  }

  Future<List<BookSearchResult>> _safe(Future<List<BookSearchResult>> f) async {
    try {
      return await f;
    } catch (_) {
      return const [];
    }
  }

  List<BookSearchResult> _merge(List<List<BookSearchResult>> lists) {
    final seen = <String>{};
    final out = <BookSearchResult>[];
    for (final list in lists) {
      for (final r in list) {
        if (seen.add(_dedupeKey(r))) out.add(r);
      }
    }
    return out.take(50).toList();
  }

  String _dedupeKey(BookSearchResult r) {
    String norm(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    return '${norm(r.title)}|${norm(r.authors.split(',').first)}';
  }

  // ---- Google Books ----
  Future<List<BookSearchResult>> _searchGoogle(String q) async {
    final keyParam = _googleKey.isNotEmpty ? '&key=$_googleKey' : '';
    final uri = Uri.parse(
      'https://www.googleapis.com/books/v1/volumes'
      '?q=${Uri.encodeQueryComponent(q)}&maxResults=20&country=TR$keyParam',
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

  // ---- Open Library ----
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

  // ---- Internet Archive (archive.org) ----
  Future<List<BookSearchResult>> _searchArchive(String q) async {
    final query = Uri.encodeQueryComponent('title:($q) AND mediatype:texts');
    final uri = Uri.parse(
      'https://archive.org/advancedsearch.php?q=$query'
      '&fl%5B%5D=identifier&fl%5B%5D=title&fl%5B%5D=creator'
      '&rows=15&output=json',
    );
    final res = await http.get(uri).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Archive ${res.statusCode}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final docs =
        ((data['response'] as Map<String, dynamic>?)?['docs'] as List?) ??
            const [];
    return docs
        .map((raw) {
          final doc = raw as Map<String, dynamic>;
          final id = doc['identifier'] as String? ?? '';
          final rawTitle = doc['title'];
          final title = rawTitle is List
              ? (rawTitle.isNotEmpty ? rawTitle.first.toString() : 'Başlıksız')
              : (rawTitle as String? ?? 'Başlıksız');
          final rawCreator = doc['creator'];
          var author = rawCreator is List
              ? rawCreator.cast<String>().join(', ')
              : (rawCreator as String? ?? '');
          if (author.length > 60) author = ''; // etiket çöplüğünü ele
          return BookSearchResult(
            title: title,
            authors: author,
            thumbnailUrl:
                id.isNotEmpty ? 'https://archive.org/services/img/$id' : null,
            source: 'Internet Archive',
          );
        })
        .where((r) => r.title.isNotEmpty)
        .toList();
  }

  // ---- Apple Books / iTunes Search ----
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
