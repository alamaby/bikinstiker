import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../models/sticker_preset.dart';

abstract class PresetRepository {
  Future<List<StickerPreset>> fetchPresets({
    required StickerPresetRole role,
    bool forceRefresh = false,
  });
}

class SupabasePresetRepository implements PresetRepository {
  final SupabaseClient _client;
  List<StickerPreset>? _cached;
  StickerPresetRole? _cachedRole;
  DateTime? _cachedAt;
  static const _ttl = Duration(minutes: 5);

  SupabasePresetRepository(this._client);

  @override
  Future<List<StickerPreset>> fetchPresets({
    required StickerPresetRole role,
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cached != null &&
        _cachedRole == role &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < _ttl) {
      return _cached!;
    }

    try {
      final res = await _client.functions.invoke(
        'list-presets',
        method: HttpMethod.get,
      );

      final data = res.data;
      if (data is! Map || data['presets'] is! List) {
        throw const GenerationFailure('Malformed response from list-presets');
      }

      final list = (data['presets'] as List)
          .map((e) => StickerPreset.fromJson(e as Map<String, dynamic>))
          .toList();

      _cached = list;
      _cachedRole = role;
      _cachedAt = now;
      return list;
    } on FunctionException catch (e) {
      final detail = e.details;
      final detailMsg = detail is Map && detail['error'] is String
          ? (detail['error'] as String)
          : e.reasonPhrase ?? '';
      throw GenerationFailure(detailMsg.isNotEmpty ? detailMsg : e.toString());
    } on Failure {
      rethrow;
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }
}
