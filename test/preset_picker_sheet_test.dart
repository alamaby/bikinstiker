import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bikin_stiker/data/models/sticker_preset.dart';
import 'package:bikin_stiker/l10n/app_localizations.dart';
import 'package:bikin_stiker/presentation/widgets/preset_picker_sheet.dart';

// Fixture ids deliberately avoid keys handled by preset_localizations so the
// tiles fall back to the server-provided label (= id here).
StickerPreset _seasonal({
  required String id,
  required StickerPresetRole role,
  required DateTime validUntil,
}) {
  return StickerPreset.fromJson({
    'id': id,
    'label': id,
    'description': '$id description',
    'emoji': '🎃',
    'requiredRole': role.name,
    'validUntil': validUntil.toIso8601String(),
  });
}

StickerPreset _regular({
  required String id,
  required StickerPresetRole role,
}) {
  return StickerPreset.fromJson({
    'id': id,
    'label': id,
    'description': '$id description',
    'emoji': '🎨',
    'requiredRole': role.name,
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('seasonal section renders above regular presets',
      (tester) async {
    await tester.pumpWidget(_wrap(PresetPickerSheet(
      presets: [
        _regular(id: 'zz_regular_a', role: StickerPresetRole.free),
        _seasonal(
          id: 'aa_seasonal',
          role: StickerPresetRole.free,
          validUntil: DateTime.utc(2026, 9, 20, 16, 59, 59),
        ),
        _regular(id: 'zz_regular_b', role: StickerPresetRole.free),
      ],
      selectedId: null,
      viewRole: StickerPresetRole.free,
      onSelect: (_) {},
    )));

    expect(find.text('Seasonal Styles'), findsOneWidget);
    // The seasonal tile renders above both regular tiles in sheet order.
    final seasonalDy = tester.getTopLeft(find.text('aa_seasonal')).dy;
    final firstRegularDy = tester.getTopLeft(find.text('zz_regular_a')).dy;
    final secondRegularDy = tester.getTopLeft(find.text('zz_regular_b')).dy;
    expect(seasonalDy, lessThan(firstRegularDy));
    expect(seasonalDy, lessThan(secondRegularDy));
  });

  testWidgets('limited badge and end date shown on seasonal tiles',
      (tester) async {
    await tester.pumpWidget(_wrap(PresetPickerSheet(
      presets: [
        _seasonal(
          id: 'aa_seasonal',
          role: StickerPresetRole.free,
          validUntil: DateTime.utc(2026, 9, 20, 16, 59, 59),
        ),
      ],
      selectedId: null,
      viewRole: StickerPresetRole.free,
      onSelect: (_) {},
    )));

    expect(find.text('Limited'), findsOneWidget);
    // End date mirrors the tile's own localized formatting; assert on the
    // year so the expectation is timezone-independent.
    expect(find.textContaining('2026'), findsOneWidget);
  });

  testWidgets('plus tile is locked for free viewer: snackbar, no selection',
      (tester) async {
    final selected = <String>[];
    await tester.pumpWidget(_wrap(PresetPickerSheet(
      presets: [
        _seasonal(
          id: 'aa_locked_plus',
          role: StickerPresetRole.plus,
          validUntil: DateTime.utc(2026, 10, 31, 16, 59, 59),
        ),
        _regular(id: 'zz_regular', role: StickerPresetRole.free),
      ],
      selectedId: null,
      viewRole: StickerPresetRole.free,
      onSelect: selected.add,
    )));

    await tester.tap(find.text('aa_locked_plus'));
    await tester.pumpAndSettle();

    expect(selected, isEmpty);
    expect(find.text('This style is exclusive to Plus.'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('free tile remains selectable for free viewer', (tester) async {
    final selected = <String>[];
    await tester.pumpWidget(_wrap(PresetPickerSheet(
      presets: [
        _regular(id: 'zz_regular', role: StickerPresetRole.free),
        _regular(id: 'zz_locked_other', role: StickerPresetRole.plus),
      ],
      selectedId: null,
      viewRole: StickerPresetRole.free,
      onSelect: selected.add,
    )));

    await tester.tap(find.text('zz_regular'));
    await tester.pumpAndSettle();

    expect(selected, ['zz_regular']);
  });

  testWidgets('locked regular presets show padlock without seasonal header',
      (tester) async {
    await tester.pumpWidget(_wrap(PresetPickerSheet(
      presets: [
        _regular(id: 'zz_locked_only', role: StickerPresetRole.plus),
      ],
      selectedId: null,
      viewRole: StickerPresetRole.free,
      onSelect: (_) {},
    )));

    expect(find.text('Seasonal Styles'), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });
}
