import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../models/sticker_generation.dart';

class GenerateStickerResult {
  final String stickerId;
  final String signedUrl;
  final String path;
  const GenerateStickerResult({
    required this.stickerId,
    required this.signedUrl,
    required this.path,
  });
}

abstract class StickerRepository {
  Future<GenerateStickerResult> generate({
    required String presetId,
    required String userInput,
  });

  Future<List<StickerGeneration>> fetchHistory({int limit = 50});

  Future<String?> signedUrlForPath(String path, {int ttlSeconds = 3600});
}

class SupabaseStickerRepository implements StickerRepository {
  final SupabaseClient _client;
  static const String _bucket = 'stickers';
  // In-memory cache keyed by storage path. Signed URLs have a 1h TTL on the
  // server side, so caching for the lifetime of the app is safe: repeated
  // calls for the same path (e.g. from a rebuilding History list) share one
  // in-flight request instead of issuing a new one per build.
  final Map<String, Future<String?>> _signedUrlCache = {};

  SupabaseStickerRepository(this._client);

  @override
  Future<GenerateStickerResult> generate({
    required String presetId,
    required String userInput,
  }) async {
    try {
      final res = await _client.functions.invoke(
        'generate-sticker',
        body: {'presetId': presetId, 'userInput': userInput},
      );

      final data = res.data;
      if (data is Map && data['error'] != null) {
        final msg = data['error'].toString();
        if (msg.toLowerCase().contains('insufficient')) {
          throw const InsufficientCreditsFailure();
        }
        throw GenerationFailure(msg);
      }

      if (data is! Map || data['stickerId'] == null || data['signedUrl'] == null) {
        throw const GenerationFailure('Malformed response from server');
      }

      return GenerateStickerResult(
        stickerId: data['stickerId'] as String,
        signedUrl: data['signedUrl'] as String,
        path: data['path'] as String? ?? '',
      );
    } on FunctionException catch (e) {
      final detail = e.details;
      if (detail is Map && detail['error'] is String) {
        final msg = detail['error'] as String;
        if (msg.toLowerCase().contains('insufficient')) {
          throw const InsufficientCreditsFailure();
        }
        throw GenerationFailure(msg);
      }
      throw GenerationFailure(e.toString());
    } on Failure {
      rethrow;
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<List<StickerGeneration>> fetchHistory({int limit = 50}) async {
    final rows = await _client
        .from('sticker_generations')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map<StickerGeneration>((r) => StickerGeneration.fromJson(r)).toList();
  }

  @override
  Future<String?> signedUrlForPath(String path, {int ttlSeconds = 3600}) async {
    if (path.isEmpty) return null;
    return _signedUrlCache.putIfAbsent(path, () => _fetchSignedUrl(path, ttlSeconds));
  }

  Future<String?> _fetchSignedUrl(String path, int ttlSeconds) async {
    try {
      return await _client.storage.from(_bucket).createSignedUrl(path, ttlSeconds);
    } catch (_) {
      return null;
    }
  }
}
