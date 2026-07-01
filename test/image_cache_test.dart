import 'dart:io';
import 'dart:typed_data';

import 'package:bikin_stiker/core/image_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tmpDir;
  late ImageCacheService service;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('image_cache_test_');
    service = ImageCacheService(testOverride: tmpDir);
  });

  tearDown(() async {
    if (await tmpDir.exists()) {
      await tmpDir.delete(recursive: true);
    }
  });

  group('ImageCacheService', () {
    test('get returns null for missing file', () async {
      expect(await service.get('nonexistent'), isNull);
    });

    test('put then get returns the file', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      await service.put('test/path.webp', bytes);
      final file = await service.get('test/path.webp');
      expect(file, isNotNull);
      expect(await file!.readAsBytes(), bytes);
    });

    test('exists returns correct bool', () async {
      expect(await service.exists('test/path.webp'), isFalse);
      await service.put('test/path.webp', Uint8List.fromList([1]));
      expect(await service.exists('test/path.webp'), isTrue);
    });

    test('remove deletes the file', () async {
      await service.put('test/path.webp', Uint8List.fromList([1]));
      expect(await service.exists('test/path.webp'), isTrue);
      await service.remove('test/path.webp');
      expect(await service.exists('test/path.webp'), isFalse);
    });

    test('different storage paths produce different cache keys', () async {
      await service.put('path/a.webp', Uint8List.fromList([1]));
      await service.put('path/b.webp', Uint8List.fromList([2]));
      final fileA = await service.get('path/a.webp');
      final fileB = await service.get('path/b.webp');
      expect(fileA, isNotNull);
      expect(fileB, isNotNull);
      expect(await fileA!.readAsBytes(), [1]);
      expect(await fileB!.readAsBytes(), [2]);
    });

    test('put overwrites existing file', () async {
      await service.put('test.webp', Uint8List.fromList([1]));
      await service.put('test.webp', Uint8List.fromList([2, 3]));
      final file = await service.get('test.webp');
      expect(await file!.readAsBytes(), [2, 3]);
    });
  });
}
