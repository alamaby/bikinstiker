import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';

class SurpriseMeQuota {
  final int usedToday;
  final int freeLimit;
  final int balance;

  const SurpriseMeQuota({
    required this.usedToday,
    required this.freeLimit,
    required this.balance,
  });

  bool get willBeCharged => usedToday >= freeLimit;
  int get freeRemaining => (freeLimit - usedToday).clamp(0, freeLimit);
}

class SurpriseMeResult {
  final String prompt;
  final int balance;
  final int freeRemaining;
  final bool charged;

  const SurpriseMeResult({
    required this.prompt,
    required this.balance,
    required this.freeRemaining,
    required this.charged,
  });
}

class SurpriseMeRepository {
  final SupabaseClient _client;

  SurpriseMeRepository(this._client);

  Future<SurpriseMeQuota> fetchQuota() async {
    try {
      final data = await _client.rpc('get_surprise_me_quota');
      if (data is! Map) throw const ServerFailure('Malformed quota response');
      return SurpriseMeQuota(
        usedToday: (data['usedToday'] as num?)?.toInt() ?? 0,
        freeLimit: (data['freeLimit'] as num?)?.toInt() ?? 0,
        balance: (data['balance'] as num?)?.toInt() ?? 0,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  Future<SurpriseMeResult> requestSurprise({required String presetId}) async {
    try {
      final res = await _client.functions.invoke(
        'surprise-me',
        body: {'presetId': presetId},
      );

      final data = res.data;
      if (data is Map && data['error'] != null) {
        final code = data['code']?.toString();
        if (code == 'insufficient_credits' ||
            data['error'].toString().toLowerCase().contains('insufficient')) {
          throw const InsufficientCreditsFailure();
        }
        throw ServerFailure(data['error'].toString());
      }

      if (data is! Map || data['prompt'] is! String) {
        throw const ServerFailure('Malformed response from server');
      }

      return SurpriseMeResult(
        prompt: data['prompt'] as String,
        balance: (data['balance'] as num?)?.toInt() ?? 0,
        freeRemaining: (data['freeRemaining'] as num?)?.toInt() ?? 0,
        charged: data['charged'] == true,
      );
    } on FunctionException catch (e) {
      final detail = e.details;
      final statusCode = e.status;

      if (statusCode == 402) {
        throw const InsufficientCreditsFailure();
      }
      if (statusCode == 429) {
        final retry = detail is Map && detail['retryAfterSeconds'] is int
            ? detail['retryAfterSeconds'] as int
            : 5;
        throw RateLimitedFailure(retry);
      }

      final detailMsg = detail is Map && detail['error'] is String
          ? (detail['error'] as String)
          : e.reasonPhrase ?? '';
      throw ServerFailure(detailMsg.isNotEmpty ? detailMsg : e.toString());
    } on Failure {
      rethrow;
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }
}
