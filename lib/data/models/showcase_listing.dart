import 'package:equatable/equatable.dart';

/// Sort options for showcase listings (maps to search RPC `p_sort`).
enum ShowcaseSort {
  trending('trending'),
  topRated('top_rated'),
  popular('popular'),
  newest('newest');

  final String raw;
  const ShowcaseSort(this.raw);

  static ShowcaseSort fromRaw(String raw) => ShowcaseSort.values
      .firstWhere((s) => s.raw == raw, orElse: () => ShowcaseSort.trending);
}

/// A sticker pack listing on the Showcase (marketplace browse row).
class ShowcaseListing extends Equatable {
  final String id;
  final String packName;
  final String? description;
  final List<String> tags;
  final int priceCredits;
  final int priceForViewer;
  final int stickerCount;
  final String? previewImagePath;
  final String? trayIconPath;
  final String sellerDisplayName;
  final int ratingCount;
  final int favoriteCount;
  final int purchaseCount;
  final bool isOwn;
  final bool isOwned;
  final bool viewerRated;
  final bool viewerFavorited;
  final DateTime createdAt;

  const ShowcaseListing({
    required this.id,
    required this.packName,
    required this.description,
    required this.tags,
    required this.priceCredits,
    required this.priceForViewer,
    required this.stickerCount,
    required this.previewImagePath,
    required this.trayIconPath,
    required this.sellerDisplayName,
    required this.ratingCount,
    required this.favoriteCount,
    required this.purchaseCount,
    required this.isOwn,
    required this.isOwned,
    required this.viewerRated,
    required this.viewerFavorited,
    required this.createdAt,
  });

  factory ShowcaseListing.fromJson(Map<String, dynamic> json) =>
      ShowcaseListing(
        id: json['listing_id'] as String,
        packName: json['pack_name'] as String? ?? '',
        description: json['description'] as String?,
        tags: (json['tags'] as List?)?.cast<String>() ?? const [],
        priceCredits: (json['price_credits'] as num?)?.toInt() ?? 0,
        priceForViewer: (json['price_for_viewer'] as num?)?.toInt() ?? 0,
        stickerCount: (json['sticker_count'] as num?)?.toInt() ?? 0,
        previewImagePath: json['preview_image_path'] as String?,
        trayIconPath: json['tray_icon_path'] as String?,
        sellerDisplayName: json['seller_display_name'] as String? ?? 'Creator',
        ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
        favoriteCount: (json['favorite_count'] as num?)?.toInt() ?? 0,
        purchaseCount: (json['purchase_count'] as num?)?.toInt() ?? 0,
        isOwn: json['is_own'] == true,
        isOwned: json['is_owned'] == true,
        viewerRated: json['viewer_rated'] == true,
        viewerFavorited: json['viewer_favorited'] == true,
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
      );

  @override
  List<Object?> get props => [
        id,
        packName,
        description,
        tags,
        priceCredits,
        priceForViewer,
        stickerCount,
        previewImagePath,
        trayIconPath,
        sellerDisplayName,
        ratingCount,
        favoriteCount,
        purchaseCount,
        isOwn,
        isOwned,
        viewerRated,
        viewerFavorited,
        createdAt,
      ];
}

/// One sticker inside a [ShowcaseDetail].
class ShowcaseDetailItem extends Equatable {
  final int position;
  final String imagePath;
  final List<String> emojis;
  final String? accessibilityText;

  const ShowcaseDetailItem({
    required this.position,
    required this.imagePath,
    required this.emojis,
    required this.accessibilityText,
  });

  factory ShowcaseDetailItem.fromJson(Map<String, dynamic> json) =>
      ShowcaseDetailItem(
        position: (json['position'] as num?)?.toInt() ?? 0,
        imagePath: json['imagePath'] as String? ?? '',
        emojis: (json['emojis'] as List?)?.cast<String>() ?? const [],
        accessibilityText: json['accessibilityText'] as String?,
      );

  @override
  List<Object?> get props =>
      [position, imagePath, emojis, accessibilityText];
}

/// Full detail payload from `get_showcase_detail` RPC.
class ShowcaseDetail extends Equatable {
  final String listingId;
  final String packName;
  final String? description;
  final List<String> tags;
  final int basePrice;
  final String viewerTier;
  final int priceForViewer;
  final int stickerCount;
  final String trayIconPath;
  final String? previewImagePath;
  final String sellerDisplayName;
  final bool isOwn;
  final String? ownedPackId;
  final int ratingCount;
  final int favoriteCount;
  final int purchaseCount;
  final bool viewerRated;
  final bool viewerFavorited;
  final List<ShowcaseDetailItem> items;

  const ShowcaseDetail({
    required this.listingId,
    required this.packName,
    required this.description,
    required this.tags,
    required this.basePrice,
    required this.viewerTier,
    required this.priceForViewer,
    required this.stickerCount,
    required this.trayIconPath,
    required this.previewImagePath,
    required this.sellerDisplayName,
    required this.isOwn,
    required this.ownedPackId,
    required this.ratingCount,
    required this.favoriteCount,
    required this.purchaseCount,
    required this.viewerRated,
    required this.viewerFavorited,
    required this.items,
  });

  bool get isPlus => viewerTier == 'plus';

  factory ShowcaseDetail.fromJson(Map<String, dynamic> json) =>
      ShowcaseDetail(
        listingId: json['listingId'] as String,
        packName: json['packName'] as String? ?? '',
        description: json['description'] as String?,
        tags: (json['tags'] as List?)?.cast<String>() ?? const [],
        basePrice: (json['basePrice'] as num?)?.toInt() ?? 0,
        viewerTier: json['viewerTier'] as String? ?? 'free',
        priceForViewer: (json['priceForViewer'] as num?)?.toInt() ?? 0,
        stickerCount: (json['stickerCount'] as num?)?.toInt() ?? 0,
        trayIconPath: json['trayIconPath'] as String? ?? '',
        previewImagePath: json['previewImagePath'] as String?,
        sellerDisplayName: json['sellerDisplayName'] as String? ?? 'Creator',
        isOwn: json['isOwn'] == true,
        ownedPackId: json['ownedPackId'] as String?,
        ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
        favoriteCount: (json['favoriteCount'] as num?)?.toInt() ?? 0,
        purchaseCount: (json['purchaseCount'] as num?)?.toInt() ?? 0,
        viewerRated: json['viewerRated'] == true,
        viewerFavorited: json['viewerFavorited'] == true,
        items: (json['items'] as List? ?? const [])
            .map((e) =>
                ShowcaseDetailItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [
        listingId,
        packName,
        description,
        tags,
        basePrice,
        viewerTier,
        priceForViewer,
        stickerCount,
        trayIconPath,
        previewImagePath,
        sellerDisplayName,
        isOwn,
        ownedPackId,
        ratingCount,
        favoriteCount,
        purchaseCount,
        viewerRated,
        viewerFavorited,
        items,
      ];
}

/// Signed URLs for a listing's media (from `showcase-preview` Edge Function).
class ShowcasePreviewUrls extends Equatable {
  final String? trayUrl;
  final String? previewUrl;

  /// Present when requested with includeItems=true; ordered by position.
  final List<String?>? items;

  const ShowcasePreviewUrls({
    required this.trayUrl,
    required this.previewUrl,
    this.items,
  });

  factory ShowcasePreviewUrls.fromJson(Map<String, dynamic> json) =>
      ShowcasePreviewUrls(
        trayUrl: json['trayUrl'] as String?,
        previewUrl: json['previewUrl'] as String?,
        items: (json['items'] as List?)
            ?.map((e) => e is Map<String, dynamic>
                ? (e['url'] as String?)
                : null)
            .toList(),
      );

  @override
  List<Object?> get props => [trayUrl, previewUrl, items];
}
