import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../models/showcase_listing.dart';

/// Outcome of the two-step purchase flow.
class ShowcasePurchaseOutcome {
  final String entitlementId;
  final int priceCharged;
  final String? packId;

  /// true when the copy step completed and the pack is usable.
  final bool completed;

  /// true when the system or user refunded during the copy step.
  final bool refunded;

  const ShowcasePurchaseOutcome({
    required this.entitlementId,
    required this.priceCharged,
    required this.completed,
    required this.refunded,
    this.packId,
  });
}

/// Listing milik owner untuk satu pack (dipakai form sheet listing).
class OwnerListingSnapshot {
  final String listingId;
  final int priceCredits;
  final String? description;
  final List<String> tags;

  const OwnerListingSnapshot({
    required this.listingId,
    required this.priceCredits,
    required this.description,
    required this.tags,
  });
}

Failure _mapRpcError(Object e) {
  final msg = e is PostgrestException ? e.message : e.toString();
  final lower = msg.toLowerCase();
  if (lower.contains('insufficient')) return const InsufficientCreditsFailure();
  if (lower.contains('pack slot limit')) {
    return const PackSlotLimitFailure();
  }
  if (lower.contains('guest')) {
    return const AuthFailure('Guest accounts cannot do this');
  }
  if (lower.contains('plus subscription')) {
    return const AuthFailure('Plus subscription required');
  }
  if (lower.contains('already purchased')) {
    return const ServerFailure('Already purchased');
  }
  if (lower.contains('listed on showcase')) {
    return const ServerFailure('Pack is listed on Showcase');
  }
  return ServerFailure(msg);
}

abstract class ShowcaseRepository {
  Future<String> fetchViewerTier();

  /// Set pack_id milik user yang punya listing aktif/suspended (untuk badge).
  Future<Set<String>> fetchListedPackIds();

  Future<List<ShowcaseListing>> search({
    String? query,
    String? tag,
    ShowcaseSort sort = ShowcaseSort.trending,
    int limit = 30,
    int offset = 0,
  });

  Future<ShowcaseDetail> fetchDetail(String listingId);

  Future<Map<String, ShowcasePreviewUrls>> fetchPreviews(
    List<String> listingIds, {
    bool includeItems = false,
  });

  Future<OwnerListingSnapshot?> fetchListingForPack(String packId);

  Future<String> createListing({
    required String packId,
    required int priceCredits,
    String? description,
    List<String> tags = const [],
  });

  Future<void> updateListing({
    required String listingId,
    required int priceCredits,
    String? description,
    List<String> tags = const [],
  });

  Future<void> unlistListing(String listingId);

  Future<({bool active, int count})> toggleRating(String listingId);

  Future<({bool favorited, int count})> toggleFavorite(String listingId);

  Future<void> reportListing({
    required String listingId,
    required String reason,
    String? note,
  });

  Future<ShowcasePurchaseOutcome> purchase(String listingId);

  Future<void> refundPendingPurchase(String entitlementId);
}

class SupabaseShowcaseRepository implements ShowcaseRepository {
  final SupabaseClient _client;

  SupabaseShowcaseRepository(this._client);

  @override
  Future<String> fetchViewerTier() async {
    // L2: satu kali retry pada error transien sebelum fallback 'free'.
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final uid = _client.auth.currentUser?.id;
        if (uid == null) return 'free';
        final row = await _client
            .from('user_wallets')
            .select('tier_now')
            .eq('user_id', uid)
            .maybeSingle();
        return (row?['tier_now'] as String?) ?? 'free';
      } catch (_) {
        if (attempt == 1) return 'free';
      }
    }
    return 'free';
  }

  @override
  Future<Set<String>> fetchListedPackIds() async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return {};
      final rows = await _client
          .from('showcase_listings')
          .select('pack_id')
          .eq('seller_id', uid)
          .neq('status', 'removed');
      return (rows as List)
          .map((r) => r['pack_id'] as String)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  @override
  Future<List<ShowcaseListing>> search({
    String? query,
    String? tag,
    ShowcaseSort sort = ShowcaseSort.trending,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final res = await _client.rpc(
        'search_showcase_listings',
        params: {
          'p_query': (query?.trim().isEmpty ?? true) ? null : query!.trim(),
          'p_tag': (tag?.trim().isEmpty ?? true) ? null : tag!.trim(),
          'p_sort': sort.raw,
          'p_limit_count': limit,
          'p_offset_count': offset,
        },
      );
      final rows = res as List? ?? const [];
      return rows
          .map((r) =>
              ShowcaseListing.fromJson(r as Map<String, dynamic>))
          .toList();
    } on Failure {
      rethrow;
    } on PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<ShowcaseDetail> fetchDetail(String listingId) async {
    try {
      final res = await _client.rpc(
        'get_showcase_detail',
        params: {'p_listing_id': listingId},
      );
      if (res is! Map) throw const ServerFailure('Malformed detail response');
      return ShowcaseDetail.fromJson(Map<String, dynamic>.from(res));
    } on Failure {
      rethrow;
    } on PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<Map<String, ShowcasePreviewUrls>> fetchPreviews(
    List<String> listingIds, {
    bool includeItems = false,
  }) async {
    if (listingIds.isEmpty) return {};
    try {
      final res = await _client.functions.invoke(
        'showcase-preview',
        body: {'listingIds': listingIds, 'includeItems': includeItems},
      );
      final data = res.data;
      if (data is! Map || data['previews'] is! Map) return {};
      final raw = data['previews'] as Map;
      return raw.map(
        (k, v) => MapEntry(
          k.toString(),
          ShowcasePreviewUrls.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      );
    } on Failure {
      rethrow;
    } catch (_) {
      // Preview URLs are best-effort; UI falls back to placeholder icons.
      return {};
    }
  }

  @override
  Future<OwnerListingSnapshot?> fetchListingForPack(String packId) async {
    try {
      final row = await _client
          .from('showcase_listings')
          .select()
          .eq('pack_id', packId)
          .neq('status', 'removed')
          .maybeSingle();
      if (row == null) return null;
      return OwnerListingSnapshot(
        listingId: row['id'] as String,
        priceCredits: (row['price_credits'] as num?)?.toInt() ?? 0,
        description: row['description'] as String?,
        tags: (row['tags'] as List?)?.cast<String>() ?? const [],
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> createListing({
    required String packId,
    required int priceCredits,
    String? description,
    List<String> tags = const [],
  }) async {
    try {
      final res = await _client.rpc(
        'create_showcase_listing',
        params: {
          'p_pack_id': packId,
          'p_price_credits': priceCredits,
          'p_description': (description?.trim().isEmpty ?? true)
              ? null
              : description!.trim(),
          'p_tags': tags,
        },
      );
      return res as String;
    } on Failure {
      rethrow;
    } on PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<void> updateListing({
    required String listingId,
    required int priceCredits,
    String? description,
    List<String> tags = const [],
  }) async {
    try {
      await _client.rpc(
        'update_showcase_listing',
        params: {
          'p_listing_id': listingId,
          'p_price_credits': priceCredits,
          'p_description': (description?.trim().isEmpty ?? true)
              ? null
              : description!.trim(),
          'p_tags': tags,
        },
      );
    } on Failure {
      rethrow;
    } on PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<void> unlistListing(String listingId) async {
    try {
      await _client.rpc(
        'unlist_showcase_listing',
        params: {'p_listing_id': listingId},
      );
    } on Failure {
      rethrow;
    } on PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<({bool active, int count})> toggleRating(String listingId) async {
    try {
      final res = await _client.rpc(
        'toggle_showcase_rating',
        params: {'p_listing_id': listingId},
      );
      final row = (res as List).first as Map;
      return (
        active: row['rated'] == true,
        count: (row['rating_count'] as num?)?.toInt() ?? 0,
      );
    } on Failure {
      rethrow;
    } on PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<({bool favorited, int count})> toggleFavorite(String listingId) async {
    try {
      final res = await _client.rpc(
        'toggle_showcase_favorite',
        params: {'p_listing_id': listingId},
      );
      final row = (res as List).first as Map;
      return (
        favorited: row['favorited'] == true,
        count: (row['favorite_count'] as num?)?.toInt() ?? 0,
      );
    } on Failure {
      rethrow;
    } on PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<void> reportListing({
    required String listingId,
    required String reason,
    String? note,
  }) async {
    try {
      await _client.rpc(
        'report_showcase_listing',
        params: {
          'p_listing_id': listingId,
          'p_reason': reason,
          'p_note': (note?.trim().isEmpty ?? true) ? null : note!.trim(),
        },
      );
    } on Failure {
      rethrow;
    } on PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<ShowcasePurchaseOutcome> purchase(String listingId) async {
    try {
      // Langkah 1: charge atomik + entitlement pending.
      final res = await _client.rpc(
        'purchase_showcase_pack',
        params: {'p_listing_id': listingId},
      );
      final rows = res as List? ?? const [];
      if (rows.isEmpty) throw const ServerFailure('Malformed purchase response');
      final row = rows.first as Map;
      final entitlementId = row['entitlement_id'] as String;
      final priceCharged = (row['price_charged'] as num?)?.toInt() ?? 0;

      // Langkah 2: salin file + buat pack buyer.
      try {
        final copyRes = await _client.functions.invoke(
          'showcase-purchase-copy',
          body: {'entitlementId': entitlementId},
        );
        final data = copyRes.data;
        if (data is Map && data['error'] != null) {
          if (data['refunded'] == true) {
            return ShowcasePurchaseOutcome(
              entitlementId: entitlementId,
              priceCharged: priceCharged,
              completed: false,
              refunded: true,
            );
          }
          throw ServerFailure(data['error'].toString());
        }
        return ShowcasePurchaseOutcome(
          entitlementId: entitlementId,
          priceCharged: priceCharged,
          completed: true,
          refunded: false,
          packId: data is Map ? data['packId'] as String? : null,
        );
      } on FunctionException catch (e) {
        // 409 dengan refunded=true -> slot penuh saat materialisasi.
        final detail = e.details;
        if (e.status == 409 &&
            detail is Map &&
            detail['refunded'] == true) {
          return ShowcasePurchaseOutcome(
            entitlementId: entitlementId,
            priceCharged: priceCharged,
            completed: false,
            refunded: true,
          );
        }
        if (e.status == 409 && detail is Map && detail['code'] == 'pack_slot_limit') {
          return ShowcasePurchaseOutcome(
            entitlementId: entitlementId,
            priceCharged: priceCharged,
            completed: false,
            refunded: true,
          );
        }
        // Copy gagal tapi masih pending -> biarkan user retry/refund manual.
        throw ServerFailure(
          detail is Map && detail['error'] is String
              ? detail['error'] as String
              : 'Copy failed',
        );
      }
    } on Failure {
      rethrow;
    } on PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<void> refundPendingPurchase(String entitlementId) async {
    try {
      await _client.rpc(
        'refund_pending_showcase_purchase',
        params: {'p_entitlement_id': entitlementId},
      );
    } on Failure {
      rethrow;
    } on PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }
}
