import 'package:bikin_stiker/core/di.dart';
import 'package:bikin_stiker/data/models/sticker_pack.dart';
import 'package:bikin_stiker/data/models/sticker_pack_item.dart';
import 'package:bikin_stiker/data/repositories/showcase_repository.dart';
import 'package:bikin_stiker/data/repositories/sticker_pack_repository.dart';
import 'package:bikin_stiker/l10n/app_localizations.dart';
import 'package:bikin_stiker/presentation/blocs/sticker_pack/sticker_pack_bloc.dart';
import 'package:bikin_stiker/presentation/screens/packs/pack_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStickerPackRepository extends Mock implements StickerPackRepository {}

/// ShowcaseRepository fake: hanya metode yang dipakai layar detail.
class _FakeShowcaseRepository implements ShowcaseRepository {
  _FakeShowcaseRepository({String initialTier = 'plus'}) : tier = initialTier;

  String tier;
  final Set<String> listedIds = {'p1'};
  int viewerTierCalls = 0;

  @override
  Future<String> fetchViewerTier() async {
    viewerTierCalls++;
    return tier;
  }

  @override
  Future<Set<String>> fetchListedPackIds() async => listedIds;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

Widget _buildTestApp(Widget screen) {
  return MaterialApp(
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: BlocProvider<StickerPackBloc>(
      create: (_) => StickerPackBloc(getIt<StickerPackRepository>()),
      child: screen,
    ),
  );
}

StickerPack _dummyPack() {
  final now = DateTime(2026, 8, 26);
  return StickerPack(
    id: 'p1',
    userId: 'u1',
    name: 'My Pack',
    packIdentifier: 'u1-p1',
    trayIconPath: 'tray_icons/u1/p1.png',
    stickerCount: 3,
    isActive: true,
    isLocked: false,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late _MockStickerPackRepository packRepo;
  late _FakeShowcaseRepository showcaseRepo;

  setUp(() {
    packRepo = _MockStickerPackRepository();
    getIt.registerSingleton<StickerPackRepository>(packRepo);

    showcaseRepo = _FakeShowcaseRepository();
    getIt.registerSingleton<ShowcaseRepository>(showcaseRepo);

    when(() => packRepo.getPackDetail('p1')).thenAnswer(
      (_) async => (
        pack: _dummyPack(),
        items: <StickerPackItem>[],
      ),
    );
  });

  tearDown(() {
    getIt.reset();
  });

  Future<void> pumpDetail(WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp(const PackDetailScreen(packId: 'p1')));
    await tester.pump(); // postFrameCallback: detail load dispatched
    await tester.pumpAndSettle();
  }

  group('PackDetailScreen showcase gate', () {
    testWidgets('shows storefront action when pack is editable', (tester) async {
      await pumpDetail(tester);

      expect(find.byTooltip('List on Showcase'), findsOneWidget);
    });

    testWidgets('free tier tap shows Plus-required snackbar', (tester) async {
      showcaseRepo.tier = 'free';
      await pumpDetail(tester);

      await tester.tap(find.byTooltip('List on Showcase'));
      await tester.pumpAndSettle();

      expect(
        find.text('Showcase listing is a Plus feature.'),
        findsOneWidget,
      );
      // Form sheet tidak boleh terbuka untuk tier free.
      expect(find.text('Base price (credits)'), findsNothing);
      expect(showcaseRepo.viewerTierCalls, 1);
    });

    testWidgets('listed badge state refreshes after onChanged callback',
        (tester) async {
      await pumpDetail(tester);
      expect(showcaseRepo.listedIds.contains('p1'), isTrue);
    });
  });
}
