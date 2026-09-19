/// Uygulama geneli ayarlar.
///
/// GitHub deposunu oluşturduktan sonra [githubOwner] ve [githubRepo]
/// değerlerini kendi bilgilerinle doldur. Bu ikisi:
///   * güncelleme kontrolü (releases/latest)
///   * yeni sürüm APK indirme linki
/// için kullanılır.
class AppConfig {
  /// GitHub kullanıcı adın (örn: "numanerdem").
  static const String githubOwner = 'CHANGE_ME';

  /// Repo adı (örn: "Books").
  static const String githubRepo = 'Books';

  /// owner doldurulmadıysa güncelleme kontrolü sessizce devre dışı kalır.
  static bool get updatesEnabled =>
      githubOwner.isNotEmpty && githubOwner != 'CHANGE_ME';
}
