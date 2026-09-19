import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Görev fotoğraflarını cihazda kalıcı olarak saklar.
class ImageStorage {
  static final ImagePicker _picker = ImagePicker();

  /// Kamera veya galeriden fotoğraf seçer ve uygulamanın kalıcı klasörüne
  /// kopyalar. Kalıcı dosya yolunu döndürür; iptal edilirse null.
  static Future<String?> pickAndStore(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${dir.path}/task_images');
    if (!imagesDir.existsSync()) {
      imagesDir.createSync(recursive: true);
    }
    final ext = picked.path.contains('.') ? picked.path.split('.').last : 'jpg';
    final dest = '${imagesDir.path}/${DateTime.now().microsecondsSinceEpoch}.$ext';
    await File(picked.path).copy(dest);
    return dest;
  }

  /// Verilen yoldaki fotoğrafı siler (varsa).
  ///
  /// Fotoğraf silme kritik değildir; ateşle-unut olarak çağrılabildiği için
  /// hataları içeride yutar (yakalanmayan async exception oluşmaz).
  static Future<void> delete(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {
      // Dosya silinemezse sessizce geç.
    }
  }
}
