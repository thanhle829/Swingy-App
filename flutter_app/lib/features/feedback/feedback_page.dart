import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../providers/analysis_provider.dart';

class FeedbackPage extends ConsumerStatefulWidget {
  const FeedbackPage({super.key});

  @override
  ConsumerState<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends ConsumerState<FeedbackPage> {
  VideoPlayerController? _videoController;
  Future<void>? _initializeVideoPlayerFuture;
  String? _currentMediaPath;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final analysis = ref.read(analysisProvider);
    _initVideo(analysis);
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  void _disposeVideo() {
    _initializeVideoPlayerFuture = null;
    _videoController?.dispose();
    _videoController = null;
    _currentMediaPath = null;
  }

  void _initVideo(analysis) {
    if (analysis == null) return;

    final media = analysis.media;
    if (analysis.mediaType != 'video' || media == null) {
      // no video to initialize
      return;
    }

    // Avoid reinitializing the same media
    if (_currentMediaPath == media) return;

    // Handle mock ids - not playable
    if (media.toString().startsWith('mock_video_')) {
      debugPrint('Mock video detected, not initializing VideoPlayer for: $media');
      setState(() {
        _error = 'Recorded video is not a playable file in this environment.';
      });
      return;
    }

    // Dispose previous controller and create a new one
    _videoController?.dispose();

    try {
      if (kIsWeb) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(media));
      } else {
        _videoController = VideoPlayerController.file(File(media));
      }

      _initializeVideoPlayerFuture = _videoController!.initialize().then((_) {
        if (mounted) setState(() {});
        _videoController!.setLooping(true);
      }).catchError((e) {
        debugPrint('Video initialization failed: $e');
        setState(() {
          _error = 'Failed to load video.';
        });
      });

      _currentMediaPath = media;
      debugPrint('Initialized VideoPlayer for: $media');
    } catch (e) {
      debugPrint('Video controller setup error: $e');
      setState(() {
        _error = 'Failed to prepare video playback.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = ref.watch(analysisProvider);

    if (analysis == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Posture Analysis')),
        body: const Center(child: Text('No analysis available. Please record or upload a video.', style: TextStyle(color: Colors.white70))),
      );
    }

    final postureColor = analysis.postureScore >= 85 ? Colors.greenAccent : (analysis.postureScore >= 70 ? Colors.amberAccent : Colors.redAccent);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0F1720), Color(0xFF0B1220)]),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                const SizedBox(height: 24),
                const Text('Posture Analysis', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                const Text('Review your posture and get recommendations', style: TextStyle(color: Color(0xFF94A3B8))),
                const SizedBox(height: 16),

                // Media preview (with video playback)
                Container(
                  width: double.infinity,
                  height: 420,
                  decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF334155), width: 2)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Center(
                      child: () {
                        if (analysis.mediaType == 'photo') {
                          return Image.network(analysis.media, fit: BoxFit.cover);
                        }

                        if (analysis.mediaType == 'video') {
                          if (_error != null) {
                            return Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center));
                          }

                          if (_initializeVideoPlayerFuture == null) {
                            // Attempt to initialize if not yet done
                            WidgetsBinding.instance.addPostFrameCallback((_) => _initVideo(analysis));
                            return const Center(child: CircularProgressIndicator());
                          }

                          return FutureBuilder(
                            future: _initializeVideoPlayerFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.done && _videoController != null && _videoController!.value.isInitialized) {
                                return Stack(children: [
                                  AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!)),
                                  Positioned(
                                    bottom: 12,
                                    left: 12,
                                    child: Row(children: [
                                      FloatingActionButton.small(
                                        backgroundColor: Colors.black45,
                                        onPressed: () {
                                          setState(() {
                                            if (_videoController!.value.isPlaying) {
                                              _videoController!.pause();
                                            } else {
                                              _videoController!.play();
                                            }
                                          });
                                        },
                                        child: Icon(_videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(_currentMediaPath ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                                    ]),
                                  ),
                                ]);
                              }

                              if (snapshot.hasError) {
                                return const Center(child: Text('Failed to load video.', style: TextStyle(color: Colors.white70)));
                              }

                              return const Center(child: CircularProgressIndicator());
                            },
                          );
                        }

                        return const Center(child: Icon(Icons.play_circle_outline, size: 64, color: Colors.white24));
                      }(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Score
                Card(
                  color: const Color(0xFF0B1220),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF334155))),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Row(children: const [Icon(Icons.trending_up, color: Colors.lightBlueAccent), SizedBox(width: 8), Text('Posture Score', style: TextStyle(color: Colors.white))]),
                        Text('${analysis.postureScore}%', style: TextStyle(color: postureColor, fontSize: 24, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: analysis.postureScore / 100.0,
                          minHeight: 10,
                          backgroundColor: const Color(0xFF0B1220),
                          color: postureColor,
                        ),
                      )
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                // Detected body areas
                Card(
                  color: const Color(0xFF0B1220),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF334155))),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: const [Icon(Icons.check_circle, color: Colors.lightBlueAccent), SizedBox(width: 8), Text('Detected Body Areas', style: TextStyle(color: Colors.white))]),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, children: analysis.bodyAreas.map((b) => Chip(label: Text(b), backgroundColor: Colors.blueGrey.shade800, labelStyle: const TextStyle(color: Colors.lightBlueAccent))).toList()),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                // Key Issues
                if (analysis.keyIssues.isNotEmpty)
                  Card(
                    color: const Color(0xFF0B1220),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF334155))),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: const [Icon(Icons.warning_amber, color: Colors.redAccent), SizedBox(width: 8), Text('Key Issues', style: TextStyle(color: Colors.white))]),
                        const SizedBox(height: 8),
                        ...analysis.keyIssues.map((issue) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [const SizedBox(width: 8), Text('•', style: TextStyle(color: Colors.redAccent)), const SizedBox(width: 8), Expanded(child: Text(issue, style: TextStyle(color: Colors.white70)))]))),
                      ]),
                    ),
                  ),
                const SizedBox(height: 12),

                // Improvements
                Card(
                  color: const Color(0xFF0B1220),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF334155))),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: const [Icon(Icons.trending_up, color: Colors.amberAccent), SizedBox(width: 8), Text('Improvement Recommendations', style: TextStyle(color: Colors.white))]),
                      const SizedBox(height: 8),
                      ...analysis.improvements.map((improvement) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [const SizedBox(width: 8), Text('•', style: TextStyle(color: Colors.amberAccent)), const SizedBox(width: 8), Expanded(child: Text(improvement, style: TextStyle(color: Colors.white70)))]))),
                    ]),
                  ),
                ),

                const SizedBox(height: 12),

                ElevatedButton.icon(onPressed: () => context.go('/poses'), icon: const Icon(Icons.emoji_events), label: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('View Famous Golfer Poses', style: TextStyle(fontWeight: FontWeight.bold)))),

                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(analysisProvider.notifier).clear();
                        context.go('/');
                      },
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF334155))),
                      child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Retake')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Save results
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Save Results')),
                    ),
                  ),
                ])
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
