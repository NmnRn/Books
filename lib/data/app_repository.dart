import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/book.dart';
import '../models/task.dart';

/// Uygulamanın tüm verisini cihazda (Hive) tutan basit depo.
///
/// Kayıtlar JSON string olarak saklanır; bu sayede tür sorunlarıyla
/// uğraşmadan modeller serbestçe değiştirilebilir.
class AppRepository {
  AppRepository._();
  static final AppRepository instance = AppRepository._();

  static const String _booksBox = 'books';
  static const String _tasksBox = 'tasks';
  static const String _settingsBox = 'settings';

  late final Box<String> _books;
  late final Box<String> _tasks;
  late final Box<String> _settings;

  /// Ekranlar bu notifier'ları dinleyerek otomatik güncellenir.
  final ValueNotifier<List<Book>> books = ValueNotifier<List<Book>>([]);
  final ValueNotifier<List<Task>> tasks = ValueNotifier<List<Task>>([]);
  final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.system);
  final ValueNotifier<int> yearlyGoal = ValueNotifier<int>(0);

  Future<void> init() async {
    await Hive.initFlutter();
    _books = await Hive.openBox<String>(_booksBox);
    _tasks = await Hive.openBox<String>(_tasksBox);
    _settings = await Hive.openBox<String>(_settingsBox);
    _reloadBooks();
    _reloadTasks();

    final storedTheme = _settings.get('themeMode');
    themeMode.value = ThemeMode.values.firstWhere(
      (e) => e.name == storedTheme,
      orElse: () => ThemeMode.system,
    );
    yearlyGoal.value = int.tryParse(_settings.get('yearlyGoal') ?? '') ?? 0;
  }

  /// Yeni kayıtlar için benzersiz kimlik.
  String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  // ---------------- Kitaplar ----------------

  void _reloadBooks() {
    final list = _books.values.map(Book.fromJson).toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    books.value = list;
  }

  Future<void> addBook(Book book) async {
    await _books.put(book.id, book.toJson());
    _reloadBooks();
  }

  Future<void> updateBook(Book book) async {
    await _books.put(book.id, book.toJson());
    _reloadBooks();
  }

  Future<void> deleteBook(String id) async {
    await _books.delete(id);
    _reloadBooks();
  }

  // ---------------- Görevler ----------------

  void _reloadTasks() {
    final list = _tasks.values.map(Task.fromJson).toList()
      ..sort((a, b) {
        if (a.done != b.done) return a.done ? 1 : -1;
        return b.createdAt.compareTo(a.createdAt);
      });
    tasks.value = list;
  }

  Future<void> addTask(Task task) async {
    await _tasks.put(task.id, task.toJson());
    _reloadTasks();
  }

  Future<void> updateTask(Task task) async {
    await _tasks.put(task.id, task.toJson());
    _reloadTasks();
  }

  Future<void> deleteTask(String id) async {
    await _tasks.delete(id);
    _reloadTasks();
  }

  // ---------------- Yedekleme (JSON) ----------------

  /// Tüm kitap ve görevleri okunabilir JSON metnine dönüştürür.
  /// Not: Görev fotoğrafları (yerel dosyalar) yedeğe dahil edilmez.
  String exportJson() {
    final data = {
      'app': 'okuma_defteri',
      'schema': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'books': books.value.map((b) => b.toMap()).toList(),
      'tasks': tasks.value.map((t) => t.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// JSON yedeğini geri yükler.
  ///
  /// [replace] true ise mevcut tüm veri silinip yerine yüklenir;
  /// false ise id'ye göre birleştirilir (aynı id üzerine yazılır, yenisi eklenir).
  /// Yüklenen toplam kayıt sayısını döndürür.
  Future<int> importJson(String source, {required bool replace}) async {
    final data = jsonDecode(source) as Map<String, dynamic>;
    final bookList = (data['books'] as List?) ?? const [];
    final taskList = (data['tasks'] as List?) ?? const [];

    if (replace) {
      await _books.clear();
      await _tasks.clear();
    }
    for (final raw in bookList) {
      final book = Book.fromMap((raw as Map).cast<String, dynamic>());
      await _books.put(book.id, book.toJson());
    }
    for (final raw in taskList) {
      final task = Task.fromMap((raw as Map).cast<String, dynamic>());
      await _tasks.put(task.id, task.toJson());
    }
    _reloadBooks();
    _reloadTasks();
    return bookList.length + taskList.length;
  }

  // ---------------- Ayarlar ----------------

  /// Google Books API anahtarı (kullanıcı Ayarlar'dan girer). Boşsa anahtarsız.
  String get googleApiKey => _settings.get('googleApiKey') ?? '';

  Future<void> setGoogleApiKey(String value) =>
      _settings.put('googleApiKey', value.trim());

  Future<void> setThemeMode(ThemeMode mode) async {
    await _settings.put('themeMode', mode.name);
    themeMode.value = mode;
  }

  Future<void> setYearlyGoal(int goal) async {
    final g = goal < 0 ? 0 : goal;
    await _settings.put('yearlyGoal', g.toString());
    yearlyGoal.value = g;
  }
}
