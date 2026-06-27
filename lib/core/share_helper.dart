import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Fetches image bytes from [signedUrl], writes to a temp file, and opens
/// the native share sheet so the user can send it to WhatsApp or any app.
Future<void> shareStickerImage(String signedUrl) async {
  final uri = Uri.parse(signedUrl);
  final response = await http.get(uri);
  if (response.statusCode != 200) {
    throw Exception('Failed to fetch sticker image (${response.statusCode})');
  }

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/sticker_share.png');
  await file.writeAsBytes(response.bodyBytes, flush: true);

  await Share.shareXFiles([
    XFile(file.path, mimeType: 'image/png'),
  ], subject: 'Check out my sticker!');
}
