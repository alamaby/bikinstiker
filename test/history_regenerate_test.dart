import 'package:bikin_stiker/core/di.dart';
import 'package:bikin_stiker/core/image_cache.dart';
import 'package:bikin_stiker/core/services/ad_config_service.dart';
import 'package:bikin_stiker/data/models/sticker_generation.dart';
import 'package:bikin_stiker/data/models/sticker_preset.dart';
import 'package:bikin_stiker/data/models/user_subscription.dart';
import 'package:bikin_stiker/data/repositories/preset_repository.dart';
import 'package:bikin_stiker/data/repositories/sticker_repository.dart';
import 'package:bikin_stiker/data/repositories/subscription_repository.dart';
import 'package:bikin_stiker/l10n/app_localizations.dart';
import 'package:bikin_stiker/presentation/blocs/history/history_bloc.dart';
import 'package:bikin_stiker/presentation/blocs/home_prefill/home_prefill_cubit.dart';
import 'package:bikin_stiker/presentation/blocs/preset/preset_bloc.dart';
import 'package:bikin_stiker/presentation/blocs/shell_tab/shell_tab_cubit.dart';
import 'package:bikin_stiker/presentation/blocs/subscription/subscription_bloc.dart';
import 'package:bikin_stiker/presentation/screens/history/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class MockStickerRepository extends Mock implements StickerRepository {}

class MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

class MockPresetRepository extends Mock implements PresetRepository {}

class MockImageCacheService extends Mock implements ImageCacheService {}

class MockAdConfigService extends Mock implements AdConfigService {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a HistoryScreen wrapped in the minimum providers needed to exercise
/// the _regenerate flow.  The [prefill] and [shellTab] params are the single
/// source-of-truth instances the test asserts against.
Widget _wrap(Widget child, {required HomePrefillCubit prefill, required ShellTabCubit shellTab}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<HomePrefillCubit>(create: (_) => prefill),
      BlocProvider<ShellTabCubit>(create: (_) => shellTab),
      BlocProvider<HistoryBloc>(
        create: (_) {
          final bloc = HistoryBloc(getIt<StickerRepository>());
          bloc.emit(HistoryBlocState(
            status: HistoryStatus.success,
            items: [
              StickerGeneration(
                id: 'gen-1',
                userId: 'user-1',
                presetName: 'kawaii',
                userPrompt: 'cat',
                finalPrompt: 'a cute cat',
                imageUrl: 'u/1.webp',
                cost: 1,
                status: StickerStatus.success,
                createdAt: DateTime.now().toUtc(),
              ),
            ],
          ));
          return bloc;
        },
      ),
      BlocProvider<SubscriptionBloc>(
        create: (_) {
          final bloc = SubscriptionBloc(getIt<SubscriptionRepository>());
          bloc.emit(SubscriptionState(
            status: SubscriptionStatus.loaded,
            subscription: UserSubscription(
              id: 'sub-1',
              userId: 'user-1',
              tier: SubscriptionTier.plus,
              startedAt: DateTime.utc(2025, 1, 1),
              expiresAt: DateTime.utc(2027, 1, 1),
              isActive: true,
            ),
          ));
          return bloc;
        },
      ),
      BlocProvider<PresetBloc>(
        create: (_) {
          final bloc = PresetBloc(getIt<PresetRepository>());
          bloc.emit(PresetState(
            status: PresetStatus.success,
            presets: [
              StickerPreset(
                id: 'kawaii',
                label: 'Kawaii',
                description: 'Kawaii style',
                emoji: '🎀',
                requiredRole: StickerPresetRole.free,
              ),
            ],
          ));
          return bloc;
        },
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    ),
  );
}

void main() {
  late MockStickerRepository stickerRepo;
  late MockSubscriptionRepository subRepo;
  late MockPresetRepository presetRepo;
  late MockImageCacheService imageCache;
  late MockAdConfigService adConfig;

  setUpAll(() {
    registerFallbackValue(StickerGeneration(
      id: '',
      userId: '',
      presetName: '',
      userPrompt: '',
      finalPrompt: '',
      imageUrl: null,
      cost: 0,
      status: StickerStatus.unknown,
      createdAt: DateTime(2026),
    ));
    registerFallbackValue(StickerPresetRole.free);
    registerFallbackValue(AdBannerLocation.history);
  });

  setUp(() {
    stickerRepo = MockStickerRepository();
    subRepo = MockSubscriptionRepository();
    presetRepo = MockPresetRepository();
    imageCache = MockImageCacheService();
    adConfig = MockAdConfigService();

    when(() => stickerRepo.getCachedImageFile(any()))
        .thenAnswer((_) async => null);
    when(() => subRepo.watchCurrent(any())).thenAnswer((_) => Stream.value(null));
    when(() => subRepo.fetchCurrent(any())).thenAnswer((_) async => null);
    when(() => presetRepo.fetchPresets(role: any(named: 'role')))
        .thenAnswer((_) async => []);
    when(() => adConfig.bannerAdUnitId(any()))
        .thenReturn('ca-app-pub-3940256099942544/6300978111');

    getIt.registerSingleton<StickerRepository>(stickerRepo);
    getIt.registerSingleton<ImageCacheService>(imageCache);
    getIt.registerSingleton<SubscriptionRepository>(subRepo);
    getIt.registerSingleton<PresetRepository>(presetRepo);
    getIt.registerSingleton<AdConfigService>(adConfig);
  });

  tearDown(() {
    getIt.reset();
  });

  testWidgets('regenerate from History → sets HomePrefill + switches to Home tab',
      (tester) async {
    final prefill = HomePrefillCubit();
    final shellTab = ShellTabCubit();

    await tester.pumpWidget(_wrap(
      const HistoryScreen(),
      prefill: prefill,
      shellTab: shellTab,
    ));
    await tester.pumpAndSettle();

    // Tile visible on History screen.
    expect(find.text('cat'), findsOneWidget);

    // Long-press the tile to open context menu.
    await tester.longPress(find.text('cat'));
    await tester.pumpAndSettle();

    // Tap "Regenerate with same prompt".
    expect(find.text('Regenerate with same prompt'), findsOneWidget);
    await tester.tap(find.text('Regenerate with same prompt'));
    await tester.pumpAndSettle();

    // Assertions:
    // (a) HomePrefillCubit has prompt + presetId set.
    expect(prefill.state.prompt, 'cat');
    expect(prefill.state.presetId, 'kawaii');

    // (b) ShellTabCubit switched to Home (0).
    expect(shellTab.state, 0);

    // (c) No Navigator pop happened — root route still present (no black screen).
    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(Navigator.of(tester.element(find.byType(HistoryScreen))).canPop(),
        isFalse);
  });

  testWidgets(
      'non-Plus user sees snackbar + does NOT switch tab after long-press',
      (tester) async {
    final prefill = HomePrefillCubit();
    final shellTab = ShellTabCubit();

    // Ensure subscription reports non-Plus from the get-go.
    when(() => subRepo.watchCurrent(any())).thenAnswer((_) => Stream.value(null));
    when(() => subRepo.fetchCurrent(any())).thenAnswer((_) async => null);

    // Use a fresh _wrap that produces a non-Plus SubscriptionBloc.
    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider<HomePrefillCubit>(create: (_) => prefill),
        BlocProvider<ShellTabCubit>(create: (_) => shellTab),
        BlocProvider<HistoryBloc>(
          create: (_) {
            final bloc = HistoryBloc(getIt<StickerRepository>());
            bloc.emit(HistoryBlocState(
              status: HistoryStatus.success,
              items: [
                StickerGeneration(
                  id: 'gen-1',
                  userId: 'user-1',
                  presetName: 'kawaii',
                  userPrompt: 'cat',
                  finalPrompt: 'a cute cat',
                  imageUrl: 'u/1.webp',
                  cost: 1,
                  status: StickerStatus.success,
                  createdAt: DateTime.now().toUtc(),
                ),
              ],
            ));
            return bloc;
          },
        ),
        BlocProvider<SubscriptionBloc>(
          create: (_) {
            final bloc = SubscriptionBloc(getIt<SubscriptionRepository>());
            bloc.emit(const SubscriptionState(
              status: SubscriptionStatus.loaded,
              subscription: null,
            ));
            return bloc;
          },
        ),
        BlocProvider<PresetBloc>(
          create: (_) {
            final bloc = PresetBloc(getIt<PresetRepository>());
            bloc.emit(const PresetState(status: PresetStatus.success));
            return bloc;
          },
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const HistoryScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    // Long-press and tap.
    await tester.longPress(find.text('cat'));
    await tester.pumpAndSettle();
    expect(find.text('Regenerate with same prompt'), findsOneWidget);
    await tester.tap(find.text('Regenerate with same prompt'));
    await tester.pumpAndSettle();

    // Should show Plus-feature snackbar and stay on History (no tab switch).
    expect(shellTab.state, 0); // default, never changed
    expect(prefill.state.prompt, isNull); // did not enter regenerate path
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(
        Navigator.of(tester.element(find.byType(HistoryScreen))).canPop(),
        isFalse);
  });
}
