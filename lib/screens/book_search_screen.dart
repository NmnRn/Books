import 'package:flutter/material.dart';

import '../data/app_repository.dart';
import '../models/book.dart';
import '../services/book_search_service.dart';
import '../widgets/book_cover.dart';

/// Google Books üzerinden kitap arayıp kütüphaneye ekleme ekranı.
class BookSearchScreen extends StatefulWidget {
  const BookSearchScreen({super.key});

  @override
  State<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  final _service = BookSearchService();
  final _controller = TextEditingController();

  List<BookSearchResult> _results = [];
  bool _loading = false;
  String? _message = 'Kitap adı, yazar veya ISBN yazıp ara.';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _message = null;
      _results = [];
    });
    try {
      final r = await _service.search(q);
      if (!mounted) return;
      setState(() {
        _results = r;
        _loading = false;
        _message = r.isEmpty ? 'Sonuç bulunamadı.' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = 'Bağlantı hatası. İnternetini kontrol et.';
      });
    }
  }

  Future<void> _addResult(BookSearchResult r) async {
    final status = await _pickStatus();
    if (status == null || !mounted) return;
    final repo = AppRepository.instance;
    await repo.addBook(Book(
      id: repo.newId(),
      title: r.title,
      authors: r.authors,
      thumbnailUrl: r.thumbnailUrl,
      description: r.description,
      pageCount: r.pageCount,
      currentPage: status == ReadingStatus.read ? r.pageCount : 0,
      status: status,
      finishedAt: status == ReadingStatus.read ? DateTime.now() : null,
    ));
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('"${r.title}" eklendi')));
  }

  Future<ReadingStatus?> _pickStatus() {
    return showModalBottomSheet<ReadingStatus>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nereye eklensin?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_add_outlined),
              title: const Text('Okunacaklar'),
              onTap: () => Navigator.pop(ctx, ReadingStatus.toRead),
            ),
            ListTile(
              leading: const Icon(Icons.auto_stories_outlined),
              title: const Text('Şu an okuyorum'),
              onTap: () => Navigator.pop(ctx, ReadingStatus.reading),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Okudum'),
              onTap: () => Navigator.pop(ctx, ReadingStatus.read),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _manualAdd() async {
    final titleC = TextEditingController();
    final authorC = TextEditingController();
    final pagesC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elle kitap ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleC,
                decoration: const InputDecoration(labelText: 'Kitap adı')),
            TextField(
                controller: authorC,
                decoration: const InputDecoration(labelText: 'Yazar')),
            TextField(
              controller: pagesC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sayfa sayısı'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ekle')),
        ],
      ),
    );
    if (ok != true) return;
    final title = titleC.text.trim();
    if (title.isEmpty || !mounted) return;
    final repo = AppRepository.instance;
    await repo.addBook(Book(
      id: repo.newId(),
      title: title,
      authors: authorC.text.trim(),
      pageCount: int.tryParse(pagesC.text.trim()) ?? 0,
    ));
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('"$title" eklendi')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitap Ara'),
        actions: [
          IconButton(
            onPressed: _manualAdd,
            icon: const Icon(Icons.edit_note),
            tooltip: 'Elle ekle',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Kitap adı, yazar veya ISBN',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _search,
                ),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: _message != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_message!, textAlign: TextAlign.center),
                    ),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final r = _results[i];
                      final subtitle = [
                        if (r.authors.isNotEmpty) r.authors,
                        if (r.pageCount > 0) '${r.pageCount} sayfa',
                      ].join(' • ');
                      return ListTile(
                        leading:
                            BookCover(url: r.thumbnailUrl, width: 40, height: 58),
                        title: Text(r.title,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: subtitle.isEmpty
                            ? null
                            : Text(subtitle,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => _addResult(r),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
