import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/credit_transaction.dart';

abstract class CreditTransactionRepository {
  Future<List<CreditTransaction>> fetchTransactions(
    String userId, {
    int limit = 50,
    CreditTxType? type,
    Set<CreditTxType>? types,
  });

  Stream<List<CreditTransaction>> watchTransactions(String userId);
}

class SupabaseCreditTransactionRepository
    implements CreditTransactionRepository {
  final SupabaseClient _client;

  SupabaseCreditTransactionRepository(this._client);

  String _txTypeToDb(CreditTxType type) {
    switch (type) {
      case CreditTxType.topup:
        return 'topup';
      case CreditTxType.dailyReward:
        return 'daily_reward';
      case CreditTxType.generateSticker:
        return 'generate_sticker';
      case CreditTxType.refund:
        return 'refund';
      case CreditTxType.subscriptionGrant:
        return 'subscription_grant';
      case CreditTxType.missionReward:
        return 'mission_reward';
      case CreditTxType.expired:
        return 'expired';
      case CreditTxType.locked:
        return 'locked';
      case CreditTxType.adminGrant:
        return 'admin_grant';
      default:
        return 'unknown';
    }
  }

  @override
  Future<List<CreditTransaction>> fetchTransactions(
    String userId, {
    int limit = 50,
    CreditTxType? type,
    Set<CreditTxType>? types,
  }) async {
    // Build filter chain first (PostgrestFilterBuilder).
    PostgrestFilterBuilder<PostgrestList> filtered = _client
        .from('credit_transactions')
        .select()
        .eq('user_id', userId)
        .not('type', 'is', null);

    if (types != null && types.isNotEmpty) {
      filtered = filtered.inFilter('type', types.map(_txTypeToDb).toList());
    } else if (type != null) {
      filtered = filtered.eq('type', _txTypeToDb(type));
    }

    // Apply ordering and (optional) limit in a separate transform chain.
    var ordered = filtered.order('created_at', ascending: false);
    if (limit > 0) {
      ordered = ordered.limit(limit);
    }

    final rows = await ordered;

    return (rows as List)
        .map((r) => CreditTransaction.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<List<CreditTransaction>> watchTransactions(String userId) {
    return _client
        .from('credit_transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50)
        .map((rows) => rows.map((r) => CreditTransaction.fromJson(r)).toList());
  }
}
