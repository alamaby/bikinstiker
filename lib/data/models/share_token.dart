/// Result of the `request_share_token` RPC.
class ShareTokenInfo {
  final String token;
  final String shareUrl;
  final DateTime expiresAt;

  const ShareTokenInfo({
    required this.token,
    required this.shareUrl,
    required this.expiresAt,
  });

  factory ShareTokenInfo.fromJson(Map<String, dynamic> json) {
    return ShareTokenInfo(
      token: json['token'] as String,
      shareUrl: json['share_url'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}

/// Result of the share link being opened by a recipient (the deep link that
/// the app receives back from the Edge Function).
class ShareClaimResult {
  final String missionId;
  final int creditsAwarded;
  final bool success;
  final String? errorCode;

  const ShareClaimResult({
    required this.missionId,
    required this.creditsAwarded,
    required this.success,
    this.errorCode,
  });

  factory ShareClaimResult.fromUri(Uri uri) {
    final params = uri.queryParameters;
    final missionId = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : (params['mission_id'] ?? params['mission'] ?? '');
    final status = params['status'];
    final err = params['share_error'];
    return ShareClaimResult(
      missionId: missionId,
      creditsAwarded: int.tryParse(params['credits'] ?? '') ?? 0,
      success: status == 'ok' && err == null,
      errorCode: err,
    );
  }
}
