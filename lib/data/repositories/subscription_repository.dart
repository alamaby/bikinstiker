import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_subscription.dart';

abstract class SubscriptionRepository {
  Future<UserSubscription?> fetchCurrent(String userId);
  Stream<UserSubscription?> watchCurrent(String userId);
}

class SupabaseSubscriptionRepository implements SubscriptionRepository {
  final SupabaseClient _client;
  SupabaseSubscriptionRepository(this._client);

  @override
  Future<UserSubscription?> fetchCurrent(String userId) async {
    final row = await _client
        .from('user_subscriptions')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .order('expires_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return UserSubscription.fromJson(row);
  }

  @override
  Stream<UserSubscription?> watchCurrent(String userId) {
    return _client
        .from('user_subscriptions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) {
          final active =
              rows
                  .where(
                    (r) =>
                        r['is_active'] == true &&
                        DateTime.parse(
                          r['expires_at'] as String,
                        ).isAfter(DateTime.now()),
                  )
                  .toList()
                ..sort(
                  (a, b) => DateTime.parse(
                    b['expires_at'] as String,
                  ).compareTo(DateTime.parse(a['expires_at'] as String)),
                );
          if (active.isEmpty) return null;
          return UserSubscription.fromJson(active.first);
        });
  }
}
