import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/wallet.dart';

abstract class WalletRepository {
  Future<Wallet?> fetchBalance(String userId);
  Stream<Wallet> watchBalance(String userId);
}

class SupabaseWalletRepository implements WalletRepository {
  final SupabaseClient _client;
  SupabaseWalletRepository(this._client);

  @override
  Future<Wallet?> fetchBalance(String userId) async {
    final row = await _client
        .from('user_wallets')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    return Wallet.fromJson(row);
  }

  @override
  Stream<Wallet> watchBalance(String userId) {
    return _client
        .from('user_wallets')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((rows) {
          if (rows.isEmpty) {
            // Wallet might not be visible yet immediately after signup; surface 0.
            return Wallet(
              userId: userId,
              balance: 0,
              updatedAt: DateTime.now(),
            );
          }
          return Wallet.fromJson(rows.first);
        });
  }
}
