import 'package:flutter/material.dart';
import 'spike_voice_client.dart';

class SpikeScreen extends StatefulWidget {
  const SpikeScreen({super.key});
  @override
  State<SpikeScreen> createState() => _SpikeScreenState();
}

class _SpikeScreenState extends State<SpikeScreen> {
  final _logs = <String>[];
  SpikeVoiceClient? _client;
  bool _active = false;

  void _log(String s) => setState(() => _logs.insert(0, s));

  Future<void> _start({required bool loopback}) async {
    if (_active) return;
    _client = SpikeVoiceClient(onLog: _log);
    setState(() => _active = true);
    if (loopback) {
      await _client!.startLoopback();
    } else {
      await _client!.start();
    }
  }

  Future<void> _stop() async {
    if (!_active) return;
    await _client?.stop();
    setState(() => _active = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Audio Spike')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _active ? null : () => _start(loopback: true),
                    icon: const Icon(Icons.loop),
                    label: const Text('Loopback (offline)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _active ? null : () => _start(loopback: false),
                    icon: const Icon(Icons.cloud),
                    label: const Text('Server (WS)'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _active ? _stop : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Dừng'),
                ),
              ),
            ]),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _logs.map((l) => Text(l)).toList(),
            ),
          ),
        ]),
      );
}
