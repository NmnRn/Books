import 'dart:io';

import 'package:flutter/material.dart';

import '../data/app_repository.dart';
import '../models/task.dart';
import '../services/image_storage.dart';
import '../utils/date_format.dart';
import 'task_edit_screen.dart';

/// Yapılacaklar (to-do) ekranı.
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Görevler')),
      body: ValueListenableBuilder<List<Task>>(
        valueListenable: repo.tasks,
        builder: (context, tasks, _) {
          if (tasks.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Henüz görev yok.\nSağ alttaki + ile ekle.',
                    textAlign: TextAlign.center),
              ),
            );
          }
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, i) => _TaskTile(task: tasks[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TaskEditScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;
  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;
    final scheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: scheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: scheme.onErrorContainer),
      ),
      onDismissed: (_) {
        ImageStorage.delete(task.imagePath);
        repo.deleteTask(task.id);
      },
      child: ListTile(
        leading: Checkbox(
          value: task.done,
          onChanged: (v) {
            task.done = v ?? false;
            repo.updateTask(task);
          },
        ),
        title: Text(
          task.title,
          style: task.done
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: _buildSubtitle(context),
        trailing: task.imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(task.imagePath!),
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.broken_image_outlined),
                ),
              )
            : (task.note != null && task.note!.isNotEmpty
                ? Icon(Icons.sticky_note_2_outlined, color: scheme.outline)
                : null),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskEditScreen(task: task)),
        ),
      ),
    );
  }

  Widget? _buildSubtitle(BuildContext context) {
    final hasNote = task.note != null && task.note!.isNotEmpty;
    final hasDue = task.dueAt != null;
    if (!hasNote && !hasDue) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDue)
          Text(formatDateTime(task.dueAt!),
              style: Theme.of(context).textTheme.bodySmall),
        if (hasNote)
          Text(task.note!, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
