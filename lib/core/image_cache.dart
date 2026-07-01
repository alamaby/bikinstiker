import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class ImageCacheService {
  static const _subdir = 'sticker_images';
  static const _maxSizeBytes = 50 * 1024 * 1024; // 50 MB

  final Directory? _testOverride;

  ImageCacheService({Directory? testOverride}) : _testOverride = testOverride;

  Future<Directory> _cacheDir() async {
    if (_testOverride != null) {
      if (!await _testOverride.exists()) {
        await _testOverride.create(recursive: true);
      }
      return _testOverride;
    }
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_subdir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _fileKey(String storagePath) => storagePath.hashCode.toRadixString(36);

  Future<File?> get(String storagePath) async {
    final dir = await _cacheDir();
    final file = File('${dir.path}/${_fileKey(storagePath)}');
    if (await file.exists()) return file;
    return null;
  }

  Future<File> put(String storagePath, Uint8List bytes) async {
    final dir = await _cacheDir();
    final file = File('${dir.path}/${_fileKey(storagePath)}');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<bool> exists(String storagePath) async {
    final dir = await _cacheDir();
    final file = File('${dir.path}/${_fileKey(storagePath)}');
    return file.exists();
  }

  Future<void> remove(String storagePath) async {
    final dir = await _cacheDir();
    final file = File('${dir.path}/${_fileKey(storagePath)}');
    if (await file.exists()) await file.delete();
  }

  Future<void> enforceMaxSize({int maxBytes = _maxSizeBytes}) async {
    final dir = await _cacheDir();
    final files = await dir
        .list()
        .where((e) => e is File)
        .cast<File>()
        .toList();

    var total = 0;
    for (final f in files) {
      total += await f.length();
    }
    if (total <= maxBytes) return;

    files.sort(
      (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
    );

    for (final f in files) {
      if (total <= maxBytes) break;
      final size = await f.length();
      await f.delete();
      total -= size;
    }
  }
}
