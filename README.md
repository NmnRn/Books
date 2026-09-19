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

## 🔎 Kitap arama kaynakları

Arama, dört kaynağı paralel sorgular ve sonuçları birleştirir:
Google Books, Open Library, Internet Archive, Apple Books. Biri hata verse
(ör. Google kotası) diğerleri sonuç döndürür.

### Google Books'u kotasız yapmak (opsiyonel)

Anahtarsızken Google Books paylaşılan bir günlük kotaya tabidir ve sık sık
`429` döndürür. Kendi ücretsiz anahtarınla bu sorun biter (kod ve CI hazır):

1. https://console.cloud.google.com → yeni proje oluştur
2. **APIs & Services → Library → "Books API"** → Enable
3. **APIs & Services → Credentials → Create credentials → API key** (kredi kartı gerekmez)
4. GitHub: repo → **Settings → Secrets and variables → Actions → New repository secret**
   - Name: `GOOGLE_BOOKS_API_KEY`, Value: (aldığın anahtar)
5. Yeni bir sürüm etiketi at (`git tag vX.Y.Z && git push origin vX.Y.Z`)

Yerelde denemek için: `flutter run --dart-define=GOOGLE_BOOKS_API_KEY=ANAHTAR`

## 🔑 İmzalama

- Release APK'lar CI'da **sabit release anahtarıyla** imzalanır (GitHub Secrets:
  `KEYSTORE_BASE64`, `STORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`).
  Böylece güncellemeler eskinin üstüne kurulur ve **veri korunur**.
- Keystore ve `android/key.properties` **asla commit'lenmez** (gitignore'da).
  Bu dosyaları ve parolayı güvenli bir yerde sakla — kaybedersen aynı anahtarla
  güncelleme yayınlayamazsın.
