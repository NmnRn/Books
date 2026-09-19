# 📚 Okuma Defteri

To-do + kitap okuma takibi bir arada, Flutter ile yazılmış Android uygulaması.
Kitaplar internetten (Google Books) otomatik doldurulur; veriler tamamen
cihazda saklanır. APK'lar GitHub Actions ile derlenir ve tag ile sürümlenir.

## ✨ Özellikler

- **Kitaplık** — Okunuyor / Okunacak / Okundu sekmeleri, sayfa ilerlemesi (% bar)
- **Otomatik kitap bilgisi** — Google Books'tan başlık, yazar, kapak, sayfa sayısı, açıklama (elle giriş de mümkün)
- **Görevler** — yapılacaklar listesi, isteğe bağlı zaman, kaydırarak sil
- **Zamanlayıcı** — geri sayım (okuma seansı) + kronometre
- **Otomatik güncelleme** — açılışta GitHub Releases'ten yeni sürüm kontrolü ve APK indirme

## 🏗️ Yapı

```
lib/
  config.dart                 # GitHub owner/repo ayarları
  main.dart                   # uygulama girişi + alt menü + güncelleme kontrolü
  theme.dart                  # Material 3 açık/koyu tema
  models/                     # Book, Task
  data/app_repository.dart    # Hive tabanlı yerel depo
  services/                   # book_search (Google Books), update (GitHub)
  screens/                    # books, book_search, book_detail, tasks, timer
  widgets/                    # book_cover, update_dialog
```

## 🚀 Kurulum (geliştirme)

```bash
flutter pub get
flutter run          # bağlı cihaz/emülatörde çalıştır
```

## 📦 APK derleme

**GitHub'da (önerilen):** `main` dalına push → Actions APK'yı derler.
İndirmek için: repo → **Actions** → ilgili çalışma → **Artifacts → app-release-apk**.

**Lokalde:** (Android SDK gerekir)
```bash
flutter build apk --release
# çıktı: build/app/outputs/flutter-apk/app-release.apk
```

## 🔖 Sürüm yayınlama (tag ile)

1. `pubspec.yaml` içindeki `version` değerini artır (örn. `1.1.0+2`).
2. Tag atıp push et:
   ```bash
   git tag v1.1.0
   git push origin v1.1.0
   ```
3. Actions APK'yı derleyip **GitHub Release**'e `app-release.apk` olarak ekler.
4. Uygulama, açılışta bu release'i görüp kullanıcıya "güncelleme var" der.

> ⚠️ Güncelleme kontrolünün çalışması için `lib/config.dart` içindeki
> `githubOwner` ve `githubRepo` değerlerini doldurman gerekir.

## 🔑 Notlar

- Release APK şimdilik **debug anahtarıyla** imzalanır (yan yüklemeye uygun).
  Play Store için kendi imza yapılandırmanı eklemelisin.
- Google Books API ücretsizdir ve anahtar gerektirmez.
