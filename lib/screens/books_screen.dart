import 'package:flutter/material.dart';

import '../data/app_repository.dart';
import '../models/book.dart';
import '../widgets/book_cover.dart';
import 'book_detail_screen.dart';
import 'book_search_screen.dart';

/// Kitaplık ekranı: Okunuyor / Okunacak / Okundu sekmeleri.
class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kitaplığım'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Okunuyor'),
              Tab(text: 'Okunacak'),
              Tab(text: 'Okundu'),
            ],
          ),
        ),
        body: ValueListenableBuilder<List<Book>>(
          valueListenable: repo.books,
          builder: (context, books, _) {
            return TabBarView(
              children: [
                _BookList(
                  books: books.where((b) => b.status == ReadingStatus.reading).toList(),
                  emptyText: 'Şu an okuduğun kitap yok.',
                ),
                _BookList(
                  books: books.where((b) => b.status == ReadingStatus.toRead).toList(),
                  emptyText: 'Okuma listen boş.\nSağ alttan kitap ekle.',
                ),
                _BookList(
                  books: books.where((b) => b.status == ReadingStatus.read).toList(),
                  emptyText: 'Henüz bitirdiğin kitap yok.',
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BookSearchScreen()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Kitap Ekle'),
        ),
      ),
    );
  }
}

class _BookList extends StatelessWidget {
  final List<Book> books;
  final String emptyText;

  const _BookList({required this.books, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: books.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) => _BookTile(book: books[i]),
    );
  }
}

class _BookTile extends StatelessWidget {
  final Book book;
  const _BookTile({required this.book});

  @override
  Widget build(BuildContext context) {
    final showProgress = book.status != ReadingStatus.toRead && book.pageCount > 0;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: BookCover(url: book.thumbnailUrl, width: 44, height: 64),
      title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      isThreeLine: showProgress,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (book.authors.isNotEmpty)
            Text(book.authors, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (showProgress) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: book.progress, minHeight: 6),
            ),
            const SizedBox(height: 2),
            Text(
              '${book.currentPage}/${book.pageCount} sf • %${(book.progress * 100).round()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id)),
      ),
    );
  }
}
