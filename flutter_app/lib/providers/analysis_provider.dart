import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analysis_model.dart';

class AnalysisNotifier extends StateNotifier<AnalysisResult?> {
  AnalysisNotifier() : super(null);

  void setMediaAndAnalyze(String media, String mediaType) {
    // Create a mock analysis similar to the original app
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
