import 'package:flutter/material.dart';

import '../data/app_repository.dart';
import '../models/task.dart';

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
            itemBuilder: (context, i) {
              final t = tasks[i];
              return Dismissible(
                key: ValueKey(t.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Theme.of(context).colorScheme.errorContainer,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete,
                      color: Theme.of(context).colorScheme.onErrorContainer),
                ),
                onDismissed: (_) => repo.deleteTask(t.id),
                child: CheckboxListTile(
                  value: t.done,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (v) {
                    t.done = v ?? false;
                    repo.updateTask(t);
                  },
                  title: Text(
                    t.title,
                    style: t.done
                        ? const TextStyle(decoration: TextDecoration.lineThrough)
                        : null,
                  ),
                  subtitle: t.dueAt != null ? Text(_formatDue(t.dueAt!)) : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTask(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  static String _formatDue(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _addTask(BuildContext context) async {
    final controller = TextEditingController();
    DateTime? due;
    final repo = AppRepository.instance;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Yeni görev'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Görev'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      due == null ? 'Zaman belirlenmedi' : _formatDue(due!),
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.schedule),
                    label: const Text('Zaman'),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime(2100),
                        initialDate: DateTime.now(),
                      );
                      if (d == null || !ctx.mounted) return;
                      final tt = await showTimePicker(
                          context: ctx, initialTime: TimeOfDay.now());
                      setLocal(() => due = DateTime(
                          d.year, d.month, d.day, tt?.hour ?? 0, tt?.minute ?? 0));
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Ekle')),
          ],
        ),
      ),
    );

    if (result != true) return;
    final title = controller.text.trim();
    if (title.isEmpty) return;
    await repo.addTask(Task(id: repo.newId(), title: title, dueAt: due));
  }
}
