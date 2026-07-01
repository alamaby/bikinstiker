import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/credit_transaction.dart';

abstract class CreditTransactionRepository {
  Future<List<CreditTransaction>> fetchTransactions(
    String userId, {
    int limit = 50,
    CreditTxType? type,
  });

  Stream<List<CreditTransaction>> watchTransactions(String userId);
}

class SupabaseCreditTransactionRepository
    implements CreditTransactionRepository {
  final SupabaseClient _client;

  SupabaseCreditTransactionRepository(this._client);

  @override
  Future<List<CreditTransaction>> fetchTransactions(
    String userId, {
    int limit = 50,
    CreditTxType? type,
  }) async {
    var query = _client
        .from('credit_transactions')
        .select()
        .eq('user_id', userId)
        .not('type', 'is', null);

    if (type != null) {
      query = query.eq('type', type.name);
    }

    final rows = await query.order('created_at', ascending: false).limit(limit);

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
