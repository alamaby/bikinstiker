import '../../l10n/app_localizations.dart';

/// Maps a raw error string (exception text, bloc errorMessage, failure
/// message) to a user-safe localized message. Raw exceptions routinely
/// contain backend endpoints, host names, and stack details — none of which
/// should ever reach the UI. Curated server messages ("Insufficient
/// credits") pass through unchanged; anything matching internal/network
/// markers collapses to a generic localized message.
///
/// Blocs store raw strings (they have no l10n access); call this at the
/// render site.
String safeErrorMessage(
  AppLocalizations l10n,
  String? raw, {
  String? fallback,
}) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return fallback ?? l10n.errorOccurred;
  final lower = text.toLowerCase();

  // Network / connectivity failures — including Supabase client wrappers.
  // Plain AuthException is NOT here: only the retryable-fetch variant is
  // network-specific; other auth errors fall through to the internal bucket.
  if (_containsAny(lower, const [
    'socketexception',
    'clientexception',
    'failed host lookup',
    'connection aborted',
    'connection refused',
    'connection closed',
    'connection reset',
    'timed out',
    'timeoutexception',
    'authretryablefetchexception',
    'errno',
    'xmlhttprequesterror',
    'network',
    'supabase.',
  ])) {
    return l10n.connectionError;
  }

  // Internal machinery (stack traces, DB/protocol details, Dart exception
  // formatting) — safe to hide behind a generic message.
  if (_containsAny(lower, const [
    'exception(',
    'exception:',
    'error:',
    'postgrest',
    'functionexception',
    'failure:',
    'violates',
    'permission denied',
    'stack trace',
    '#0      ',
  ])) {
    return l10n.errorOccurred;
  }

  return text;
}

bool _containsAny(String haystack, List<String> needles) {
  for (final needle in needles) {
    if (haystack.contains(needle)) return true;
  }
  return false;
}
