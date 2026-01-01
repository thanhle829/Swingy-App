import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/analysis_model.dart';

const String backendBase = String.fromEnvironment('SWINGY_BACKEND', defaultValue: 'http://10.0.2.2:8000');

class AnalysisNotifier extends StateNotifier<AnalysisResult?> {
  AnalysisNotifier() : super(null);

  /// Uploads media to the backend if available and sets analysis state based on response.
  Future<void> setMediaAndAnalyze(String media, String mediaType) async {
    // Optimistically set media so UI can show preview
    state = AnalysisResult(
      postureScore: 0,
      keyIssues: [],
      improvements: [],
      bodyAreas: [],
      media: media,
      mediaType: mediaType,
    );

    // Only attempt backend call for videos and when not running on web
    if (mediaType == 'video' && !kIsWeb) {
      try {
        final uri = Uri.parse('$backendBase/predict_video');

        // Attach file from path (works on non-web platforms); if the path is invalid
        // MultipartFile.fromPath will throw and be caught below.
        final request = http.MultipartRequest('POST', uri);
        request.files.add(await http.MultipartFile.fromPath('file', media));

        final streamed = await request.send();
        final resp = await http.Response.fromStream(streamed);

        if (resp.statusCode == 200) {
          final json = jsonDecode(resp.body);
          final score = (json['postureScore'] ?? 0) as int;
          final keyIssues = List<String>.from(json['keyIssues'] ?? []);
          final improvements = List<String>.from(json['improvements'] ?? []);
          final bodyAreas = List<String>.from(json['bodyAreas'] ?? []);

          final analysis = AnalysisResult(
            postureScore: score,
            keyIssues: keyIssues,
            improvements: improvements,
            bodyAreas: bodyAreas,
            media: media,
            mediaType: mediaType,
          );

          state = analysis;
          return;
        } else {
          debugPrint('Backend responded with ${resp.statusCode}: ${resp.body}');
        }
      } catch (e, st) {
        debugPrint('Backend call failed: $e\n$st');
      }
    }

    // Fallback: Create a mock analysis similar to the original app
    final rnd = Random();
    final score = 70 + rnd.nextInt(31); // 70 - 100

    final analysis = AnalysisResult(
      postureScore: score,
      keyIssues: ['Slight forward head posture', 'Shoulders slightly rounded'],
      improvements: ['Keep shoulders back and relaxed', 'Align head over shoulders', 'Engage core muscles'],
      bodyAreas: ['Head', 'Shoulders', 'Spine', 'Hips', 'Legs'],
      media: media,
      mediaType: mediaType,
    );

    state = analysis;
  }

  void clear() => state = null;
}

final analysisProvider = StateNotifierProvider<AnalysisNotifier, AnalysisResult?>((ref) {
  return AnalysisNotifier();
});
