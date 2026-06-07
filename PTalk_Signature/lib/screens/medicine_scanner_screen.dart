import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ptalk_core/ptalk_core.dart';
import '../voice/holobox_api.dart';

/// Quét thông tin thuốc (Elder Care) — port MedicineScannerActivity.kt.
class MedicineScannerScreen extends StatefulWidget {
  const MedicineScannerScreen({super.key});
  @override
  State<MedicineScannerScreen> createState() => _MedicineScannerScreenState();
}

enum _ScanState { preview, capturing, analyzing, result, error }

class _MedicineScannerScreenState extends State<MedicineScannerScreen> {
  CameraController? _cam;
  bool _camReady = false;
  _ScanState _state = _ScanState.preview;
  String _message = 'Hướng camera vào vỉ/lọ thuốc rồi bấm chụp';
  String? _result;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (!(await Permission.camera.request()).isGranted) {
      setState(() {
        _state = _ScanState.error;
        _message = 'Cần quyền camera để quét thuốc';
      });
      return;
    }
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final ctrl = CameraController(back, ResolutionPreset.high,
          enableAudio: false);
      await ctrl.initialize();
      if (!mounted) return;
      setState(() {
        _cam = ctrl;
        _camReady = true;
      });
    } catch (e) {
      setState(() {
        _state = _ScanState.error;
        _message = 'Không mở được camera: $e';
      });
    }
  }

  Future<void> _capture() async {
    if (_cam == null || !_camReady) return;
    setState(() {
      _state = _ScanState.capturing;
      _message = 'Đang chụp...';
    });
    try {
      final shot = await _cam!.takePicture();
      setState(() {
        _state = _ScanState.analyzing;
        _message = 'Đang phân tích thuốc…';
      });
      final text = await HoloboxApi.analyzeMedicine(File(shot.path));
      if (!mounted) return;
      setState(() {
        if (text.isEmpty) {
          _state = _ScanState.preview;
          _message = 'Không nhận diện được, thử chụp rõ hơn';
        } else {
          _state = _ScanState.result;
          _result = text;
        }
      });
    } on HoloboxException catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ScanState.error;
        _message = e.message;
      });
    }
  }

  void _retake() => setState(() {
        _state = _ScanState.preview;
        _result = null;
        _message = 'Hướng camera vào vỉ/lọ thuốc rồi bấm chụp';
      });

  @override
  void dispose() {
    _cam?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.accentElder;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Quét thông tin thuốc'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _state == _ScanState.result
                ? _resultView(accent)
                : _cameraView(),
          ),
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(_message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFE67E22))),
                const SizedBox(height: 12),
                if (_state == _ScanState.result)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: accent),
                    onPressed: _retake,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Chụp lại'),
                  )
                else
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: accent),
                    onPressed: (_camReady &&
                            (_state == _ScanState.preview))
                        ? _capture
                        : null,
                    icon: _state == _ScanState.analyzing ||
                            _state == _ScanState.capturing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.camera),
                    label: const Text('Chụp & phân tích'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cameraView() {
    if (!_camReady || _cam == null) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFE67E22)));
    }
    return CameraPreview(_cam!);
  }

  Widget _resultView(Color accent) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kết quả phân tích:',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.accentElderDark)),
            const SizedBox(height: 12),
            Text(_result ?? '',
                style: const TextStyle(fontSize: 15, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
