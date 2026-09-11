import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/di.dart';
import '../../core/image_cache.dart';
import '../../data/repositories/sticker_repository.dart';
import '../../l10n/app_localizations.dart';

/// Builds the image for a loaded [file].
///
/// [onError] is the widget's production error handler (corrupt-file purge
/// scheduling). Custom builders must forward it to their image's
/// `errorBuilder` when they want the purge behavior; test stubs that draw
/// something else can ignore it.
typedef RetryableImageBuilder = Widget Function(
  BuildContext context,
  File file,
  ImageErrorWidgetBuilder onError,
);

/// Sticker image with loading / error / manual-retry states.
///
/// Loads via [StickerRepository.getCachedImageFile] (local file cache →
/// signed URL → network download).
///
/// State contract:
/// - null/empty [storagePath] → static "no image" icon (nothing to load).
/// - loading → spinner.
/// - sign/download failure, or a completed load with no file (e.g. HTTP
///   404) → error icon; tap retries (the local entry is purged first so a
///   corrupt cached file can never trap the retry in a loop).
/// - undecodable file bytes → the corrupt cache entry is purged once and
///   the image reloads automatically; persistent failure falls back to
///   the error icon (still manually retryable).
///
/// [imageBuilder] is a testability seam: production uses [Image.file]
/// (with the corrupt-file purge above); widget tests inject a stub so no
/// real image decoding is required. Stubs that forward [onError] to their
/// image's `errorBuilder` exercise the production purge path.
class RetryableCachedImage extends StatefulWidget {
  final String? storagePath;
  final BoxFit fit;

  /// Spinner diameter; null keeps the default indicator size.
  final double? progressSize;
  final Color? emptyIconColor;
  final Color? errorIconColor;

  final RetryableImageBuilder? imageBuilder;

  const RetryableCachedImage({
    super.key,
    required this.storagePath,
    this.fit = BoxFit.cover,
    this.progressSize,
    this.emptyIconColor,
    this.errorIconColor,
    this.imageBuilder,
  });

  @override
  State<RetryableCachedImage> createState() => _RetryableCachedImageState();
}

class _RetryableCachedImageState extends State<RetryableCachedImage> {
  Future<File?>? _future;
  bool _purgedCorruptFile = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RetryableCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storagePath != widget.storagePath) {
      _purgedCorruptFile = false;
      _load();
    }
  }

  void _load() {
    final path = widget.storagePath;
    _future = (path == null || path.isEmpty)
        ? null
        : getIt<StickerRepository>().getCachedImageFile(path);
  }

  /// Manual retry: purge the local entry first, then reload. Purging first
  /// guarantees a corrupt cached file cannot trap the retry (a plain
  /// reload would keep hitting the same bad bytes on the L1 cache hit).
  void _retry() {
    final path = widget.storagePath;
    if (path == null || path.isEmpty) return;
    getIt<ImageCacheService>().remove(path).catchError((_) {}).whenComplete(() {
      if (mounted) setState(_load);
    });
  }

  Future<void> _purgeCorruptFileAndReload() async {
    final path = widget.storagePath;
    if (!mounted || path == null || path.isEmpty || _purgedCorruptFile) return;
    _purgedCorruptFile = true;
    try {
      await getIt<ImageCacheService>().remove(path);
    } catch (_) {
      // Best effort: reload anyway; the error UI remains as fallback.
    }
    if (mounted) setState(_load);
  }

  Widget _errorIcon(String retryLabel) {
    return GestureDetector(
      onTap: _retry,
      child: Center(
        child: Tooltip(
          message: retryLabel,
          child: Icon(
            Icons.broken_image_outlined,
            color: widget.errorIconColor,
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, File file) {
    final custom = widget.imageBuilder;
    if (custom != null) {
      return custom(context, file, _handleImageError);
    }
    return Image.file(
      file,
      fit: widget.fit,
      errorBuilder: _handleImageError,
    );
  }

  Widget _handleImageError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    if (!_purgedCorruptFile) {
      // setState is illegal during build: schedule after the frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _purgeCorruptFileAndReload();
      });
    }
    return _errorIcon(AppLocalizations.of(context)!.retry);
  }

  @override
  Widget build(BuildContext context) {
    final retryLabel = AppLocalizations.of(context)!.retry;
    if (_future == null) {
      return Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: widget.emptyIconColor,
        ),
      );
    }
    return FutureBuilder<File?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          const progress = CircularProgressIndicator(strokeWidth: 2);
          final size = widget.progressSize;
          return Center(
            child: size == null
                ? progress
                : SizedBox(height: size, width: size, child: progress),
          );
        }
        final file = snap.data;
        if (snap.hasError || file == null) {
          return _errorIcon(retryLabel);
        }
        return _buildImage(context, file);
      },
    );
  }
}
