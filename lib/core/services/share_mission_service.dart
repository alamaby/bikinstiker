import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/share_token.dart';

/// Coordinates the two halves of the share-to-social-media mission:
///
/// 1. Outbound: request a single-use share token from the server, then open
///    the native share sheet with the resulting link baked into the text.
/// 2. Inbound: surface deep-link opens (`bikinstiker.com/share-claimed/...`
///    via Universal/App Links or `bikinstiker://share-claimed/...` via the
///    custom URL scheme) so the MissionBloc can convert the click into a
///    completed mission and a success UI.
class ShareMissionService {
  ShareMissionService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client,
      _appLinks = AppLinks();

  final SupabaseClient _client;
  final AppLinks _appLinks;

  StreamController<ShareClaimResult>? _claimController;
  StreamSubscription<Uri>? _linkSubscription;
  Uri? _initialLink;
  bool _initialized = false;

  /// Stream of share-claim deep links. Each emission represents a recipient
  /// opening the shared link. The MissionBloc listens to this.
  Stream<ShareClaimResult> get claimStream {
    _ensureInitialized();
    return _claimController!.stream;
  }

  /// First deep link that opened the app (cold start). May be null if the
  /// app was launched normally. Consumed exactly once.
  Future<ShareClaimResult?> consumeInitialLink() async {
    _ensureInitialized();
    final uri = _initialLink;
    _initialLink = null;
    if (uri == null) return null;
    return _maybeBuildClaim(uri);
  }

  /// Mints a fresh single-use token from the server.
  Future<ShareTokenInfo> requestToken(String missionId) async {
    final rows = await _client.rpc(
      'request_share_token',
      params: {'p_mission_id': missionId},
    );
    final list = rows as List;
    if (list.isEmpty) {
      throw Exception('Share token server returned no rows');
    }
    return ShareTokenInfo.fromJson(list.first as Map<String, dynamic>);
  }

  /// Opens the native share sheet with the link baked into the message text.
  /// Returns true if the share sheet closed without an error; does not mean
  /// the user actually shared (native API cannot distinguish).
  Future<bool> openShareSheet({
    required String shareUrl,
    String? message,
    Rect? sharePositionOrigin,
  }) async {
    final text = message != null ? '$message\n$shareUrl' : shareUrl;
    final params = ShareParams(
      text: text,
      subject: 'BikinStiker - share to earn',
      sharePositionOrigin: sharePositionOrigin,
    );
    final result = await SharePlus.instance.share(params);
    return result.status == ShareResultStatus.success ||
        result.status == ShareResultStatus.dismissed;
  }

  void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    _claimController = StreamController<ShareClaimResult>.broadcast(
      onListen: _startListening,
      onCancel: _stopListening,
    );
  }

  Future<void> _startListening() async {
    try {
      _initialLink ??= await _appLinks.getInitialLink();
      if (_initialLink != null) {
        final claim = _maybeBuildClaim(_initialLink!);
        if (claim != null) {
          _initialLink = null;
          _claimController?.add(claim);
        }
      }
      _linkSubscription ??= _appLinks.uriLinkStream.listen((uri) {
        final claim = _maybeBuildClaim(uri);
        if (claim != null) {
          _claimController?.add(claim);
        }
      });
    } catch (e) {
      // app_links can throw on platforms without deep-link support; we still
      // emit no events rather than failing the whole service.
      // ignore: avoid_print
      print('ShareMissionService: failed to start deep link listener: $e');
    }
  }

  void _stopListening() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }

  /// Returns a [ShareClaimResult] if [uri] is a share-claim deep link.
  /// Accepts both the https host (Universal/App Links) and the custom URL
  /// scheme bikinstiker://... which serves as a fallback on platforms
  /// without domain association set up.
  ShareClaimResult? _maybeBuildClaim(Uri uri) {
    final isHttpsClaim =
        uri.scheme == 'https' &&
        uri.host == 'bikinstiker.com' &&
        uri.pathSegments.isNotEmpty &&
        (uri.pathSegments.first == 'share-claimed' ||
            uri.pathSegments.first == 'r');
    final isCustomClaim =
        uri.scheme == 'bikinstiker' && uri.host == 'share-claimed';
    if (!isHttpsClaim && !isCustomClaim) return null;
    return ShareClaimResult.fromUri(uri);
  }

  Future<void> dispose() async {
    await _linkSubscription?.cancel();
    await _claimController?.close();
  }
}
