import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/app_repository.dart';
import '../services/backup_service.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';

/// Yedekleme, güncelleme kontrolü ve sürüm bilgisi.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = 'v${info.version} (${info.buildNumber})');
    }
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      await BackupService.exportAndShare();
    } catch (_) {
      _snack('Dışa aktarma başarısız oldu.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final json = await BackupService.pickBackupJson();
    if (json == null || !mounted) return;

    // true = sıfırla ve yükle, false = birleştir, null = iptal
    final mode = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Geri yükleme'),
        content: const Text(
            'Yedek nasıl uygulansın?\n\n• Birleştir: mevcut verinin üstüne ekler\n• Sıfırla ve yükle: her şeyi silip yedeği yükler'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Birleştir')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sıfırla ve yükle')),
        ],
      ),
    );
    if (mode == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final count =
          await AppRepository.instance.importJson(json, replace: mode);
      _snack('$count kayıt geri yüklendi.');
    } catch (_) {
      _snack('Geçersiz veya bozuk yedek dosyası.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkUpdate() async {
    setState(() => _busy = true);
    try {
      final info = await UpdateService().check();
      if (!mounted) return;
      if (info == null) {
        _snack('Güncelleme bilgisi alınamadı (config veya internet).');
      } else if (info.available) {
        await showUpdateDialog(context, info);
      } else {
        _snack('En güncel sürümü kullanıyorsun. 👍');
      }
    } catch (_) {
      _snack('Güncelleme kontrolü başarısız.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: Stack(
        children: [
          ListView(
            children: [
              _sectionTitle('Yedekleme'),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('Yedeği dışa aktar'),
                subtitle: const Text('Kitap ve görevleri JSON olarak paylaş'),
                onTap: _busy ? null : _export,
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Yedekten geri yükle'),
                subtitle: const Text('Bir .json yedek dosyası seç'),
                onTap: _busy ? null : _import,
              ),
              const Divider(),
              _sectionTitle('Güncelleme'),
              ListTile(
                leading: const Icon(Icons.system_update_outlined),
                title: const Text('Güncellemeleri kontrol et'),
                onTap: _busy ? null : _checkUpdate,
              ),
              const Divider(),
              _sectionTitle('Hakkında'),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Sürüm'),
                subtitle: Text(_version.isEmpty ? '...' : _version),
              ),
            ],
          ),
          if (_busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
      );
}
