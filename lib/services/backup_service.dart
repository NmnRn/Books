import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_repository.dart';

/// Verileri JSON olarak dışa aktarma (paylaşım) ve içe aktarma (dosya seçme).
class BackupService {
  /// Verileri JSON dosyasına yazar ve sistemin paylaşım sayfasını açar
  /// (Drive'a kaydet, kendine e-posta at, Dosyalar'a kaydet vb.).
  static Future<void> exportAndShare() async {
    final json = AppRepository.instance.exportJson();
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().split('T').first;
    final file = File('${dir.path}/okuma_defteri_yedek_$stamp.json');
    await file.writeAsString(json);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Okuma Defteri yedeği',
      ),
    );
  }

  /// Kullanıcıya bir `.json` dosyası seçtirir ve içeriğini metin olarak döndürür.
  /// İptal edilirse null.
  static Future<String?> pickBackupJson() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (files.isEmpty) return null;
    final bytes = await files.first.readAsBytes();
    return utf8.decode(bytes);
  }
}
