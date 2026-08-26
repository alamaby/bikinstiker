import 'package:flutter_test/flutter_test.dart';

import 'package:bikin_stiker/data/models/credit_transaction.dart';
import 'package:bikin_stiker/data/models/showcase_listing.dart';

void main() {
  group('ShowcaseListing', () {
    test('parses search RPC row with viewer flags', () {
      final listing = ShowcaseListing.fromJson({
        'listing_id': 'lst-1',
        'pack_name': 'Cute Cats',
        'description': 'Meow pack',
        'tags': ['cat', 'cute'],
        'price_credits': 8,
        'price_for_viewer': 10,
        'sticker_count': 12,
        'preview_image_path': 'seller/gen.jpg',
        'tray_icon_path': 'tray_icons/seller/pack.png',
        'seller_display_name': 'Adi',
        'rating_count': 4,
        'favorite_count': 7,
        'purchase_count': 2,
        'is_own': false,
        'is_owned': true,
        'viewer_rated': false,
        'viewer_favorited': true,
        'created_at': '2026-08-25T00:00:00Z',
      });

      expect(listing.id, 'lst-1');
      expect(listing.packName, 'Cute Cats');
      expect(listing.tags, ['cat', 'cute']);
      expect(listing.priceCredits, 8);
      expect(listing.priceForViewer, 10);
      expect(listing.isOwned, isTrue);
      expect(listing.viewerFavorited, isTrue);
    });

    test('defaults tolerate null optionals', () {
      final listing = ShowcaseListing.fromJson({
        'listing_id': 'lst-2',
      });
      expect(listing.packName, '');
      expect(listing.tags, isEmpty);
      expect(listing.description, isNull);
      expect(listing.priceForViewer, 0);
      expect(listing.isOwn, isFalse);
    });
  });

  group('ShowcaseDetail', () {
    test('parses get_showcase_detail jsonb payload', () {
      final detail = ShowcaseDetail.fromJson({
        'listingId': 'lst-1',
        'packName': 'Cute Cats',
        'description': null,
        'tags': ['cat'],
        'basePrice': 8,
        'viewerTier': 'free',
        'priceForViewer': 10,
        'stickerCount': 3,
        'trayIconPath': 'tray_icons/x/y.png',
        'previewImagePath': 'x/1.jpg',
        'sellerDisplayName': 'Adi',
        'isOwn': false,
        'ownedPackId': null,
        'ratingCount': 1,
        'favoriteCount': 2,
        'purchaseCount': 3,
        'viewerRated': false,
        'viewerFavorited': false,
        'items': [
          {
            'position': 1,
            'imagePath': 'x/1.jpg',
            'emojis': ['🐱'],
            'accessibilityText': 'cat',
          },
        ],
      });

      expect(detail.isPlus, isFalse);
      // Free surcharge: ceil(8 * 1.25) = 10 (server-computed, client trusts).
      expect(detail.priceForViewer, 10);
      expect(detail.items, hasLength(1));
      expect(detail.items.first.emojis, ['🐱']);
    });
  });

  group('CreditTransaction showcase types', () {
    test('maps showcase_purchase and showcase_sale', () {
      final buy = CreditTransaction.fromJson({
        'id': 't1',
        'user_id': 'u1',
        'amount': -10,
        'type': 'showcase_purchase',
        'created_at': '2026-08-25T00:00:00Z',
      });
      final sale = CreditTransaction.fromJson({
        'id': 't2',
        'user_id': 'u1',
        'amount': 6,
        'type': 'showcase_sale',
        'created_at': '2026-08-25T00:00:00Z',
      });

      expect(buy.type, CreditTxType.showcasePurchase);
      expect(buy.isDebit, isTrue);
      expect(sale.type, CreditTxType.showcaseSale);
      expect(sale.isCredit, isTrue);
    });
  });
}
