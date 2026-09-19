import 'package:flutter/foundation.dart';
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

  late final Box<String> _books;
  late final Box<String> _tasks;

  /// Ekranlar bu notifier'ları dinleyerek otomatik güncellenir.
  final ValueNotifier<List<Book>> books = ValueNotifier<List<Book>>([]);
  final ValueNotifier<List<Task>> tasks = ValueNotifier<List<Task>>([]);

  Future<void> init() async {
    await Hive.initFlutter();
    _books = await Hive.openBox<String>(_booksBox);
    _tasks = await Hive.openBox<String>(_tasksBox);
    _reloadBooks();
    _reloadTasks();
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
}
