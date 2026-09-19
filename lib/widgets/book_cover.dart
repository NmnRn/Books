import 'package:flutter/material.dart';

/// Kitap kapağı görseli. URL yoksa veya yüklenemezse yer tutucu gösterir.
class BookCover extends StatelessWidget {
  final String? url;
  final double width;
  final double height;

  const BookCover({
    super.key,
    required this.url,
    this.width = 48,
    this.height = 68,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(6);

    final placeholder = Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.menu_book,
          color: scheme.onSurfaceVariant, size: width * 0.5),
    );

    if (url == null || url!.isEmpty) {
      return ClipRRect(borderRadius: radius, child: placeholder);
    }

    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        url!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }
}
