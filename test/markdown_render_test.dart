import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

const _legalSample = '''
# Privacy Policy

**Effective Date:** 2026-07-03

### 1. Ringkasan

- Email dan kata sandi
- Data sesi anonim

| Purpose | Data Used | Legal Basis |
|---|---|---|
| Provide and operate the App | Account data | Performance of contract |
''';

String _renderedPlainText(WidgetTester tester) {
  return tester
      .widgetList<RichText>(find.byType(RichText))
      .map((widget) => widget.text.toPlainText())
      .join('\n');
}

void main() {
  testWidgets(
    'flutter_markdown_plus renders heading, list and table with legal styleSheet',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Markdown(
              data: _legalSample,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              styleSheet: MarkdownStyleSheet(
                h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                h3: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                p: const TextStyle(fontSize: 14),
                listBullet: const TextStyle(fontSize: 14),
                tableHead: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                tableBody: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      final text = _renderedPlainText(tester);
      expect(text, contains('Privacy Policy'));
      expect(text, contains('Email dan kata sandi'));
      expect(text, contains('Data sesi anonim'));
      expect(text, contains('Provide and operate the App'));
      expect(text, contains('Performance of contract'));

      expect(find.byType(Table), findsOneWidget);
    },
  );
}
