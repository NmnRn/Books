import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/app_repository.dart';
import '../models/task.dart';
import '../services/image_storage.dart';
import '../utils/date_format.dart';

/// Görev oluşturma/düzenleme ekranı: başlık, not, fotoğraf, zaman.
class TaskEditScreen extends StatefulWidget {
  /// null ise yeni görev; dolu ise düzenleme.
  final Task? task;
  const TaskEditScreen({super.key, this.task});

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  late final TextEditingController _titleC;
  late final TextEditingController _noteC;
  DateTime? _dueAt;
  String? _imagePath;
  String? _originalImagePath;
  bool _saved = false;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleC = TextEditingController(text: t?.title ?? '');
    _noteC = TextEditingController(text: t?.note ?? '');
    _dueAt = t?.dueAt;
    _imagePath = t?.imagePath;
    _originalImagePath = t?.imagePath;
  }

  @override
  void dispose() {
    // Kaydedilmeden çıkıldıysa, yeni seçilip commit edilmemiş dosyayı temizle.
    if (!_saved && _imagePath != null && _imagePath != _originalImagePath) {
      ImageStorage.delete(_imagePath);
    }
    _titleC.dispose();
    _noteC.dispose();
    super.dispose();
  }

  Future<void> _chooseSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final path = await ImageStorage.pickAndStore(source);
    if (path == null) return;
    // Önceki commit edilmemiş seçimi sil.
    if (_imagePath != null && _imagePath != _originalImagePath) {
      await ImageStorage.delete(_imagePath);
    }
    setState(() => _imagePath = path);
  }

  void _removeImage() {
    if (_imagePath != null && _imagePath != _originalImagePath) {
      ImageStorage.delete(_imagePath); // commit edilmemiş yeni dosya
    }
    setState(() => _imagePath = null);
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
      initialDate: _dueAt ?? DateTime.now(),
    );
    if (d == null || !mounted) return;
    final tt = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt ?? DateTime.now()),
    );
    setState(() =>
        _dueAt = DateTime(d.year, d.month, d.day, tt?.hour ?? 0, tt?.minute ?? 0));
  }

  Future<void> _save() async {
    final title = _titleC.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Başlık boş olamaz')));
      return;
    }
    final repo = AppRepository.instance;
    final note = _noteC.text.trim().isEmpty ? null : _noteC.text.trim();

    // Fotoğraf değiştiyse eski orijinali sil.
    if (_originalImagePath != null && _originalImagePath != _imagePath) {
      await ImageStorage.delete(_originalImagePath);
    }

    if (_isEdit) {
      final t = widget.task!
        ..title = title
        ..note = note
        ..dueAt = _dueAt
        ..imagePath = _imagePath;
      await repo.updateTask(t);
    } else {
      await repo.addTask(Task(
        id: repo.newId(),
        title: title,
        note: note,
        dueAt: _dueAt,
        imagePath: _imagePath,
      ));
    }
    _saved = true;
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Görevi sil'),
        content: const Text('Bu görev silinsin mi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true) return;
    await ImageStorage.delete(widget.task!.imagePath);
    await AppRepository.instance.deleteTask(widget.task!.id);
    _saved = true; // dispose tekrar silmeye çalışmasın
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Görevi Düzenle' : 'Yeni Görev'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Sil',
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleC,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Başlık',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteC,
            minLines: 3,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Not',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Zaman'),
              subtitle: Text(_dueAt == null ? 'Belirlenmedi' : formatDateTime(_dueAt!)),
              trailing: _dueAt == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _dueAt = null),
                    ),
              onTap: _pickDateTime,
            ),
          ),
          const SizedBox(height: 16),
          Text('Fotoğraf', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          if (_imagePath != null)
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_imagePath!),
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 220,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined, size: 40),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _removeImage,
                    ),
                  ),
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: _chooseSource,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Fotoğraf ekle'),
            ),
          if (_imagePath != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _chooseSource,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Fotoğrafı değiştir'),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
