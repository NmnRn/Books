import 'package:flutter/material.dart';

import '../data/app_repository.dart';
import '../models/book.dart';

/// Okuma istatistikleri: özet sayılar, okunan sayfa ve son 12 ay grafiği.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  static const List<String> _months = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('İstatistikler')),
      body: ValueListenableBuilder<List<Book>>(
        valueListenable: repo.books,
        builder: (context, books, _) {
          if (books.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Henüz kitap yok.\nKitap ekledikçe istatistikler burada oluşur.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ValueListenableBuilder<int>(
            valueListenable: repo.yearlyGoal,
            builder: (context, goal, _) => _buildStats(context, books, goal),
          );
        },
      ),
    );
  }

  Widget _buildStats(BuildContext context, List<Book> books, int goal) {
    final scheme = Theme.of(context).colorScheme;

    final read =
        books.where((b) => b.status == ReadingStatus.read).toList();
    final reading =
        books.where((b) => b.status == ReadingStatus.reading).length;
    final toRead =
        books.where((b) => b.status == ReadingStatus.toRead).length;

    var pagesRead = 0;
    for (final b in books) {
      if (b.status == ReadingStatus.read) {
        pagesRead += b.pageCount > 0 ? b.pageCount : b.currentPage;
      } else {
        pagesRead += b.currentPage;
      }
    }

    final now = DateTime.now();
    final finishedThisYear = read
        .where((b) => b.finishedAt != null && b.finishedAt!.year == now.year)
        .length;
    final finishedThisMonth = read
        .where((b) =>
            b.finishedAt != null &&
            b.finishedAt!.year == now.year &&
            b.finishedAt!.month == now.month)
        .length;

    final readPages = read.where((b) => b.pageCount > 0).map((b) => b.pageCount);
    final avgPages =
        readPages.isEmpty ? 0 : (readPages.reduce((a, b) => a + b) / readPages.length).round();

    // Son 12 ay: her ay bitirilen kitap sayısı.
    final counts = <int>[];
    final labels = <String>[];
    for (var i = 11; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      labels.add(_months[m.month - 1]);
      counts.add(read
          .where((b) =>
              b.finishedAt != null &&
              b.finishedAt!.year == m.year &&
              b.finishedAt!.month == m.month)
          .length);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (goal > 0) ...[
          _goalCard(context, finishedThisYear, goal),
          const SizedBox(height: 16),
        ],
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _StatCard(icon: Icons.library_books_outlined, label: 'Toplam kitap', value: '${books.length}', color: scheme.primary),
            _StatCard(icon: Icons.check_circle_outline, label: 'Okundu', value: '${read.length}', color: Colors.green),
            _StatCard(icon: Icons.auto_stories_outlined, label: 'Okunuyor', value: '$reading', color: Colors.orange),
            _StatCard(icon: Icons.bookmark_outline, label: 'Okunacak', value: '$toRead', color: scheme.tertiary),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Okuma', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _statRow(context, Icons.menu_book_outlined, 'Toplam okunan sayfa', '$pagesRead'),
                _statRow(context, Icons.calendar_today_outlined, 'Bu yıl bitirilen', '$finishedThisYear kitap'),
                _statRow(context, Icons.today_outlined, 'Bu ay bitirilen', '$finishedThisMonth kitap'),
                if (avgPages > 0)
                  _statRow(context, Icons.straighten_outlined, 'Ortalama uzunluk', '$avgPages sayfa'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Son 12 ayda bitirilen', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                _MonthlyChart(counts: counts, labels: labels, color: scheme.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _goalCard(BuildContext context, int done, int goal) {
    final progress = (done / goal).clamp(0.0, 1.0);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: scheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text('${DateTime.now().year} okuma hedefi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimaryContainer)),
                const Spacer(),
                Text('$done / $goal',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: progress, minHeight: 12),
            ),
            const SizedBox(height: 8),
            Text(
              done >= goal
                  ? 'Hedefe ulaştın! 🎉'
                  : '%${(progress * 100).round()} tamam — ${goal - done} kitap kaldı',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Basit dikey çubuk grafik (paket kullanmadan).
class _MonthlyChart extends StatelessWidget {
  final List<int> counts;
  final List<String> labels;
  final Color color;

  const _MonthlyChart({
    required this.counts,
    required this.labels,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final maxC = counts.fold<int>(0, (m, c) => c > m ? c : m);
    if (maxC == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Bu dönemde bitirdiğin kitap yok.'),
      );
    }
    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(counts.length, (i) {
          final c = counts[i];
          final barHeight = c == 0 ? 0.0 : (c / maxC) * 100.0;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (c > 0)
                  Text('$c', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 2),
                Container(
                  height: barHeight + (c > 0 ? 4 : 0),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: c > 0 ? color : Colors.transparent,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(labels[i],
                      style: Theme.of(context).textTheme.labelSmall),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
