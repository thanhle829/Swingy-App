class AnalysisResult {
  final int postureScore;
  final List<String> keyIssues;
  final List<String> improvements;
  final List<String> bodyAreas;
  final String media;
  final String mediaType; // 'photo' | 'video'

  AnalysisResult({
    required this.postureScore,
    required this.keyIssues,
    required this.improvements,
    required this.bodyAreas,
    required this.media,
    required this.mediaType,
  });
}
