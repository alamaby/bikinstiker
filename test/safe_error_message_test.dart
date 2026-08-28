import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';

import 'package:bikin_stiker/core/errors/safe_error_message.dart';
import 'package:bikin_stiker/l10n/app_localizations.dart';

void main() {
  late final AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('network failures map to connectionError', () {
    const networkRaw = [
      // The exact shape from the reported screenshots.
      'AuthRetryableFetchException: fetching API from '
          'https://abcdefghijklmnop.supabase.co/auth/v1/status failed.',
      'ClientException: XMLHttpRequest error.',
      'SocketException: Failed host lookup: abc.supabase.co (OS Error: '
          'errno = 11001, error = getaddrinfo failed)',
      'SocketException: Connection refused (OS Error: errno = 111)',
      'TimeoutException after 0:00:30.000000',
      'Connection closed while receiving data',
      // GoTrue clock-skew rejection seen at cold start (RCA 2026-08-28).
      'JWT issued at future',
      'AuthApiException(message: JWT issued at future, statusCode: 400)',
    ];
    for (final raw in networkRaw) {
      test('maps: ${raw.split(':')[0]}', () {
        expect(safeErrorMessage(l10n, raw), l10n.connectionError);
      });
    }
  });

  group('internal machinery maps to generic errorOccurred', () {
    const internalRaw = [
      'PostgrestException(message: relation does not exist, code: 42P01)',
      'FunctionException: {"error":"boom"}',
      'Bad state: No element\n#0      ListMixin.firstWhere',
      'AuthException: invalid claim',
      'permission denied for table users',
    ];
    for (final raw in internalRaw) {
      test('maps: ${raw.split('(')[0].split(':')[0]}', () {
        expect(safeErrorMessage(l10n, raw), l10n.errorOccurred);
      });
    }
  });

  group('curated messages pass through', () {
    test('server-authored message stays visible', () {
      expect(safeErrorMessage(l10n, 'Insufficient credits'), 'Insufficient credits');
    });
    test('localized curated message stays visible', () {
      const msg = 'This preset requires a higher tier';
      expect(safeErrorMessage(l10n, msg), msg);
    });
  });

  group('empty input falls back', () {
    test('null -> fallback when provided', () {
      expect(safeErrorMessage(l10n, null, fallback: 'X'), 'X');
    });
    test('empty -> default generic', () {
      expect(safeErrorMessage(l10n, ''), l10n.errorOccurred);
    });
  });
}
