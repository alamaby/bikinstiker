import 'dart:io';

import 'package:bikin_stiker/core/di.dart';
import 'package:bikin_stiker/core/image_cache.dart';
import 'package:bikin_stiker/data/repositories/sticker_repository.dart';
import 'package:bikin_stiker/l10n/app_localizations.dart';
import 'package:bikin_stiker/presentation/widgets/retryable_cached_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStickerRepository extends Mock implements StickerRepository {}

class _MockImageCacheService extends Mock implements ImageCacheService {}

/// NOTE: no real I/O or image decoding happens here on purpose —
/// `testWidgets` runs in a FakeAsync zone where awaiting real async I/O
/// deadlocks, and [Image.file] decoding never resolves in this
/// environment's flutter_tester. The widget exposes an [imageBuilder]
/// seam, so tests inject a stub and assert on states/transitions.
const _stubKey = Key('stub-image');

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: SizedBox(width: 200, height: 200, child: child)),
  );
}

Widget _stubImage(
  BuildContext context,
  File file,
  ImageErrorWidgetBuilder onError,
) =>
    Container(key: _stubKey);

/// Image provider that fails immediately without touching any codec.
/// Proved to resolve fast in this environment's flutter_tester (where real
/// image decoding never completes), so error paths can be tested.
class _FailingImageProvider extends ImageProvider<_FailingImageProvider> {
  int resolutions = 0;

  @override
  Future<_FailingImageProvider> obtainKey(ImageConfiguration configuration) {
    resolutions++;
    return SynchronousFuture<_FailingImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
      _FailingImageProvider key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(
      Future<ImageInfo>.error(Exception('bad pixels')),
    );
  }
}

void main() {
  late _MockStickerRepository repo;
  late _MockImageCacheService imageCache;

  setUp(() {
    repo = _MockStickerRepository();
    imageCache = _MockImageCacheService();
    getIt.registerSingleton<StickerRepository>(repo);
    getIt.registerSingleton<ImageCacheService>(imageCache);
    when(() => imageCache.remove(any())).thenAnswer((_) async {});
  });

  tearDown(() {
    getIt.reset();
  });

  Future<void> settleFrames(WidgetTester tester, [int frames = 5]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Widget subject(String? path) => RetryableCachedImage(
        storagePath: path,
        imageBuilder: _stubImage,
      );

  group('RetryableCachedImage', () {
    testWidgets('shows image when load succeeds', (tester) async {
      when(() => repo.getCachedImageFile(any()))
          .thenAnswer((_) async => File('good.bin'));

      await tester.pumpWidget(_buildTestApp(subject('u/1.png')));
      await settleFrames(tester);

      expect(find.byKey(_stubKey), findsOneWidget);
      verify(() => repo.getCachedImageFile('u/1.png')).called(1);
    });

    testWidgets('error on failure, tap retries and shows image',
        (tester) async {
      var calls = 0;
      when(() => repo.getCachedImageFile(any())).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw Exception('socket blip');
        return File('good.bin');
      });

      await tester.pumpWidget(_buildTestApp(subject('u/1.png')));
      await settleFrames(tester);
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.broken_image_outlined));
      await settleFrames(tester);

      expect(find.byKey(_stubKey), findsOneWidget);
      verify(() => repo.getCachedImageFile('u/1.png')).called(2);
    });

    testWidgets('completed load with null file shows error and retries',
        (tester) async {
      var calls = 0;
      when(() => repo.getCachedImageFile(any())).thenAnswer((_) async {
        calls++;
        if (calls == 1) return null; // e.g. HTTP 404 on download
        return File('good.bin');
      });

      await tester.pumpWidget(_buildTestApp(subject('u/1.png')));
      await settleFrames(tester);
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.broken_image_outlined));
      await settleFrames(tester);

      expect(find.byKey(_stubKey), findsOneWidget);
    });

    testWidgets('empty path shows placeholder without repository call',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(subject('')));
      await settleFrames(tester);

      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
      verifyNever(() => repo.getCachedImageFile(any()));
    });

    testWidgets('manual retry purges the local entry before reloading',
        (tester) async {
      const badPath = 'u/bad.bin';
      var calls = 0;
      when(() => repo.getCachedImageFile(any())).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw Exception('socket blip');
        return File('good.bin');
      });

      await tester.pumpWidget(_buildTestApp(subject(badPath)));
      await settleFrames(tester);
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.broken_image_outlined));
      await settleFrames(tester);

      expect(find.byKey(_stubKey), findsOneWidget);
      expect(calls, 2);
      // A corrupt cached file must not trap the retry: the stale local
      // entry is removed before reloading.
      verify(() => imageCache.remove(badPath)).called(1);
    });

    testWidgets(
        'corrupt file triggers errorBuilder purge, reloads once, no loop',
        (tester) async {
      const corruptPath = 'u/corrupt.bin';
      final failingProvider = _FailingImageProvider();
      var repoCalls = 0;
      when(() => repo.getCachedImageFile(any())).thenAnswer((_) async {
        repoCalls++;
        // Bytes are irrelevant: the injected provider always fails fast,
        // simulating undecodable (corrupt) cached bytes without a codec.
        return File(corruptPath);
      });

      await tester.pumpWidget(
        _buildTestApp(
          RetryableCachedImage(
            storagePath: corruptPath,
            imageBuilder: (context, file, onError) => Image(
              image: failingProvider,
              errorBuilder: onError,
            ),
          ),
        ),
      );
      await settleFrames(tester, 10);

      // Persistent failure settles on the error icon (manually retryable).
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
      // The corrupt entry was purged exactly once...
      verify(() => imageCache.remove(corruptPath)).called(1);
      // ...and exactly one reload followed the initial load...
      verify(() => repo.getCachedImageFile(corruptPath)).called(2);
      expect(repoCalls, 2);
      expect(failingProvider.resolutions, 2);
      // ...with no further looping: settle again, no new interactions.
      await settleFrames(tester, 10);
      verifyNoMoreInteractions(imageCache);
      verifyNoMoreInteractions(repo);
      expect(repoCalls, 2);
      expect(failingProvider.resolutions, 2);
    });
  });
}
