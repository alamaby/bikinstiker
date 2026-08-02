import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Fetches image bytes from [signedUrl], writes to a temp file, and opens
/// the native share sheet so the user can send it to WhatsApp or any app.
/// Determines file extension and MIME type from the response content-type header
/// or by inspecting magic bytes.
Future<void> shareStickerImage(String signedUrl) async {
  final uri = Uri.parse(signedUrl);
  final response = await http.get(uri);
  if (response.statusCode != 200) {
    throw Exception('Failed to fetch sticker image (${response.statusCode})');
  }

  final bytes = response.bodyBytes;
  if (bytes.isEmpty) {
    throw Exception('Downloaded sticker image is empty');
  }

  // Determine format from content-type header or magic bytes
  final contentType = response.headers['content-type']?.toLowerCase() ?? '';
  final (extension, mimeType) = _detectFormat(bytes, contentType);

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/sticker_share$extension');
  await file.writeAsBytes(bytes, flush: true);

  await Share.shareXFiles([
    XFile(file.path, mimeType: mimeType),
  ], subject: 'Check out my sticker!');
}

/// Detects image format from magic bytes and/or content-type header.
/// Returns (extension, mimeType).
(String, String) _detectFormat(Uint8List bytes, String contentType) {
  // PNG: 89 50 4E 47
  if (bytes.length >= 4 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return ('.png', 'image/png');
  }
  // WebP: RIFF....WEBP
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return ('.webp', 'image/webp');
  }
  // JPEG: FF D8 FF
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return ('.jpg', 'image/jpeg');
  }

  // Fallback to content-type header
  if (contentType.contains('png')) return ('.png', 'image/png');
  if (contentType.contains('webp')) return ('.webp', 'image/webp');
  if (contentType.contains('jpeg') || contentType.contains('jpg')) return ('.jpg', 'image/jpeg');

  // Default to PNG for transparency support
  return ('.png', 'image/png');
}
