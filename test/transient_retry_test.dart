import 'package:flutter_test/flutter_test.dart';

import 'package:bikin_stiker/core/errors/transient_retry.dart';

void main() {
  test('returns immediately when fn succeeds on first attempt', () async {
    final delays = <Duration>[];
    final result = await retryOnTransient<int>(
      () async => 7,
      delay: (d) async => delays.add(d),
    );
    expect(result, 7);
    expect(delays, isEmpty);
  });

  test('retries transient failures with 500ms then 1s backoff', () async {
    final delays = <Duration>[];
    var calls = 0;
    final result = await retryOnTransient<String>(
      () async {
        calls++;
        if (calls < 3) throw Exception('jwt issued at future');
        return 'ok';
      },
      delay: (d) async => delays.add(d),
    );
    expect(result, 'ok');
    expect(calls, 3);
    expect(delays, const [Duration(milliseconds: 500), Duration(seconds: 1)]);
  });

  test('rethrows after maxRetries is exhausted', () async {
    var calls = 0;
    await expectLater(
      retryOnTransient<void>(
        () async {
          calls++;
          throw Exception('always failing');
        },
        maxRetries: 2,
        delay: (_) async {},
      ),
      throwsException,
    );
    // 1 initial attempt + 2 retries.
    expect(calls, 3);
  });

  test('rethrows immediately when isTransient returns false', () async {
    final delays = <Duration>[];
    var calls = 0;
    await expectLater(
      retryOnTransient<void>(
        () async {
          calls++;
          throw Exception('permanent');
        },
        isTransient: (_) => false,
        delay: (d) async => delays.add(d),
      ),
      throwsException,
    );
    expect(calls, 1);
    expect(delays, isEmpty);
  });
}
