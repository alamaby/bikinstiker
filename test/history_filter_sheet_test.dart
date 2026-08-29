import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bikin_stiker/l10n/app_localizations.dart';
import 'package:bikin_stiker/presentation/screens/history/widgets/history_filter_chips.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(child: child),
    ),
  );
}

void main() {
  const options = [
    FilterOption(value: 'a', label: 'Alpha'),
    FilterOption(value: 'b', label: 'Beta', emoji: '🎨'),
  ];

  testWidgets('tap chip opens bottom sheet with selected check-marked',
      (tester) async {
    await tester.pumpWidget(_wrap(FilterChipDropdown<String>(
      label: 'Style',
      title: 'Style',
      current: 'a',
      options: options,
      onSelected: (_) {},
    )));

    await tester.tap(find.text('Style: Alpha'));
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });

  testWidgets('selecting an option closes the sheet and fires onSelected',
      (tester) async {
    final selected = <String>[];
    await tester.pumpWidget(_wrap(FilterChipDropdown<String>(
      label: 'Style',
      title: 'Style',
      current: 'a',
      options: options,
      onSelected: selected.add,
    )));

    await tester.tap(find.text('Style: Alpha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();

    expect(selected, ['b']);
    // Sheet closed — options no longer on screen as sheet rows.
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('chip label reflects the current selection', (tester) async {
    await tester.pumpWidget(_wrap(FilterChipDropdown<String>(
      label: 'Style',
      title: 'Style',
      current: 'b',
      options: options,
      onSelected: (_) {},
    )));

    expect(find.text('Style: Beta'), findsOneWidget);
  });

  testWidgets('locked chip shows padlock and does not open a sheet',
      (tester) async {
    final selected = <String>[];
    await tester.pumpWidget(_wrap(FilterChipDropdown<String>(
      label: 'Style',
      title: 'Style',
      current: 'a',
      options: options,
      onSelected: selected.add,
      locked: true,
    )));

    expect(find.text('Style: Alpha'), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);

    // The locked chip has no tap handler — tapping it must not open a sheet.
    await tester.tap(find.text('Style'));
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsNothing);
    expect(selected, isEmpty);
  });
}
