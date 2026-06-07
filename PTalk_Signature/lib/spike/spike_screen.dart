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

  Future<void> _toggle() async {
    if (_active) {
      await _client?.stop();
      setState(() => _active = false);
    } else {
      _client = SpikeVoiceClient(onLog: _log);
      setState(() => _active = true);
      await _client!.start();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Audio Spike')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _toggle,
              icon: Icon(_active ? Icons.stop : Icons.mic),
              label: Text(_active ? 'Dừng' : 'Bắt đầu nói'),
            ),
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
