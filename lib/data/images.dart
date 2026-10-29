import 'dart:convert';
import 'dart:typed_data';

/// Thrown for a photo that isn't JPEG, PNG or WebP.
class UnsupportedImageException implements Exception {
  const UnsupportedImageException();
}

/// The image type of [bytes] from its first bytes, or null if it isn't
/// JPEG, PNG or WebP.
String? imageMediaType(Uint8List bytes) {
  bool startsWith(List<int> prefix, [int offset = 0]) {
    if (bytes.length < offset + prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[offset + i] != prefix[i]) return false;
    }
    return true;
  }

  if (startsWith([0xFF, 0xD8, 0xFF])) return 'image/jpeg';
  if (startsWith([0x89, 0x50, 0x4E, 0x47])) return 'image/png';
  if (startsWith(ascii.encode('RIFF')) && startsWith(ascii.encode('WEBP'), 8)) {
    return 'image/webp';
  }
  return null;
}
