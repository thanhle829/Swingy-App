import 'dart:html' as html;

/// Create a blob URL for the provided bytes (web only).
String? createObjectUrlFromBytes(List<int>? bytes, String? name) {
  if (bytes == null) return null;
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  return url;
}
