import 'dart:convert';
import 'dart:typed_data';

/// Decodes an optional base64 launcher bitmap, returning null for invalid data.
Uint8List? decodeLauncherIcon(String? encoded) {
  if (encoded == null || encoded.isEmpty) return null;
  try {
    return base64Decode(encoded);
  } catch (_) {
    return null;
  }
}
