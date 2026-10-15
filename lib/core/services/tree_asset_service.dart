import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/forest_tree_model.dart';

/// Service responsible for managing high-quality tree sprite assets (PNG/WebP),
/// caching decoded textures in GPU memory, and providing graceful fallback
/// to procedural botanical rendering when individual assets are not present.
class TreeAssetService {
  static final TreeAssetService instance = TreeAssetService._internal();

  TreeAssetService._internal();

  /// Memory cache of loaded raster tree sprites keyed by asset path.
  final Map<String, ui.Image> _spriteCache = {};

  /// Cache of paths confirmed missing in the asset bundle to avoid redundant lookups.
  final Set<String> _missingAssets = {};

  /// Paths currently being loaded to prevent duplicate concurrent disk fetches.
  final Map<String, Future<ui.Image?>> _loadingFutures = {};

  /// Synchronously retrieve a cached sprite if already decoded into GPU memory.
  ui.Image? getCachedSprite(String assetPath) {
    return _spriteCache[assetPath];
  }

  /// Whether the sprite has been verified as present in cache.
  bool hasCachedSprite(String assetPath) {
    return _spriteCache.containsKey(assetPath);
  }

  /// Whether this asset path is already known to be missing from the asset bundle.
  bool isKnownMissing(String assetPath) {
    return _missingAssets.contains(assetPath);
  }

  /// Load a tree sprite asset from the bundle. If absent, marks as missing
  /// and safely returns null without interrupting execution.
  Future<ui.Image?> loadTreeSprite(String assetPath) async {
    if (_spriteCache.containsKey(assetPath)) {
      return _spriteCache[assetPath];
    }

    if (_missingAssets.contains(assetPath)) {
      return null;
    }

    if (_loadingFutures.containsKey(assetPath)) {
      return _loadingFutures[assetPath];
    }

    final future = _loadFromBundle(assetPath);
    _loadingFutures[assetPath] = future;

    try {
      final img = await future;
      return img;
    } finally {
      _loadingFutures.remove(assetPath);
    }
  }

  Future<ui.Image?> _loadFromBundle(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;
      _spriteCache[assetPath] = image;
      return image;
    } catch (_) {
      // Asset not found in bundle or invalid image format; mark missing for fallback
      _missingAssets.add(assetPath);
      return null;
    }
  }

  /// Preloads all species stages in the background so they are immediately
  /// available for silky 60fps rendering without jank.
  Future<void> preloadAllSpecies() async {
    final futures = <Future<ui.Image?>>[];

    for (final species in TreeSpecies.values) {
      for (int stage = 1; stage <= 5; stage++) {
        final path = species.getAssetPath(stage);
        futures.add(loadTreeSprite(path));
      }
      futures.add(loadTreeSprite(species.getWitheredAssetPath()));
    }

    await Future.wait(futures);
  }

  /// Renders a tree sprite centered horizontally at [anchorPoint.dx] with
  /// its base anchored precisely at [anchorPoint.dy].
  void drawTreeSprite({
    required Canvas canvas,
    required ui.Image image,
    required Offset anchorPoint,
    required double targetHeight,
    double opacity = 1.0,
  }) {
    final aspect = image.width / image.height;
    final targetWidth = targetHeight * aspect;

    final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dstRect = Rect.fromLTWH(
      anchorPoint.dx - (targetWidth / 2),
      anchorPoint.dy - targetHeight,
      targetWidth,
      targetHeight,
    );

    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..isAntiAlias = true;

    if (opacity < 1.0) {
      paint.color = Color.fromRGBO(255, 255, 255, opacity);
    }

    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  /// Clear the cache (for testing or memory pressure management)
  void clearCache() {
    for (final img in _spriteCache.values) {
      img.dispose();
    }
    _spriteCache.clear();
    _missingAssets.clear();
    _loadingFutures.clear();
  }
}
