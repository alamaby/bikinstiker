import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sticker_feedback.dart';

abstract class StickerFeedbackRepository {
  Future<StickerFeedback?> fetch(String stickerGenerationId);

  Future<Map<String, StickerFeedback>> fetchMany(List<String> stickerGenerationIds);

  Future<StickerFeedback> submit({
    required String stickerGenerationId,
    required StickerFeedbackRating rating,
    List<String> reasonTags = const [],
    String? note,
  });

  Future<void> delete(String stickerGenerationId);
}

class SupabaseStickerFeedbackRepository implements StickerFeedbackRepository {
  final SupabaseClient _client;

  SupabaseStickerFeedbackRepository(this._client);

  @override
  Future<StickerFeedback?> fetch(String stickerGenerationId) async {
    final row = await _client
        .from('sticker_generation_feedback')
        .select()
        .eq('sticker_generation_id', stickerGenerationId)
        .maybeSingle();
    if (row == null) return null;
    return StickerFeedback.fromJson(row);
  }

  @override
  Future<Map<String, StickerFeedback>> fetchMany(
    List<String> stickerGenerationIds,
  ) async {
    if (stickerGenerationIds.isEmpty) return const {};
    final rows = await _client
        .from('sticker_generation_feedback')
        .select()
        .inFilter('sticker_generation_id', stickerGenerationIds);

    return {
      for (final row in rows.map(StickerFeedback.fromJson))
        row.stickerGenerationId: row,
    };
  }

  @override
  Future<StickerFeedback> submit({
    required String stickerGenerationId,
    required StickerFeedbackRating rating,
    List<String> reasonTags = const [],
    String? note,
  }) async {
    final row = await _client.rpc(
      'upsert_sticker_generation_feedback',
      params: {
        'p_sticker_generation_id': stickerGenerationId,
        'p_rating': stickerFeedbackRatingValue(rating),
        'p_reason_tags': reasonTags,
        'p_note': note,
      },
    );

    if (row is! Map<String, dynamic>) {
      throw const FormatException('Malformed feedback response from server');
    }

    return StickerFeedback.fromJson(row);
  }

  @override
  Future<void> delete(String stickerGenerationId) async {
    await _client.rpc(
      'delete_sticker_generation_feedback',
      params: {'p_sticker_generation_id': stickerGenerationId},
    );
  }
}
