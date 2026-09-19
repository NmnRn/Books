import 'package:flutter/material.dart';

import '../data/app_repository.dart';
import '../models/book.dart';
import '../widgets/book_cover.dart';

/// Kitap detay/düzenleme ekranı. Durum, sayfa ilerlemesi ve hedefi yönetir.
class BookDetailScreen extends StatelessWidget {
  final String bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;
    return ValueListenableBuilder<List<Book>>(
      valueListenable: repo.books,
      builder: (context, books, _) {
        final idx = books.indexWhere((b) => b.id == bookId);
        if (idx == -1) {
          // Kitap silinmiş olabilir.
          return const Scaffold(body: SizedBox.shrink());
        }
        return _DetailView(book: books[idx]);
      },
    );
  }
}

class _DetailView extends StatelessWidget {
  final Book book;
  const _DetailView({required this.book});

  AppRepository get _repo => AppRepository.instance;

  void _adjustPage(int delta) {
    var next = book.currentPage + delta;
    if (next < 0) next = 0;
    if (book.pageCount > 0 && next > book.pageCount) next = book.pageCount;
    book.currentPage = next;
    if (book.pageCount > 0 && next >= book.pageCount) {
      book.status = ReadingStatus.read;
      book.finishedAt ??= DateTime.now();
    } else if (book.status == ReadingStatus.toRead && next > 0) {
      book.status = ReadingStatus.reading;
    }
    _repo.updateBook(book);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitap Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Sil',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(url: book.thumbnailUrl, width: 90, height: 130),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    if (book.authors.isNotEmpty)
                      Text(book.authors,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Durum', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<ReadingStatus>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ReadingStatus.toRead, label: Text('Okunacak')),
              ButtonSegment(value: ReadingStatus.reading, label: Text('Okunuyor')),
              ButtonSegment(value: ReadingStatus.read, label: Text('Okundu')),
            ],
            selected: {book.status},
            onSelectionChanged: (s) {
              book.status = s.first;
              if (book.status == ReadingStatus.read && book.pageCount > 0) {
                book.currentPage = book.pageCount;
                book.finishedAt ??= DateTime.now();
              }
              _repo.updateBook(book);
            },
          ),
          const SizedBox(height: 24),
          Text('İlerleme', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          if (book.pageCount > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: book.progress, minHeight: 10),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              Text(
                '${book.currentPage} / ${book.pageCount > 0 ? book.pageCount : "?"} sayfa',
                style: theme.textTheme.bodyLarge,
              ),
              const Spacer(),
              if (book.pageCount > 0)
                Text('%${(book.progress * 100).round()}',
                    style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                  onPressed: () => _adjustPage(-10), child: const Text('-10')),
              const SizedBox(width: 8),
              OutlinedButton(
                  onPressed: () => _adjustPage(-1), child: const Text('-1')),
              const Spacer(),
              OutlinedButton(
                  onPressed: () => _adjustPage(1), child: const Text('+1')),
              const SizedBox(width: 8),
              FilledButton(
                  onPressed: () => _adjustPage(10), child: const Text('+10')),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Sayfaları düzenle'),
              onPressed: () => _editPages(context),
            ),
          ),
          const Divider(height: 32),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Günlük okuma hedefi'),
            trailing: Text(
                book.dailyGoalMinutes > 0 ? '${book.dailyGoalMinutes} dk' : 'Yok'),
            onTap: () async {
              final v = await _promptNumber(
                  context, 'Günlük hedef (dakika)', book.dailyGoalMinutes);
              if (v != null) {
                book.dailyGoalMinutes = v < 0 ? 0 : v;
                _repo.updateBook(book);
              }
            },
          ),
          if (book.description != null && book.description!.isNotEmpty) ...[
            const Divider(height: 32),
            Text('Açıklama', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(book.description!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kitabı sil'),
        content: Text('"${book.title}" silinsin mi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sil')),
        ],
      ),
    );
    if (ok == true) {
      await _repo.deleteBook(book.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _editPages(BuildContext context) async {
    final currentC = TextEditingController(text: book.currentPage.toString());
    final totalC = TextEditingController(text: book.pageCount.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sayfaları düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Şu anki sayfa'),
            ),
            TextField(
              controller: totalC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Toplam sayfa'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Kaydet')),
        ],
      ),
    );
    if (ok != true) return;
    final total = int.tryParse(totalC.text.trim()) ?? book.pageCount;
    var current = int.tryParse(currentC.text.trim()) ?? book.currentPage;
    if (total > 0 && current > total) current = total;
    if (current < 0) current = 0;
    book.pageCount = total;
    book.currentPage = current;
    if (total > 0 && current >= total) {
      book.status = ReadingStatus.read;
      book.finishedAt ??= DateTime.now();
    }
    _repo.updateBook(book);
  }

  Future<int?> _promptNumber(
      BuildContext context, String title, int initial) {
    final controller = TextEditingController(text: initial.toString());
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(controller.text.trim())),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
