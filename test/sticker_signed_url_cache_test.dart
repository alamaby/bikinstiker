import 'dart:io';

import 'package:bikin_stiker/core/errors/failures.dart';
import 'package:bikin_stiker/core/image_cache.dart';
import 'package:bikin_stiker/data/repositories/sticker_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockSupabaseStorageClient extends Mock
    implements SupabaseStorageClient {}

class _MockStorageFileApi extends Mock implements StorageFileApi {}

void main() {
  late Directory tmpDir;
  late _MockSupabaseClient client;
  late _MockSupabaseStorageClient storage;
  late _MockStorageFileApi fileApi;
  late SupabaseStickerRepository repo;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('signed_url_test_');
    client = _MockSupabaseClient();
    storage = _MockSupabaseStorageClient();
    fileApi = _MockStorageFileApi();
    when(() => client.storage).thenReturn(storage);
    when(() => storage.from(any())).thenReturn(fileApi);
    repo = SupabaseStickerRepository(client, ImageCacheService(testOverride: tmpDir));
  });

  tearDown(() async {
    if (await tmpDir.exists()) {
      await tmpDir.delete(recursive: true);
    }
  });

  group('signedUrlForPath failure cache (regression: Sep-2026 report)', () {
    test('a failed sign attempt is NOT cached: retry signs again', () async {
      var calls = 0;
      when(() => fileApi.createSignedUrl(any(), any())).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw Exception('socket blip');
        return 'https://signed.example/2';
      });

      await expectLater(
        repo.signedUrlForPath('user-id/sticker-id.png'),
        throwsA(isA<GenerationFailure>()),
      );
      expect(
        await repo.signedUrlForPath('user-id/sticker-id.png'),
        'https://signed.example/2',
      );
      verify(() => fileApi.createSignedUrl(any(), any())).called(2);
    });

    test('a successful sign is still cached within TTL', () async {
      when(() => fileApi.createSignedUrl(any(), any()))
          .thenAnswer((_) async => 'https://signed.example/1');

      expect(await repo.signedUrlForPath('user-id/a.png'),
          'https://signed.example/1');
      expect(await repo.signedUrlForPath('user-id/a.png'),
          'https://signed.example/1');
      verify(() => fileApi.createSignedUrl(any(), any())).called(1);
    });

    test('empty path returns null without touching storage', () async {
      expect(await repo.signedUrlForPath(''), isNull);
      verifyNever(() => client.storage);
    });
  });
}
