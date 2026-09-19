import 'dart:async';

import 'package:flutter/material.dart';

/// Zamanlayıcı ekranı: geri sayım (okuma seansı) + kronometre.
class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Zamanlayıcı'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Geri Sayım'),
              Tab(text: 'Kronometre'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [CountdownTab(), StopwatchTab()],
        ),
      ),
    );
  }
}

/// Okuma seansı için geri sayım sayacı.
class CountdownTab extends StatefulWidget {
  const CountdownTab({super.key});

  @override
  State<CountdownTab> createState() => _CountdownTabState();
}

class _CountdownTabState extends State<CountdownTab> {
  static const List<int> _presets = [15, 25, 45, 60];
  int _totalSeconds = 25 * 60;
  int _remaining = 25 * 60;
  Timer? _timer;

  bool get _running => _timer != null;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setMinutes(int minutes) {
    _timer?.cancel();
    setState(() {
      _totalSeconds = minutes * 60;
      _remaining = minutes * 60;
      _timer = null;
    });
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _timer = null);
      return;
    }
    if (_remaining <= 0) _remaining = _totalSeconds;
    setState(() {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_remaining <= 1) {
          t.cancel();
          setState(() {
            _remaining = 0;
            _timer = null;
          });
          _onFinished();
        } else {
          setState(() => _remaining--);
        }
      });
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _remaining = _totalSeconds;
      _timer = null;
    });
  }

  void _onFinished() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Süre doldu! 📚'),
        content: const Text('Okuma seansı tamamlandı.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Tamam')),
        ],
      ),
    );
  }

  String get _formatted {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _custom() async {
    final controller =
        TextEditingController(text: (_totalSeconds ~/ 60).toString());
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Özel süre'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'dakika'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(controller.text.trim())),
            child: const Text('Ayarla'),
          ),
        ],
      ),
    );
    if (v != null && v > 0) _setMinutes(v);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds == 0 ? 0.0 : _remaining / _totalSeconds;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                      value: progress, strokeWidth: 10),
                ),
                Text(_formatted,
                    style: const TextStyle(
                        fontSize: 48, fontWeight: FontWeight.w300)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            children: _presets
                .map((m) => ChoiceChip(
                      label: Text('$m dk'),
                      selected: _totalSeconds == m * 60,
                      onSelected: _running ? null : (_) => _setMinutes(m),
                    ))
                .toList(),
          ),
          TextButton.icon(
            onPressed: _running ? null : _custom,
            icon: const Icon(Icons.tune),
            label: const Text('Özel süre'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _toggle,
                icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                label: Text(_running ? 'Duraklat' : 'Başlat'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.stop),
                label: const Text('Sıfırla'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Basit kronometre.
class StopwatchTab extends StatefulWidget {
  const StopwatchTab({super.key});

  @override
  State<StopwatchTab> createState() => _StopwatchTabState();
}

class _StopwatchTabState extends State<StopwatchTab> {
  final Stopwatch _sw = Stopwatch();
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_sw.isRunning) {
      _sw.stop();
      _ticker?.cancel();
      _ticker = null;
      setState(() {});
    } else {
      _sw.start();
      _ticker = Timer.periodic(
          const Duration(milliseconds: 100), (_) => setState(() {}));
    }
  }

  void _reset() {
    _sw.stop();
    _sw.reset();
    _ticker?.cancel();
    _ticker = null;
    setState(() {});
  }

  String get _formatted {
    final d = _sw.elapsed;
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = two(d.inMinutes % 60);
    final s = two(d.inSeconds % 60);
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_formatted,
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w200)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _toggle,
                icon: Icon(_sw.isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(_sw.isRunning ? 'Duraklat' : 'Başlat'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.stop),
                label: const Text('Sıfırla'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
