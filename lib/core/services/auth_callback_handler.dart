import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Returns true if [uri] is a Supabase auth callback
/// (`bikinstiker://auth/callback`, with or without query parameters).
/// Kept top-level so it can be unit-tested without mocks.
bool isAuthCallbackUri(Uri uri) =>
    uri.scheme == 'bikinstiker' && uri.host == 'auth';

/// Consumes Supabase auth-callback deep links and exchanges them for a
/// session via `getSessionFromUrl`.
///
/// Covers cold start ([AppLinks.getInitialLink]) and warm start
/// ([AppLinks.uriLinkStream]). Share-claim links are ignored here; they
/// belong to [ShareMissionService] whose filter is disjoint.
class AuthCallbackHandler {
  AuthCallbackHandler({SupabaseClient? client, AppLinks? appLinks})
      : _client = client ?? Supabase.instance.client,
        _appLinks = appLinks ?? AppLinks();

  final SupabaseClient _client;
  final AppLinks _appLinks;

  StreamSubscription<Uri>? _linkSubscription;
  bool _initialized = false;

  /// Starts listening. Safe to call once; subsequent calls are no-ops.
  /// Never throws: startup must not crash because of deep links.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) await _consume(initial);
      _linkSubscription = _appLinks.uriLinkStream.listen(_consume);
    } catch (e) {
      debugPrint('AuthCallbackHandler: failed to start listener: $e');
    }
  }

  Future<void> _consume(Uri uri) async {
    if (!isAuthCallbackUri(uri)) return;
    try {
      await _client.auth.getSessionFromUrl(uri);
    } catch (e) {
      // The same link can be observed twice (initial + stream, or double
      // emission). An already-consumed link is not an error.
      final msg = e.toString().toLowerCase();
      if (msg.contains('flow_state') || msg.contains('already')) return;
      debugPrint('AuthCallbackHandler: getSessionFromUrl failed: $e');
    }
  }

  Future<void> dispose() async {
    await _linkSubscription?.cancel();
    _linkSubscription = null;
  }
}
