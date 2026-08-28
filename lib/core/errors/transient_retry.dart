/// Retries [fn] on transient startup failures with short exponential backoff.
///
/// Cold-start authenticated calls can fail with transient auth errors —
/// e.g. Supabase GoTrue rejecting a cached token with "JWT issued at future"
/// when server-side clocks momentarily disagree — or one-shot network blips.
/// These resolve on a simple retry, so the consent gate retries silently
/// before surfacing an error screen.
///
/// READ-ONLY calls only: never wrap non-idempotent writes (submit paths must
/// rely on their own idempotency keys if ever wrapped).
///
/// [isTransient] narrows what is retried; by default every failure is
/// retried. [delay] is injectable for deterministic tests.
Future<T> retryOnTransient<T>(
  Future<T> Function() fn, {
  int maxRetries = 2,
  bool Function(Object error)? isTransient,
  Future<void> Function(Duration delay)? delay,
}) async {
  Future<void> defaultDelay(Duration d) => Future<void>.delayed(d);
  final wait = delay ?? defaultDelay;
  var attempt = 0;
  while (true) {
    try {
      return await fn();
    } catch (e) {
      final transient = isTransient?.call(e) ?? true;
      attempt++;
      if (!transient || attempt > maxRetries) rethrow;
      await wait(Duration(milliseconds: 500 << (attempt - 1)));
    }
  }
}
