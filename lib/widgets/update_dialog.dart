import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/update_service.dart';

/// Yeni sürüm bulunduğunda kullanıcıya gösterilen diyalog.
Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Güncelleme mevcut'),
      content: Text(
        'Yeni sürüm yayınlandı: v${info.latestVersion}\n'
        'Senin sürümün: v${info.currentVersion}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Daha sonra'),
        ),
        FilledButton(
          onPressed: () async {
            final url = info.apkUrl ?? info.releaseUrl;
            if (url.isNotEmpty) {
              await launchUrl(Uri.parse(url),
                  mode: LaunchMode.externalApplication);
            }
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('İndir'),
        ),
      ],
    ),
  );
}
