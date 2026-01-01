// Stub implementation for platforms without dart:io (web)
// This file is chosen by conditional import when dart:io is unavailable.

/// Returns a platform-specific File-like object for the given path.
/// On web this throws since files are not available via dart:io.
dynamic fileFromPath(String path) => throw UnsupportedError('File is not available on this platform');
