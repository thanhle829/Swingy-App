
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

class PosesPage extends StatelessWidget {
  const PosesPage({super.key});

  void _showVideo(BuildContext context, String assetPath) {
    // Show a dialog that initializes and plays the video
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        late final VideoPlayerController controller;
        late Future<void> initializeFuture;

        // Create and initialize the controller here so it is disposed when dialog closes
        if (kIsWeb) {
          controller = VideoPlayerController.networkUrl(Uri.parse(assetPath));
        } else {
          // Assets are packaged with the app
          controller = VideoPlayerController.asset(assetPath);
        }

        initializeFuture = controller.initialize().then((_) {
          controller.setLooping(true);
          controller.play();
        }).catchError((e) {
          debugPrint('Failed to initialize video: $e');
        });

        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
            decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF334155))),
            child: Stack(children: [
              FutureBuilder(
                future: initializeFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done && controller.value.isInitialized) {
                    return AspectRatio(aspectRatio: controller.value.aspectRatio, child: VideoPlayer(controller));
                  }
                  if (snapshot.hasError) {
                    return const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('Failed to load video', style: TextStyle(color: Colors.white70))));
                  }
                  return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                },
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    controller.pause();
                    controller.dispose();
                    Navigator.of(context).pop();
                  },
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: FloatingActionButton.small(
                  backgroundColor: Colors.black45,
                  onPressed: () {
                    if (controller.value.isPlaying) {
                      controller.pause();
                    } else {
                      controller.play();
                    }
                  },
                  child: const Icon(Icons.play_arrow),
                ),
              )
            ]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final golfers = [
      {
        'name': 'Tiger Woods',
        'stance': 'Balanced stance with feet shoulder-width apart',
        'videoAsset': 'assets/videos/Tiger-Woods.mp4'
      },
      {
        'name': 'Rory McIlroy',
        'stance': 'Athletic stance with dynamic balance',
        'videoAsset': 'assets/videos/Rory-McIlroy.mp4'
      },
      {
        'name': 'Dustin Johnson',
        'stance': 'Wide stance for stability',
        'videoAsset': 'assets/videos/Dustin-Johnson.mp4'
      },
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F1720), Color(0xFF0B1220)])),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: [
              Row(children: [
                OutlinedButton.icon(
                  onPressed: () => context.go('/feedback'),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text('Back to Analysis', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF334155)), backgroundColor: Colors.transparent),
                ),
              ]),
              const SizedBox(height: 12),
              const Text('Famous Golfer Poses', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 6),
              const Text('Learn and compare your posture with professional golfers', style: TextStyle(color: Color(0xFF94A3B8))),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: golfers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final g = golfers[idx];
                    return Card(
                      color: const Color(0xFF0B1220),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF334155))),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(g['name']!, style: const TextStyle(color: Color(0xFFFFC107), fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: g['videoAsset'] != null ? () => _showVideo(context, g['videoAsset'] as String) : null,
                            child: Container(
                              height: 180,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.black),
                              child: Center(
                                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  const Icon(Icons.play_circle_outline, color: Colors.white30, size: 48),
                                  if (g['videoAsset'] != null) const SizedBox(width: 12),
                                  if (g['videoAsset'] != null) const Text('Play video', style: TextStyle(color: Colors.white70))
                                ]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Stance: ${g['stance']}', style: const TextStyle(color: Colors.white70)),
                        ]),
                      ),
                    );
                  },
                ),
              )
            ]),
          ),
        ),
      ),
    );
  }
}
