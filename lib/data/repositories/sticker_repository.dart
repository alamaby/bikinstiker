import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../../core/image_cache.dart';
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
    String? caption,
    String? captionPosition,
  });

  Future<List<StickerGeneration>> fetchHistory({int limit = 50});

  Future<String?> signedUrlForPath(String path, {int ttlSeconds = 3600});

  /// Returns a locally-cached image file for [storagePath].
  /// Fetches from network on cache miss.
  Future<File?> getCachedImageFile(String storagePath);
}

class _CachedSignedUrl {
  final Future<String?> future;
  final DateTime issuedAt;
  _CachedSignedUrl(this.future, this.issuedAt);
}

class SupabaseStickerRepository implements StickerRepository {
  final SupabaseClient _client;
  final ImageCacheService _imageCache;
  static const String _bucket = 'stickers';
  static const _signedUrlTtl = Duration(minutes: 50);

  final Map<String, _CachedSignedUrl> _signedUrlCache = {};

  SupabaseStickerRepository(this._client, this._imageCache);

  @override
  Future<GenerateStickerResult> generate({
    required String presetId,
    required String userInput,
    String? caption,
    String? captionPosition,
  }) async {
    try {
      final res = await _client.functions.invoke(
        'generate-sticker',
        body: {
          'presetId': presetId,
          'userInput': userInput,
          if (caption != null && caption.isNotEmpty) 'caption': caption,
          if (caption != null && caption.isNotEmpty)
            'captionPosition': captionPosition,
        },
      );

      final data = res.data;
      if (data is Map && data['error'] != null) {
        final msg = data['error'].toString();
        if (msg.toLowerCase().contains('insufficient')) {
          throw const InsufficientCreditsFailure();
        }
        throw GenerationFailure(msg);
      }

      if (data is! Map ||
          data['stickerId'] == null ||
          data['signedUrl'] == null) {
        throw const GenerationFailure('Malformed response from server');
      }

      return GenerateStickerResult(
        stickerId: data['stickerId'] as String,
        signedUrl: data['signedUrl'] as String,
        path: data['path'] as String? ?? '',
      );
    } on FunctionException catch (e) {
      final detail = e.details;
      final statusCode = e.status;
      final detailMsg = detail is Map && detail['error'] is String
          ? (detail['error'] as String)
          : e.reasonPhrase ?? '';

      if (statusCode == 429) {
        final retry = detail is Map && detail['retryAfterSeconds'] is int
            ? detail['retryAfterSeconds'] as int
            : 20;
        throw RateLimitedFailure(retry);
      }

      if (statusCode == 409) {
        final retry = detail is Map && detail['retryAfterSeconds'] is int
            ? detail['retryAfterSeconds'] as int
            : null;
        throw GenerationInProgressFailure(retryAfterSeconds: retry);
      }

      if (detailMsg.toLowerCase().contains('insufficient')) {
        throw const InsufficientCreditsFailure();
      }
      throw GenerationFailure(detailMsg.isNotEmpty ? detailMsg : e.toString());
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
    return rows
        .map<StickerGeneration>((r) => StickerGeneration.fromJson(r))
        .toList();
  }

  @override
  Future<String?> signedUrlForPath(String path, {int ttlSeconds = 3600}) async {
    if (path.isEmpty) return null;

    final cached = _signedUrlCache[path];
    if (cached != null &&
        DateTime.now().difference(cached.issuedAt) < _signedUrlTtl) {
      return cached.future;
    }

    final entry = _CachedSignedUrl(
      _fetchSignedUrl(path, ttlSeconds),
      DateTime.now(),
    );
    _signedUrlCache[path] = entry;
    return entry.future;
  }

  @override
  Future<File?> getCachedImageFile(String storagePath) async {
    if (storagePath.isEmpty) return null;

    // L1: local file cache
    final existing = await _imageCache.get(storagePath);
    if (existing != null) return existing;

    // L2: signed URL (TTL-aware)
    final signedUrl = await signedUrlForPath(storagePath);
    if (signedUrl == null) return null;

    // L3: network fetch → store locally
    try {
      final res = await http.get(Uri.parse(signedUrl));
      if (res.statusCode != 200) return null;
      final file = await _imageCache.put(storagePath, res.bodyBytes);
      await _imageCache.enforceMaxSize();
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _fetchSignedUrl(String path, int ttlSeconds) async {
    try {
      return await _client.storage
          .from(_bucket)
          .createSignedUrl(path, ttlSeconds);
    } catch (e) {
      throw GenerationFailure('Failed to create signed URL: $e');
    }
  }
}
