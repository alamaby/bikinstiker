import 'package:bikin_stiker/core/services/auth_callback_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isAuthCallbackUri', () {
    test('auth callback without query returns true', () {
      expect(
        isAuthCallbackUri(Uri.parse('bikinstiker://auth/callback')),
        isTrue,
      );
    });
    test('auth callback with code query returns true', () {
      expect(
        isAuthCallbackUri(
          Uri.parse('bikinstiker://auth/callback?code=abc123'),
        ),
        isTrue,
      );
    });
    test('share-claim custom scheme returns false', () {
      expect(
        isAuthCallbackUri(Uri.parse('bikinstiker://share-claimed/xyz')),
        isFalse,
      );
    });
    test('https share-claim link returns false', () {
      expect(
        isAuthCallbackUri(
          Uri.parse('https://bikinstiker.alamaby.com/share-claimed/xyz'),
        ),
        isFalse,
      );
    });
  });
}
