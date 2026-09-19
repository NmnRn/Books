import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../config.dart';

/// Güncelleme kontrolünün sonucu.
class UpdateInfo {
  final bool available;
  final String currentVersion;
  final String latestVersion;
  final String? apkUrl;
  final String releaseUrl;

  UpdateInfo({
    required this.available,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    this.apkUrl,
  });
}

/// GitHub Releases üzerinden en son sürümü kontrol eder ve semver karşılaştırır.
///
/// Akış: `git tag v1.1.0` → push → Actions Release yapar →
/// uygulama açılışta bu servisle "güncelleme var mı" diye bakar.
class UpdateService {
  Future<UpdateInfo?> check() async {
    if (!AppConfig.updatesEnabled) return null;

    final info = await PackageInfo.fromPlatform();
    final current = info.version; // pubspec sürümü, örn "1.0.0"

    final uri = Uri.parse(
      'https://api.github.com/repos/${AppConfig.githubOwner}/${AppConfig.githubRepo}/releases/latest',
    );
    final res = await http.get(
      uri,
      headers: {'Accept': 'application/vnd.github+json'},
    ).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return null; // henüz release yok olabilir

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final tag = (data['tag_name'] as String? ?? '').replaceFirst('v', '');
    final releaseUrl = data['html_url'] as String? ?? '';

    String? apkUrl;
    for (final a in (data['assets'] as List?) ?? const []) {
      final asset = a as Map<String, dynamic>;
      final name = (asset['name'] as String? ?? '').toLowerCase();
      if (name.endsWith('.apk')) {
        apkUrl = asset['browser_download_url'] as String?;
        break;
      }
    }

    return UpdateInfo(
      available: _isNewer(tag, current),
      currentVersion: current,
      latestVersion: tag.isEmpty ? current : tag,
      apkUrl: apkUrl,
      releaseUrl: releaseUrl,
    );
  }

  /// `latest` sürümü `current`'tan yeni ise true döner (basit semver).
  bool _isNewer(String latest, String current) {
    List<int> parse(String v) => v
        .split('+')
        .first
        .split('.')
        .map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();

    final l = parse(latest);
    final c = parse(current);
    final len = l.length > c.length ? l.length : c.length;
    for (var i = 0; i < len; i++) {
      final lv = i < l.length ? l[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (lv != cv) return lv > cv;
    }
    return false;
  }
}
