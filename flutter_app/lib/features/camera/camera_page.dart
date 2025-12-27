
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../providers/analysis_provider.dart';

class CameraPage extends ConsumerStatefulWidget {
  const CameraPage({super.key});

  @override
  ConsumerState<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends ConsumerState<CameraPage> {
  bool isRecording = false;
  int recordingTime = 0;
  String? selectedFileName;
  String? previewMedia; // local path or mock id

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  String? _error;

  Future<void> _initCameras() async {
    if (kIsWeb) return; // web will use file picker for now

    final cameraPermission = await Permission.camera.request();
    final micPermission = await Permission.microphone.request();

    if (!cameraPermission.isGranted || !micPermission.isGranted) {
      // leave UI to show permissions denied
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(_cameras!.first, ResolutionPreset.high, enableAudio: true);
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e, st) {
      // Surface initialization errors to the UI for easier debugging on device
      if (mounted) {
        setState(() {
          _error = 'Camera initialization failed: ${e.toString()}';
        });
      }
      debugPrint('Camera init error: $e\n$st');
    }
  }

  Future<void> _startRecording() async {
    if (!kIsWeb && _controller != null && _controller!.value.isInitialized) {
      try {
        await _controller!.startVideoRecording();
        setState(() {
          isRecording = true;
          recordingTime = 0;
          _error = null;
        });
        // periodic timer
        Future.doWhile(() async {
          if (!mounted) return false;
          if (isRecording) {
            await Future.delayed(const Duration(seconds: 1));
            setState(() {
              recordingTime += 1;
            });
            return true;
          }
          return false;
        });
      } catch (e, st) {
        // fallback to mock behavior and show error
        if (mounted) {
          setState(() {
            _error = 'Failed to start recording: ${e.toString()}';
          });
        }
        debugPrint('Start recording error: $e\n$st');
        superSetMockRecording();
      }
    } else {
      // web or uninitialized - fallback mock
      superSetMockRecording();
    }
  }

  void superSetMockRecording() {
    setState(() {
      isRecording = true;
      recordingTime = 0;
    });
  }

  Future<void> _stopRecording() async {
    if (!kIsWeb && _controller != null && _controller!.value.isRecordingVideo) {
      try {
        final XFile file = await _controller!.stopVideoRecording();
        final length = await file.length();
        debugPrint('Saved video path: ${file.path} (${length} bytes)');

        setState(() {
          isRecording = false;
          previewMedia = file.path;
          selectedFileName = file.name;
        });

        ref.read(analysisProvider.notifier).setMediaAndAnalyze(file.path, 'video');
        if (mounted) context.go('/feedback');
      } catch (e) {
        // fallback to mock
        final mockUrl = 'mock_video_${DateTime.now().millisecondsSinceEpoch}';
        debugPrint('Recording fallback used, mock id: $mockUrl, error: $e');
        setState(() {
          isRecording = false;
          previewMedia = mockUrl;
          selectedFileName = 'Recorded video';
        });
        ref.read(analysisProvider.notifier).setMediaAndAnalyze(mockUrl, 'video');
        if (mounted) context.go('/feedback');
      }
    } else if (isRecording) {
      // mock stop
      setState(() {
        isRecording = false;
      });
      final mockUrl = 'mock_video_${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        previewMedia = mockUrl;
        selectedFileName = 'Recorded video';
      });
      ref.read(analysisProvider.notifier).setMediaAndAnalyze(mockUrl, 'video');
      if (mounted) context.go('/feedback');
    }
  }

  void _triggerUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final mediaUrl = file.path ?? file.name;
        debugPrint('Picked upload: $mediaUrl');
        setState(() {
          previewMedia = mediaUrl;
          selectedFileName = file.name;
        });

        ref.read(analysisProvider.notifier).setMediaAndAnalyze(mediaUrl, 'video');
        if (mounted) context.go('/feedback');
      }
    } catch (e) {
      // ignore for now
    }
  }

  String _formatTime(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  void initState() {
    super.initState();
    _initCameras();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewWidget = !kIsWeb && _isCameraInitialized && _controller != null
        ? CameraPreview(_controller!)
        : (previewMedia != null
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.play_circle_outline, size: 64, color: Colors.white24), const SizedBox(height: 8), Text(selectedFileName ?? '', style: const TextStyle(color: Colors.white70))]))
            : const Center(child: Icon(Icons.videocam, size: 64, color: Colors.white24)));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F1720), Color(0xFF0B1220)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  const Text('Posture Check', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  const Text('Upload or record a video to analyze your posture', style: TextStyle(color: Color(0xFF94A3B8))),
                  const SizedBox(height: 12),

                  // Error message (if any)
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade900, borderRadius: BorderRadius.circular(10)),
                      child: Text(_error!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                    ),

                  const SizedBox(height: 8),

                  // Video area
                  Container(
                    width: double.infinity,
                    height: 420,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF334155), width: 2),
                    ),
                    child: Stack(
                      children: [
                        // Preview or placeholder
                        Positioned.fill(child: previewWidget),

                        // Recording badge
                        if (isRecording)
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(999)),
                              child: Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), const SizedBox(width: 8), Text(_formatTime(recordingTime), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Action buttons
                  if (previewMedia != null)
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              previewMedia = null;
                              selectedFileName = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF334155))),
                          child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Retake')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Use the existing analysis result to go to feedback (already set)
                            if (mounted) context.go('/feedback');
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Analyze')),
                        ),
                      ),
                    ])
                  else
                    Row(children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _triggerUpload,
                          icon: const Icon(Icons.upload_file),
                          label: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Upload Video')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isRecording ? _stopRecording : _startRecording,
                          icon: Icon(isRecording ? Icons.stop : Icons.videocam),
                          label: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(isRecording ? 'Stop' : 'Record')),
                          style: ElevatedButton.styleFrom(backgroundColor: isRecording ? Colors.red : Colors.green),
                        ),
                      ),
                    ]),

                  const SizedBox(height: 12),
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF0B1220), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF334155))), child: const Text('Upload a video or record one live. Position your entire body in frame for accurate posture analysis', style: TextStyle(color: Color(0xFF94A3B8)), textAlign: TextAlign.center)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
