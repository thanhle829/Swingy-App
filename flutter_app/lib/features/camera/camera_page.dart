
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/analysis_provider.dart';
import '../../shared/web_file_url.dart';

class CameraPage extends ConsumerStatefulWidget {
  const CameraPage({super.key});

  @override
  ConsumerState<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends ConsumerState<CameraPage> {
  String? selectedFileName;
  String? previewMedia; // local path or mock id
  bool _isUploading = false;
  String? _error;

  void _triggerUpload() async {
    try {
      setState(() {
        _isUploading = true;
        _error = null;
      });
      final result = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Validate extension to ensure only video files are accepted
        final fileName = file.name ?? '';
        final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
        const allowed = {'mp4', 'mov', 'webm', 'mkv', 'avi', 'mpeg', 'mpg', '3gp', 'wmv'};
        if (!allowed.contains(ext)) {
          setState(() {
            _error = 'Please select a video file (MP4/MOV/WebM, etc).';
          });
          return;
        }

        // On web, attempt to create an object URL from bytes so VideoPlayer can play it.
        String mediaUrl;
        if (kIsWeb) {
          final objUrl = createObjectUrlFromBytes(file.bytes, file.name);
          mediaUrl = objUrl ?? file.name;
        } else {
          mediaUrl = file.path ?? file.name;
        }

        debugPrint('Picked upload: $mediaUrl');
        setState(() {
          previewMedia = mediaUrl;
          selectedFileName = file.name;
          _error = null;
        });

        ref.read(analysisProvider.notifier).setMediaAndAnalyze(mediaUrl, 'video');
        if (mounted) context.go('/feedback');
      }
    } catch (e) {
      debugPrint('Upload failed: $e');
      setState(() {
        _error = 'Failed to pick a video.';
      });
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewWidget = previewMedia != null
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.play_circle_outline, size: 64, color: Colors.white24), const SizedBox(height: 8), Text(selectedFileName ?? '', style: const TextStyle(color: Colors.white70))]))
        : const Center(child: Icon(Icons.videocam, size: 64, color: Colors.white24));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/pexels-ashford-marx-1565533-6501725.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.55), BlendMode.darken),
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
                  const Text('Posture Check', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white, shadows: [Shadow(color: Colors.black45, blurRadius: 6, offset: Offset(0,2))])),
                  const SizedBox(height: 6),
                  const Text('Upload a video to analyze your posture', style: TextStyle(color: Color(0xFF94A3B8))),
                  const SizedBox(height: 12),

                  if (_error != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade900, borderRadius: BorderRadius.circular(10)),
                      child: Text(_error!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                    ),

                  const SizedBox(height: 8),

                  // Video area (rounded inner panel)
                  Container(
                    width: double.infinity,
                    height: 460,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9AAE81).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF2E4F10), width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          // subtle inner area background to match design
                          Positioned.fill(child: Container(color: const Color(0xFF9AAE81).withOpacity(0.12))),
                          Positioned.fill(child: previewWidget),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Upload button (single)
                  SizedBox(
                    width: 320,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _triggerUpload,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3E6B0A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12)),
                      child: _isUploading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Upload Video', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF203214).withOpacity(0.6), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2E4F10))), child: const Text('Upload a video file (MP4 preferred). Position your entire body in frame for accurate posture analysis', style: TextStyle(color: Color(0xFFBFD2A8)), textAlign: TextAlign.center)),
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
