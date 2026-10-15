import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/models/forest_decoration_model.dart';
import '../../../../core/models/forest_tree_model.dart';
import '../../../../core/services/tree_asset_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/forest_wildlife.dart';
import '../utils/planting_space_manager.dart';

/// 2.5D Coordinate Helper for Forest Positioning and Depth Sorting
class IsometricCoordinates {
  /// Converts normalized grid (u, v in 0..1) to screen coordinates.
  /// Preserves the standard 2:1 depth projection for sorting and positioning.
  static Offset gridToScreen({
    required double u,
    required double v,
    required double centerX,
    required double centerY,
    required double radiusX,
    required double radiusY,
  }) {
    final du = (u - 0.5) * 2.0;
    final dv = (v - 0.5) * 2.0;

    final screenX = centerX + (du - dv) * radiusX;
    final screenY = centerY + (du + dv) * radiusY;

    return Offset(screenX, screenY);
  }

  /// Depth sorting metric: entities further south (higher u + v)
  /// are in front and rendered after entities further north.
  static double depthMetric(double u, double v) => u + v;
}

/// Represents an entity to be rendered in the depth buffer
abstract class IsometricEntity {
  final double u;
  final double v;
  double get depth => IsometricCoordinates.depthMetric(u, v);

  IsometricEntity({required this.u, required this.v});
}

class TreeEntity extends IsometricEntity {
  final ForestTreeModel tree;
  final bool isSelected;
  final bool isActiveFocus;

  TreeEntity({
    required this.tree,
    this.isSelected = false,
    this.isActiveFocus = false,
  }) : super(u: tree.xRatio, v: tree.yRatio);
}

class DecorationEntity extends IsometricEntity {
  final ForestDecorationModel decoration;

  DecorationEntity({
    required this.decoration,
  }) : super(u: decoration.xRatio, v: decoration.yRatio);
}

class WildlifeEntity extends IsometricEntity {
  final ForestWildlife animal;

  WildlifeEntity({
    required this.animal,
  }) : super(u: animal.worldU, v: animal.worldV);
}

/// Delegate contract for SanctuaryViewController
abstract class SanctuaryViewDelegate {
  void animateSectorDelta(int delta);
  void animateToSector(int sectorIndex);
  void animateToWorldU(double targetU);
  void panBy(double delta);
  int get currentSectorIndex;
  int get totalSectorsCount;
}

/// Controller for programmatic navigation and pan control across sanctuary sectors
class SanctuaryViewController extends ChangeNotifier {
  SanctuaryViewDelegate? _delegate;

  void attach(SanctuaryViewDelegate delegate) {
    _delegate = delegate;
  }

  void detach() {
    _delegate = null;
  }

  void animateToNextSector() {
    _delegate?.animateSectorDelta(1);
  }

  void animateToPreviousSector() {
    _delegate?.animateSectorDelta(-1);
  }

  void animateToSector(int sectorIndex) {
    _delegate?.animateToSector(sectorIndex);
  }

  void animateToWorldU(double targetU) {
    _delegate?.animateToWorldU(targetU);
  }

  void panBy(double delta) {
    _delegate?.panBy(delta);
  }

  int get currentSector => _delegate?.currentSectorIndex ?? 0;
  int get totalSectors => _delegate?.totalSectorsCount ?? 1;

  void notifySectorUpdated() {
    notifyListeners();
  }
}

/// Stateful Interactive Forest Sanctuary View
/// Supports:
/// 1. Interactive horizontal panning (dragging left & right) with fluid momentum/inertia.
/// 2. Continuous endless transition (seamless modular panorama wrapping).
/// 3. Multi-layer parallax across sky, mountain ridges, horizon silhouettes, and meadow floor.
/// 4. Z-sorted interactive tree touch targets accessible at any pan offset.
class IsometricSanctuaryView extends StatefulWidget {
  final List<ForestTreeModel> trees;
  final List<ForestDecorationModel> decorations;
  final List<ForestWildlife>? wildlife;
  final bool isMoonlit;
  final bool isRaining;
  final ForestTreeModel? selectedTree;
  final String? activeFocusSessionId;
  final ValueChanged<ForestTreeModel>? onTreeTap;
  final ValueChanged<ForestDecorationModel>? onDecorationTap;
  final ValueChanged<ForestWildlife>? onWildlifeTap;
  final ValueChanged<int>? onSectorChanged;
  final SanctuaryViewController? controller;

  const IsometricSanctuaryView({
    super.key,
    required this.trees,
    required this.decorations,
    required this.isMoonlit,
    this.isRaining = false,
    this.wildlife,
    this.selectedTree,
    this.activeFocusSessionId,
    this.onTreeTap,
    this.onDecorationTap,
    this.onWildlifeTap,
    this.onSectorChanged,
    this.controller,
  });

  @override
  State<IsometricSanctuaryView> createState() => _IsometricSanctuaryViewState();
}

class _IsometricSanctuaryViewState extends State<IsometricSanctuaryView>
    with TickerProviderStateMixin
    implements SanctuaryViewDelegate {
  late AnimationController _windController;
  late AnimationController _inertiaController;
  Animation<double>? _inertiaAnimation;

  late final List<ForestWildlife> _wildlife;
  final Map<String, Rect> _treeHitBoxes = {};
  final Map<String, Rect> _decorationHitBoxes = {};
  final Map<String, Rect> _wildlifeHitBoxes = {};

  double _panOffset = 0.0;
  double _windGust = 0.0;
  double _continuousWindPhase = 0.0;
  double _dragTotalDistance = 0.0;
  int _lastNotifiedSector = -1;
  double _lastKnownWidth = 400.0;
  DateTime _lastFrameTime = DateTime.now();

  @override
  int get totalSectorsCount => PlantingSpaceManager.getSectorCount(widget.trees.length);

  @override
  int get currentSectorIndex {
    final count = totalSectorsCount;
    if (_lastKnownWidth <= 0 || count <= 0) return 0;
    return PlantingSpaceManager.getSectorIndexFromPan(_panOffset, _lastKnownWidth, count);
  }

  @override
  void initState() {
    super.initState();
    _wildlife = widget.wildlife ?? ForestWildlife.createDefaultWildlife();
    _lastFrameTime = DateTime.now();

    _windController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..addListener(_onWindTick)
     ..repeat();

    _inertiaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(() {
      if (_inertiaAnimation != null) {
        setState(() {
          _panOffset = _inertiaAnimation!.value;
        });
        _checkSectorChange();
      }
    })..addStatusListener((status) {
      if (status == AnimationStatus.completed && _inertiaAnimation != null) {
        setState(() {
          _panOffset = _inertiaAnimation!.value;
        });
        _checkSectorChange();
      }
    });

    widget.controller?.attach(this);
    _preloadSprites();
  }

  void _onWindTick() {
    final now = DateTime.now();
    final dt = (now.difference(_lastFrameTime).inMicroseconds / 1000000.0).clamp(0.001, 0.05);
    _lastFrameTime = now;
    _continuousWindPhase += dt / 3.6;
    if (_continuousWindPhase > 100000.0) {
      _continuousWindPhase -= 100000.0;
    }
    _windGust *= 0.93;
    final sectors = totalSectorsCount;
    for (final animal in _wildlife) {
      animal.update(dt, sectors);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tickerEnabled = TickerMode.of(context);
    if (tickerEnabled && !_windController.isAnimating) {
      _windController.repeat();
    } else if (!tickerEnabled && _windController.isAnimating) {
      _windController.stop();
    }
  }

  void _preloadSprites() {
    for (final tree in widget.trees) {
      TreeAssetService.instance.loadTreeSprite(tree.assetPath).then((img) {
        if (img != null && mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant IsometricSanctuaryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.detach();
      widget.controller?.attach(this);
    }
    if (widget.trees != oldWidget.trees) {
      _preloadSprites();
    }
  }

  @override
  void dispose() {
    widget.controller?.detach();
    _windController.dispose();
    _inertiaController.dispose();
    super.dispose();
  }

  void _checkSectorChange() {
    final current = currentSectorIndex;
    if (current != _lastNotifiedSector) {
      _lastNotifiedSector = current;
      widget.onSectorChanged?.call(current);
      widget.controller?.notifySectorUpdated();
    }
  }

  void _onHorizontalDragDown(DragDownDetails details) {
    _inertiaController.stop();
    _dragTotalDistance = 0.0;
  }

  void _onTapDown(TapDownDetails details) {
    _inertiaController.stop();
    _dragTotalDistance = 0.0;
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _inertiaController.stop();
    _dragTotalDistance = 0.0;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _dragTotalDistance += details.primaryDelta!.abs();
    _windGust = (_windGust + details.primaryDelta! / 35.0).clamp(-3.0, 3.0);
    setState(() {
      _panOffset += details.primaryDelta!;
    });
    _checkSectorChange();
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (velocity.abs() > 60) {
      _startInertiaFling(velocity);
    }
  }

  void _startInertiaFling(double velocity) {
    _inertiaController.stop();
    final start = _panOffset;
    final flingDelta = velocity * 0.28;
    final durationMs = (velocity.abs() * 0.35).clamp(250, 750).toInt();

    _inertiaController.duration = Duration(milliseconds: durationMs);
    _inertiaAnimation = Tween<double>(begin: start, end: start + flingDelta).animate(
      CurvedAnimation(parent: _inertiaController, curve: Curves.decelerate),
    );

    _inertiaController.forward(from: 0.0);
  }

  @override
  void animateSectorDelta(int delta) {
    if (_lastKnownWidth <= 0) return;
    _inertiaController.stop();
    final currentPan = _panOffset;
    final currentSectorNormalized = (-currentPan / _lastKnownWidth).round();
    final targetPan = -(currentSectorNormalized + delta) * _lastKnownWidth;

    _inertiaController.duration = const Duration(milliseconds: 380);
    _inertiaAnimation = Tween<double>(begin: currentPan, end: targetPan).animate(
      CurvedAnimation(parent: _inertiaController, curve: Curves.easeInOutCubic),
    );

    _inertiaController.forward(from: 0.0);
  }

  @override
  void animateToSector(int targetSector) {
    final current = currentSectorIndex;
    final delta = targetSector - current;
    if (delta != 0) {
      animateSectorDelta(delta);
    }
  }

  @override
  void animateToWorldU(double targetU) {
    if (_lastKnownWidth <= 0) return;
    _inertiaController.stop();
    final sectors = totalSectorsCount;
    final panoramaWidth = sectors * _lastKnownWidth;
    final currentPan = _panOffset;
    final targetPan = 0.5 * panoramaWidth - (targetU * panoramaWidth);

    _inertiaController.duration = const Duration(milliseconds: 550);
    _inertiaAnimation = Tween<double>(begin: currentPan, end: targetPan).animate(
      CurvedAnimation(parent: _inertiaController, curve: Curves.easeInOutCubic),
    );

    _inertiaController.forward(from: 0.0);
  }

  @override
  void panBy(double delta) {
    setState(() {
      _panOffset += delta;
    });
    _checkSectorChange();
  }

  void _handleTapUp(TapUpDetails details) {
    // If user dragged more than 12 pixels, treat as swipe gesture, not tap
    if (_dragTotalDistance > 12.0) return;

    final pos = details.localPosition;

    // 1. Check wildlife (both ground roaming animals and soaring sky birds)
    if (widget.onWildlifeTap != null) {
      final sortedWildlife = List<ForestWildlife>.from(_wildlife)
        ..sort((a, b) => (b.worldU + b.worldV).compareTo(a.worldU + a.worldV));

      for (final animal in sortedWildlife) {
        final rect = _wildlifeHitBoxes[animal.id];
        if (rect != null && rect.inflate(4.0).contains(pos)) {
          animal.triggerTap();
          setState(() {});
          widget.onWildlifeTap?.call(animal);
          return;
        }
      }
    }

    // 2. Check trees front-to-back (highest depth metric first)
    final sortedTrees = List<ForestTreeModel>.from(widget.trees)
      ..sort((a, b) => (b.xRatio + b.yRatio).compareTo(a.xRatio + a.yRatio));

    for (final tree in sortedTrees) {
      final rect = _treeHitBoxes[tree.id];
      if (rect != null && rect.inflate(10.0).contains(pos)) {
        widget.onTreeTap?.call(tree);
        return;
      }
    }

    // 3. Check decorations
    for (final dec in widget.decorations) {
      final rect = _decorationHitBoxes[dec.id];
      if (rect != null && rect.inflate(10.0).contains(pos)) {
        widget.onDecorationTap?.call(dec);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _lastKnownWidth = constraints.maxWidth;
        return AnimatedBuilder(
          animation: _windController,
          builder: (context, child) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragDown: _onHorizontalDragDown,
              onTapDown: _onTapDown,
              onHorizontalDragStart: _onHorizontalDragStart,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              onTapUp: _handleTapUp,
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: IsometricForestPainter(
                    trees: widget.trees,
                    decorations: widget.decorations,
                    wildlife: _wildlife,
                    isMoonlit: widget.isMoonlit,
                    isRaining: widget.isRaining,
                    selectedTreeId: widget.selectedTree?.id,
                    activeFocusSessionId: widget.activeFocusSessionId,
                    windPhase: _continuousWindPhase,
                    panOffset: _panOffset,
                    windGust: _windGust,
                    treeHitBoxes: _treeHitBoxes,
                    decorationHitBoxes: _decorationHitBoxes,
                    wildlifeHitBoxes: _wildlifeHitBoxes,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Immersive Storybook Forest Painter
/// Replaces flat canvas fills with rich, lightweight, layered 2.5D artwork
class IsometricForestPainter extends CustomPainter {
  final List<ForestTreeModel> trees;
  final List<ForestDecorationModel> decorations;
  final List<ForestWildlife>? wildlife;
  final bool isMoonlit;
  final bool isRaining;
  final String? selectedTreeId;
  final String? activeFocusSessionId;
  final double windPhase;
  final double panOffset;
  final double windGust;
  final Map<String, Rect>? treeHitBoxes;
  final Map<String, Rect>? decorationHitBoxes;
  final Map<String, Rect>? wildlifeHitBoxes;

  // Reusable static paint instances to eliminate GC pressure during animation loops
  static final Paint _skyPaint = Paint();
  static final Paint _cloudPaint = Paint();
  static final Paint _sunbeamPaint = Paint();
  static final Paint _sunGlowPaint = Paint();
  static final Paint _sunBodyPaint = Paint();
  static final Paint _ridgePaint = Paint();
  static final Paint _canopyPaint = Paint();
  static final Paint _groundKnollPaint = Paint();
  static final Paint _groundGladePaint = Paint();
  static final Paint _gladeHighlightPaint = Paint();
  static final Paint _dappledSunPaint = Paint();
  static final Paint _pathPaint = Paint()
    ..strokeWidth = 24
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _ambientShadowPaint = Paint();
  static final Paint _castShadowPaint = Paint();
  static final Paint _stoneBasePaint = Paint();
  static final Paint _stoneMossPaint = Paint();
  static final Paint _fernPaint = Paint()
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  static final Paint _grassPaint = Paint()
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  static final Paint _flowerPetalPaint = Paint();
  static final Paint _flowerCorePaint = Paint();
  static final Paint _leafLitterPaint = Paint();
  static final Paint _frondForegroundPaint = Paint();
  static final Paint _windTrailPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _leafPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _leafVeinPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 0.8;
  static final Paint _leafGlowPaint = Paint();
  static final Paint _underwaterShadowPaint = Paint();
  static final Paint _shorelinePaint = Paint();
  static final Path _tempSilhouettePath = Path();
  static final Path _tempGrassPath = Path();
  static final Paint _animalBodyPaint = Paint();
  static final Paint _animalDetailPaint = Paint();
  static final Paint _animalFeaturePaint = Paint();
  static final Paint _animalEyePaint = Paint()..color = const Color(0xFF212121);
  static final Paint _animalEyeWhitePaint = Paint()..color = Colors.white;
  static final Paint _animalHeartPaint = Paint()..color = const Color(0xFFFF5252);
  static final Paint _animalHeartGlowPaint = Paint()
    ..color = const Color(0xFFFF8DA1).withValues(alpha: 0.5);
  static final Paint _shootingStarPaint = Paint();
  static final Paint _waterSpringPaint = Paint();
  static final Paint _waterRipplePaint = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
  static final Paint _waterStonePaint = Paint();
  static final Paint _rainDropPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _rainSplashPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _rainMistPaint = Paint();
  static final Paint _rainAtmospherePaint = Paint();

  IsometricForestPainter({
    required this.trees,
    required this.decorations,
    this.wildlife,
    required this.isMoonlit,
    this.isRaining = false,
    this.selectedTreeId,
    this.activeFocusSessionId,
    required this.windPhase,
    this.panOffset = 0.0,
    this.windGust = 0.0,
    this.treeHitBoxes,
    this.decorationHitBoxes,
    this.wildlifeHitBoxes,
  });

  /// Maps a world X coordinate into screen coordinate with modular seamless wrapping
  double _wrapWorldXToScreen(double worldX, double panoramaWidth, double pan, double viewportWidth) {
    final camX = 0.5 * panoramaWidth - pan;
    final dx = worldX - camX;
    double wrappedDx = (dx % panoramaWidth + panoramaWidth) % panoramaWidth;
    if (wrappedDx > panoramaWidth / 2) {
      wrappedDx -= panoramaWidth;
    }
    return viewportWidth * 0.5 + wrappedDx;
  }

  /// Calculates on-screen coordinate for an isometric entity in the endless panorama
  Offset _getPanoramicEntityScreenPos({
    required double u,
    required double v,
    required double centerX,
    required double centerY,
    required double radiusX,
    required double radiusY,
    required double panoramaWidth,
    required double pan,
    required double viewportWidth,
  }) {
    final worldX = u * panoramaWidth;
    final screenX = _wrapWorldXToScreen(worldX, panoramaWidth, pan, viewportWidth) + (v - 0.5) * 36.0;
    final screenY = centerY + (v - 0.5) * (radiusY * 2.2);
    return Offset(screenX, screenY);
  }

  @override
  void paint(Canvas canvas, Size size) {
    treeHitBoxes?.clear();
    decorationHitBoxes?.clear();
    wildlifeHitBoxes?.clear();

    final w = size.width;
    final h = size.height;
    final totalSectors = PlantingSpaceManager.getSectorCount(trees.length);
    final panoramaWidth = totalSectors * w;

    // 1. Atmosphere & Sky (Top 0-38% of screen)
    _drawSkyAndSunbeams(canvas, size, panoramaWidth);

    // 2. Celestial Body (Warm Sun or Ivory Crescent Moon)
    _drawCelestialBody(canvas, size);

    // 2.2 Shooting Stars (Meteors in Moonlit Night mode)
    if (isMoonlit) {
      _drawShootingStars(canvas, size);
    }

    // 2.5 Soaring Sky Birds
    _drawFlyingSkyBirds(canvas, size, panoramaWidth);

    // 3. Layered Background Horizon & Distant Forest Canopy (25-45% of screen)
    _drawBackgroundForestRidge(canvas, size);

    // 4. Continuous Living Forest Floor (34-100% of screen with rich textures & dappled light)
    _drawContinuousForestFloor(canvas, size, totalSectors, panoramaWidth);

    // 4.5 Glade Spring Pool (Sector 1 crystal waters with koi fish and water ripples)
    _drawGladeSpringPool(canvas, size, totalSectors, panoramaWidth);

    // 5. Ambient Mature Trees Framing the Glade (Wings & Back Treeline)
    _drawFramingForestTrees(canvas, size, totalSectors, panoramaWidth);

    // 6. Natural Forest Ground Details (Ferns, Mossy Stones, Wildflowers, Clover, Grasses)
    _drawForestFloorDetails(canvas, size, totalSectors, panoramaWidth);

    // 7. Z-Sorted Planted Trees & Equipped Decorations
    final gladeCenter = Offset(w * 0.5, h * 0.50);
    final gladeRadiusX = w * 0.40;
    final gladeRadiusY = h * 0.20;
    _drawZSortedEntities(canvas, size, gladeCenter, gladeRadiusX, gladeRadiusY, totalSectors, panoramaWidth);

    // 8. Foreground Vignette & Botanical Fronds (Bottom corners for depth)
    _drawForegroundBotanicals(canvas, size);

    // 9. Ambient Environmental Animation (Drifting Sakura Petals / Fireflies)
    _drawEnvironmentalParticles(canvas, size);

    // 10. Live Falling Rain Effect (Atmospheric veil, drops, splashes & mist)
    if (isRaining) {
      _drawRainEffect(canvas, size);
    }
  }

  // ─── 1. ATMOSPHERE & SUNBEAMS ───
  void _drawSkyAndSunbeams(Canvas canvas, Size size, double panoramaWidth) {
    final w = size.width;
    final h = size.height;

    if (isMoonlit) {
      _skyPaint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0A141A), // Deep velvet midnight
          Color(0xFF0F2225), // Nocturnal pine teal
          Color(0xFF16322C), // Mist at tree line
        ],
        stops: [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.45));
    } else {
      _skyPaint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFC2DFD7), // Gentle sage-tinted morning sky
          Color(0xFFD9EDE3), // Pale woodland mist
          Color(0xFFF0F7EC), // Warm sunlit haze above tree line
        ],
        stops: [0.0, 0.50, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.45));
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.45), _skyPaint);

    // Soft drifting clouds with parallax
    final cloudDrift = math.sin(windPhase * math.pi * 2) * 6.0;
    final cloudParallax = panOffset * 0.08;
    _cloudPaint.color = (isMoonlit ? const Color(0xFF1F3835) : Colors.white)
        .withValues(alpha: isMoonlit ? 0.25 : 0.55);

    final c1X = ((w * 0.22 + cloudDrift + cloudParallax) % w + w) % w;
    final c2X = ((w * 0.78 - cloudDrift * 0.7 + cloudParallax * 0.75) % w + w) % w;

    _drawCloud(canvas, Offset(c1X, h * 0.17), 65, _cloudPaint);
    _drawCloud(canvas, Offset(c2X, h * 0.14), 80, _cloudPaint);

    // Soft Filtered Sunbeams (God Rays) streaming through the canopy (Sunlight mode only)
    if (!isMoonlit) {
      final rayShift = (panOffset * 0.05).clamp(-w * 0.15, w * 0.15);
      _sunbeamPaint.shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x28FFF9C4), // Warm translucent sunlight
          Color(0x12FFFDE7),
          Color(0x00FFFDE7),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.65));

      final ray1 = Path()
        ..moveTo(w * 0.70 + rayShift, 0)
        ..lineTo(w * 0.88 + rayShift, 0)
        ..lineTo(w * 0.40 + rayShift * 0.5, h * 0.55)
        ..lineTo(w * 0.18 + rayShift * 0.5, h * 0.55)
        ..close();
      canvas.drawPath(ray1, _sunbeamPaint);

      final ray2 = Path()
        ..moveTo(w * 0.82 + rayShift, 0)
        ..lineTo(w + rayShift, 0)
        ..lineTo(w * 0.75 + rayShift * 0.5, h * 0.60)
        ..lineTo(w * 0.55 + rayShift * 0.5, h * 0.60)
        ..close();
      canvas.drawPath(ray2, _sunbeamPaint);
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double width, Paint paint) {
    final r = width * 0.20;
    canvas.drawCircle(Offset(center.dx - r * 1.2, center.dy + r * 0.2), r * 0.8, paint);
    canvas.drawCircle(Offset(center.dx, center.dy - r * 0.2), r * 1.15, paint);
    canvas.drawCircle(Offset(center.dx + r * 1.1, center.dy + r * 0.1), r * 0.85, paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy + r * 0.35), width: width, height: r * 1.0), paint);
  }

  // ─── 2. CELESTIAL BODY ───
  void _drawCelestialBody(Canvas canvas, Size size) {
    final celestialShift = (panOffset * 0.035).clamp(-size.width * 0.12, size.width * 0.12);

    if (isMoonlit) {
      final moonCenter = Offset(size.width * 0.80 + celestialShift, size.height * 0.21);
      _sunGlowPaint.color = const Color(0xFFE0F2F1).withValues(alpha: 0.20);
      canvas.drawCircle(moonCenter, 24, _sunGlowPaint);

      _sunBodyPaint.color = const Color(0xFFE8F5E9);
      canvas.drawCircle(moonCenter, 15, _sunBodyPaint);

      final darkCutout = Paint()..color = const Color(0xFF0F2225);
      canvas.drawCircle(Offset(moonCenter.dx - 5, moonCenter.dy - 3), 13, darkCutout);
    } else {
      final sunCenter = Offset(size.width * 0.80 + celestialShift, size.height * 0.21);
      _sunGlowPaint.color = const Color(0xFFFFE082).withValues(alpha: 0.35);
      canvas.drawCircle(sunCenter, 30, _sunGlowPaint);

      _sunBodyPaint.color = const Color(0xFFFFF9C4);
      canvas.drawCircle(sunCenter, 17, _sunBodyPaint);
    }
  }

  // ─── 3. LAYERED BACKGROUND FOREST RIDGE ───
  void _drawBackgroundForestRidge(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Layer 1: Distant misty ridge silhouette (Parallax 0.15x, smooth continuous harmonic waves)
    final farRidge = Path();
    final ridgeShift = panOffset * 0.15;
    farRidge.moveTo(-20, h * 0.44);
    for (double x = -20; x <= w + 20; x += 16) {
      final effX = x - ridgeShift;
      final wave1 = math.sin(effX * (2 * math.pi / (w * 0.95)));
      final wave2 = math.cos(effX * (2 * math.pi / (w * 1.45)));
      final y = h * 0.33 + wave1 * (h * 0.024) + wave2 * (h * 0.016);
      farRidge.lineTo(x, y);
    }
    farRidge.lineTo(w + 20, h * 0.44);
    farRidge.lineTo(-20, h * 0.44);
    farRidge.close();

    _ridgePaint.color = (isMoonlit ? const Color(0xFF142B24) : const Color(0xFFA2C2A8)).withValues(alpha: 0.55);
    canvas.drawPath(farRidge, _ridgePaint);

    // Layer 2: Mid-distance randomized dense forest canopy silhouettes across the horizon (Parallax 0.35x)
    // Streamlined spacing (48px) to reduce tree count and maximize 60/120fps scrolling performance
    const d = 48.0;
    final treelineShift = panOffset * 0.35;
    final startIdx = ((-d * 2 - treelineShift) / d).floor();
    final endIdx = ((w + d * 2 - treelineShift) / d).ceil();

    final dayTints = const [
      Color(0xFF5A8562), // Deep pine emerald
      Color(0xFF6B9672), // Classic woodland green
      Color(0xFF7CA37C), // Soft sage mist
      Color(0xFF8BAF7A), // Warm olive gold
      Color(0xFF5D7F60), // Distant spruce
    ];

    final nightTints = const [
      Color(0xFF0F2620), // Deep midnight pine
      Color(0xFF132B25), // Twilight slate spruce
      Color(0xFF17382E), // Moonlit juniper
      Color(0xFF0C1D18), // Dark shadowy woodland
    ];

    final tints = isMoonlit ? nightTints : dayTints;

    for (int i = startIdx; i <= endIdx; i++) {
      final r1 = _pseudoHash(i, 1);
      final r2 = _pseudoHash(i, 2);
      final r3 = _pseudoHash(i, 3);
      final r4 = _pseudoHash(i, 4);
      final r5 = _pseudoHash(i, 5);

      final tx = i * d + treelineShift + (r1 - 0.5) * 12.0;
      final ty = h * (0.33 + (math.sin(i * 1.3) * 0.016) + (r2 - 0.5) * 0.010);
      final treeHeight = 24.0 + r3 * 22.0; // Random heights between 24 and 46
      final treeWidth = 18.0 + r4 * 16.0;  // Random widths between 18 and 34

      final treeColor = tints[(r5 * tints.length).floor() % tints.length];
      _canopyPaint.color = treeColor.withValues(alpha: 0.82);

      final treeType = (r5 * 4).floor() % 4;
      switch (treeType) {
        case 0:
          _drawSilhouettePine(canvas, tx, ty, treeWidth, treeHeight, _canopyPaint);
          break;
        case 1:
          _drawSilhouetteOak(canvas, tx, ty, treeWidth, treeHeight, _canopyPaint);
          break;
        case 2:
          _drawSilhouetteBirch(canvas, tx, ty, treeWidth * 0.8, treeHeight * 1.12, _canopyPaint);
          break;
        case 3:
          _drawSilhouetteCedar(canvas, tx, ty, treeWidth * 1.15, treeHeight * 0.88, _canopyPaint);
          break;
      }
    }
  }

  static double _pseudoHash(int i, int salt) {
    int n = i * 374761393 + salt * 668265263;
    n = (n ^ (n >> 13)) * 1274126177;
    return ((n ^ (n >> 16)) & 0x7FFFFFFF) / 2147483647.0;
  }

  void _drawSilhouettePine(Canvas canvas, double x, double baseY, double width, double height, Paint paint) {
    _tempSilhouettePath.reset();
    _tempSilhouettePath
      ..moveTo(x, baseY - height)
      ..lineTo(x + width * 0.5, baseY)
      ..lineTo(x - width * 0.5, baseY)
      ..close();
    canvas.drawPath(_tempSilhouettePath, paint);
  }

  void _drawSilhouetteOak(Canvas canvas, double x, double baseY, double width, double height, Paint paint) {
    canvas.drawCircle(Offset(x, baseY - height * 0.6), width * 0.48, paint);
    canvas.drawCircle(Offset(x - width * 0.28, baseY - height * 0.38), width * 0.36, paint);
    canvas.drawCircle(Offset(x + width * 0.28, baseY - height * 0.38), width * 0.36, paint);
  }

  void _drawSilhouetteBirch(Canvas canvas, double x, double baseY, double width, double height, Paint paint) {
    // Tall slender oval canopy
    final rect = Rect.fromCenter(
      center: Offset(x, baseY - height * 0.55),
      width: width * 0.7,
      height: height * 0.9,
    );
    canvas.drawOval(rect, paint);
  }

  void _drawSilhouetteCedar(Canvas canvas, double x, double baseY, double width, double height, Paint paint) {
    // Tiered layered horizontal cushions
    const tiers = 3;
    for (int t = 0; t < tiers; t++) {
      final tierY = baseY - height * (0.35 + t * 0.25);
      final tierW = width * (1.0 - t * 0.22);
      final tierH = height * 0.32;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, tierY), width: tierW, height: tierH),
        paint,
      );
    }
  }

  // ─── 4. CONTINUOUS LIVING FOREST FLOOR ───
  void _drawContinuousForestFloor(Canvas canvas, Size size, int totalSectors, double panoramaWidth) {
    final w = size.width;
    final h = size.height;

    // Layer 1: Back woodland knoll (distant ground slope, Parallax 0.65x)
    final backKnoll = Path();
    final knollShift = panOffset * 0.65;
    backKnoll.moveTo(-20, h);
    for (double x = -20; x <= w + 20; x += 18) {
      final effX = x - knollShift;
      final y = h * 0.36 + math.sin(effX * (2 * math.pi / (w * 1.1))) * (h * 0.022);
      backKnoll.lineTo(x, y);
    }
    backKnoll.lineTo(w + 20, h);
    backKnoll.close();

    if (isMoonlit) {
      _groundKnollPaint.color = const Color(0xFF132A20);
      _groundKnollPaint.shader = null;
    } else {
      _groundKnollPaint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF6E9944), Color(0xFF558231)],
      ).createShader(Rect.fromLTWH(0, h * 0.34, w, h * 0.25));
    }
    canvas.drawPath(backKnoll, _groundKnollPaint);

    // Layer 2: Main sanctuary glade terrain (Parallax 1.0x continuous rolling clearing)
    final mainGlade = Path();
    final gladeShift = panOffset;
    mainGlade.moveTo(-20, h);
    for (double x = -20; x <= w + 20; x += 18) {
      final effX = x - gladeShift;
      final y = h * 0.42 +
          math.sin(effX * (2 * math.pi / (w * 1.25))) * (h * 0.025) +
          math.cos(effX * (2 * math.pi / (w * 0.85))) * (h * 0.016);
      mainGlade.lineTo(x, y);
    }
    mainGlade.lineTo(w + 20, h);
    mainGlade.close();

    if (isMoonlit) {
      _groundGladePaint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF183B2C), // Deep nocturnal moss
          Color(0xFF132F23),
          Color(0xFF0F241B),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, h * 0.38, w, h * 0.62));
    } else {
      _groundGladePaint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF8DBF4B), // Sunny clearing grass
          Color(0xFF75A63B), // Warm woodland green
          Color(0xFF59852B), // Forest floor moss
          Color(0xFF486E23), // Deep earthy loam near foreground
        ],
        stops: [0.0, 0.35, 0.70, 1.0],
      ).createShader(Rect.fromLTWH(0, h * 0.38, w, h * 0.62));
    }
    canvas.drawPath(mainGlade, _groundGladePaint);

    // Layer 3: Soft ambient sunlight clearing highlight per visible sector
    _gladeHighlightPaint.color = (isMoonlit ? const Color(0xFF265A46) : const Color(0xFFAED581))
        .withValues(alpha: isMoonlit ? 0.25 : 0.42);

    for (int s = 0; s < totalSectors; s++) {
      final sectorWorldX = (s + 0.5) * w;
      final screenCenterX = _wrapWorldXToScreen(sectorWorldX, panoramaWidth, panOffset, w);
      if (screenCenterX >= -w * 0.6 && screenCenterX <= w * 1.6) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(screenCenterX, h * 0.52), width: w * 0.75, height: h * 0.26),
          _gladeHighlightPaint,
        );

        // Layer 4: Subtle dappled light patches across this glade
        if (!isMoonlit) {
          _dappledSunPaint.color = const Color(0xFFFFF9C4).withValues(alpha: 0.16);
          canvas.drawOval(Rect.fromCenter(center: Offset(screenCenterX - w * 0.14, h * 0.58), width: w * 0.30, height: h * 0.10), _dappledSunPaint);
          canvas.drawOval(Rect.fromCenter(center: Offset(screenCenterX + w * 0.14, h * 0.50), width: w * 0.28, height: h * 0.09), _dappledSunPaint);
          canvas.drawOval(Rect.fromCenter(center: Offset(screenCenterX - w * 0.02, h * 0.68), width: w * 0.35, height: h * 0.11), _dappledSunPaint);
        }

        // Layer 5: Earthy pathway meandering through this glade
        _pathPaint.color = (isMoonlit ? const Color(0xFF1B2A1E) : const Color(0xFF8D6E63))
            .withValues(alpha: isMoonlit ? 0.35 : 0.22);
        final softPath = Path()
          ..moveTo(screenCenterX - w * 0.30, h * 0.62)
          ..cubicTo(screenCenterX - w * 0.12, h * 0.56, screenCenterX + w * 0.12, h * 0.54, screenCenterX + w * 0.32, h * 0.48);
        canvas.drawPath(softPath, _pathPaint);
      }
    }
  }

  // ─── 5. AMBIENT MATURE TREES FRAMING THE GLADE ───
  void _drawFramingForestTrees(Canvas canvas, Size size, int totalSectors, double panoramaWidth) {
    final w = size.width;
    final h = size.height;
    final windSway = math.sin(windPhase * math.pi * 2) * 0.025;

    final leftFlankSpecies = const [
      TreeSpecies.mountainPine,
      TreeSpecies.ancientOak,
      TreeSpecies.cherryBlossom,
      TreeSpecies.silverBirch,
    ];
    final rightFlankSpecies = const [
      TreeSpecies.ancientOak,
      TreeSpecies.goldenGinkgo,
      TreeSpecies.mountainPine,
      TreeSpecies.riverWillow,
    ];

    for (int s = 0; s < totalSectors; s++) {
      final leftSpec = leftFlankSpecies[s % leftFlankSpecies.length];
      final rightSpec = rightFlankSpecies[(s + 1) % rightFlankSpecies.length];

      // Left flank framing tree
      final leftWorldX = s * w + w * 0.06;
      final leftScreenX = _wrapWorldXToScreen(leftWorldX, panoramaWidth, panOffset, w);
      if (leftScreenX >= -70 && leftScreenX <= w + 70) {
        _drawFramingTree(canvas, Offset(leftScreenX, h * 0.46), 1.20 + (s % 2) * 0.1, leftSpec, windSway);
      }

      // Mid-left framing wing
      final midLeftWorldX = s * w + w * 0.16;
      final midLeftScreenX = _wrapWorldXToScreen(midLeftWorldX, panoramaWidth, panOffset, w);
      if (midLeftScreenX >= -70 && midLeftScreenX <= w + 70) {
        _drawFramingTree(canvas, Offset(midLeftScreenX, h * 0.41), 0.95 + ((s + 1) % 2) * 0.1, TreeSpecies.ancientOak, windSway * 0.8);
      }

      // Right flank framing tree
      final rightWorldX = s * w + w * 0.94;
      final rightScreenX = _wrapWorldXToScreen(rightWorldX, panoramaWidth, panOffset, w);
      if (rightScreenX >= -70 && rightScreenX <= w + 70) {
        _drawFramingTree(canvas, Offset(rightScreenX, h * 0.45), 1.15 + ((s + 1) % 2) * 0.1, rightSpec, -windSway);
      }

      // Mid-right framing wing
      final midRightWorldX = s * w + w * 0.84;
      final midRightScreenX = _wrapWorldXToScreen(midRightWorldX, panoramaWidth, panOffset, w);
      if (midRightScreenX >= -70 && midRightScreenX <= w + 70) {
        _drawFramingTree(canvas, Offset(midRightScreenX, h * 0.40), 1.00 + (s % 2) * 0.08, TreeSpecies.mountainPine, -windSway * 0.7);
      }
    }
  }

  void _drawFramingTree(Canvas canvas, Offset pos, double scale, TreeSpecies species, double sway) {
    // Contact drop shadow on the living forest floor
    _ambientShadowPaint.color = Colors.black.withValues(alpha: isMoonlit ? 0.30 : 0.16);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy + 3), width: 44 * scale, height: 16 * scale),
      _ambientShadowPaint,
    );

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(scale);
    canvas.rotate(sway);

    final trunkColor = isMoonlit ? const Color(0xFF2E221B) : const Color(0xFF4E342E);
    if (species == TreeSpecies.mountainPine) {
      _drawPineIllustrated(canvas, trunkColor);
    } else {
      _drawOakIllustrated(canvas, trunkColor);
    }

    canvas.restore();
  }

  // ─── 6. FOREST FLOOR DETAILS (Ferns, stones, wildflowers, clover, grass) ───
  void _drawForestFloorDetails(Canvas canvas, Size size, int totalSectors, double panoramaWidth) {
    final w = size.width;
    final h = size.height;
    final windSway = math.sin(windPhase * math.pi * 2) * 2.2;

    _stoneBasePaint.color = isMoonlit ? const Color(0xFF263238) : const Color(0xFF6D7B75);
    _stoneMossPaint.color = isMoonlit ? const Color(0xFF1B3D2F) : const Color(0xFF689F38);
    _fernPaint.color = (isMoonlit ? const Color(0xFF1F523B) : const Color(0xFF43A047)).withValues(alpha: 0.85);
    _grassPaint.color = (isMoonlit ? const Color(0xFF265A42) : const Color(0xFF7CB342)).withValues(alpha: 0.85);
    _leafLitterPaint.color = isMoonlit ? const Color(0xFF3E2D22) : const Color(0xFF8D6E63);

    const flowers = [
      _MeadowFlower(0.30, 0.50, Color(0xFFFFFFFF), Color(0xFFFFD54F)), // Wood anemone
      _MeadowFlower(0.46, 0.62, Color(0xFFFFF9C4), Color(0xFFFFB300)), // Buttercup
      _MeadowFlower(0.64, 0.48, Color(0xFFE1BEE7), Color(0xFF8E24AA)), // Woodland violet
      _MeadowFlower(0.72, 0.66, Color(0xFFFFCDD2), Color(0xFFE91E63)), // Wild primrose
      _MeadowFlower(0.38, 0.72, Color(0xFFBBDEFB), Color(0xFF1976D2)), // Forget-me-not
      _MeadowFlower(0.58, 0.56, Color(0xFFFFFFFF), Color(0xFFFFD54F)), // Daisy
      _MeadowFlower(0.25, 0.68, Color(0xFFFFF9C4), Color(0xFFFFB300)), // Buttercup
    ];

    const grassSpots = [
      Offset(0.28, 0.45), Offset(0.42, 0.52), Offset(0.55, 0.44),
      Offset(0.68, 0.60), Offset(0.35, 0.64), Offset(0.78, 0.48),
      Offset(0.50, 0.68),
    ];

    final matureCount = trees.where((t) => t.stage >= 5).length;

    for (int s = 0; s < totalSectors; s++) {
      final sWorldX = s * w;

      // 1. Moss-covered forest stones nestled in the grass
      final s1X = _wrapWorldXToScreen(sWorldX + w * 0.22, panoramaWidth, panOffset, w);
      if (s1X >= -30 && s1X <= w + 30) {
        final s1 = Offset(s1X, h * 0.58);
        canvas.drawOval(Rect.fromCenter(center: s1, width: 22, height: 12), _stoneBasePaint);
        canvas.drawOval(Rect.fromCenter(center: Offset(s1.dx, s1.dy - 3), width: 18, height: 8), _stoneMossPaint);
      }

      final s2X = _wrapWorldXToScreen(sWorldX + w * 0.76, panoramaWidth, panOffset, w);
      if (s2X >= -30 && s2X <= w + 30) {
        final s2 = Offset(s2X, h * 0.54);
        canvas.drawOval(Rect.fromCenter(center: s2, width: 28, height: 14), _stoneBasePaint);
        canvas.drawOval(Rect.fromCenter(center: Offset(s2.dx - 2, s2.dy - 3), width: 22, height: 9), _stoneMossPaint);
      }

      // 2. Beautiful Woodland Ferns
      final f1X = _wrapWorldXToScreen(sWorldX + w * 0.14, panoramaWidth, panOffset, w);
      if (f1X >= -30 && f1X <= w + 30) {
        _drawFernCluster(canvas, Offset(f1X, h * 0.65), windSway, _fernPaint);
      }
      final f2X = _wrapWorldXToScreen(sWorldX + w * 0.86, panoramaWidth, panOffset, w);
      if (f2X >= -30 && f2X <= w + 30) {
        _drawFernCluster(canvas, Offset(f2X, h * 0.62), -windSway, _fernPaint);
      }

      // 3. Clover clusters (3-leaf shamrocks)
      final c1X = _wrapWorldXToScreen(sWorldX + w * 0.34, panoramaWidth, panOffset, w);
      if (c1X >= -20 && c1X <= w + 20) {
        _drawCloverCluster(canvas, Offset(c1X, h * 0.53));
      }
      final c2X = _wrapWorldXToScreen(sWorldX + w * 0.70, panoramaWidth, panOffset, w);
      if (c2X >= -20 && c2X <= w + 20) {
        _drawCloverCluster(canvas, Offset(c2X, h * 0.59));
      }

      // 4. Delicate Wildflowers scattered through the glade
      for (final f in flowers) {
        final fx = _wrapWorldXToScreen(sWorldX + w * f.u, panoramaWidth, panOffset, w);
        if (fx < -10 || fx > w + 10) continue;
        final fy = h * f.v;

        _flowerPetalPaint.color = isMoonlit ? f.petalColor.withValues(alpha: 0.6) : f.petalColor;
        _flowerCorePaint.color = f.coreColor;

        canvas.drawCircle(Offset(fx - 2, fy), 1.6, _flowerPetalPaint);
        canvas.drawCircle(Offset(fx + 2, fy), 1.6, _flowerPetalPaint);
        canvas.drawCircle(Offset(fx, fy - 2), 1.6, _flowerPetalPaint);
        canvas.drawCircle(Offset(fx, fy + 2), 1.6, _flowerPetalPaint);
        canvas.drawCircle(Offset(fx, fy), 1.2, _flowerCorePaint);
      }

      // 5. Natural grass tufts swaying in the glade
      for (final spot in grassSpots) {
        final gx = _wrapWorldXToScreen(sWorldX + w * spot.dx, panoramaWidth, panOffset, w);
        if (gx < -10 || gx > w + 10) continue;
        final gy = h * spot.dy;

        _tempGrassPath.reset();
        _tempGrassPath
          ..moveTo(gx - 2, gy)
          ..quadraticBezierTo(gx - 4 + windSway, gy - 6, gx - 6 + windSway, gy - 9)
          ..moveTo(gx, gy)
          ..quadraticBezierTo(gx + windSway * 0.5, gy - 8, gx + 1 + windSway, gy - 12)
          ..moveTo(gx + 2, gy)
          ..quadraticBezierTo(gx + 4 + windSway, gy - 6, gx + 6 + windSway, gy - 9);
        canvas.drawPath(_tempGrassPath, _grassPaint);
      }

      // 6. Fallen Leaves & Petals on the ground
      final l1X = _wrapWorldXToScreen(sWorldX + w * 0.20, panoramaWidth, panOffset, w);
      if (l1X >= -10 && l1X <= w + 10) {
        canvas.drawCircle(Offset(l1X, h * 0.52), 2.2, _leafLitterPaint);
      }
      final l2X = _wrapWorldXToScreen(sWorldX + w * 0.74, panoramaWidth, panOffset, w);
      if (l2X >= -10 && l2X <= w + 10) {
        canvas.drawCircle(Offset(l2X, h * 0.48), 2.0, _leafLitterPaint);
      }

      // 7. Mature Forest Ecosystem Understory
      if (matureCount >= 5 || trees.length >= 12) {
        final m1X = _wrapWorldXToScreen(sWorldX + w * 0.24, panoramaWidth, panOffset, w);
        if (m1X >= -15 && m1X <= w + 15) {
          _drawMushroom(canvas, Offset(m1X, h * 0.59), isScarlet: true);
        }
        final m2X = _wrapWorldXToScreen(sWorldX + w * 0.76, panoramaWidth, panOffset, w);
        if (m2X >= -15 && m2X <= w + 15) {
          _drawMushroom(canvas, Offset(m2X, h * 0.56), isScarlet: true);
        }
      }
    }
  }

  void _drawMushroom(Canvas canvas, Offset base, {required bool isScarlet}) {
    // Mushroom stalk
    final stalkPaint = Paint()..color = isMoonlit ? const Color(0xFFD7CCC8) : const Color(0xFFFFF8E1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(base.dx, base.dy - 3), width: 3, height: 6), const Radius.circular(1.5)),
      stalkPaint,
    );

    // Mushroom cap
    final capPaint = Paint()
      ..color = isScarlet
          ? (isMoonlit ? const Color(0xFFC62828) : const Color(0xFFE53935))
          : (isMoonlit ? const Color(0xFF5D4037) : const Color(0xFF8D6E63));

    canvas.drawArc(
      Rect.fromCenter(center: Offset(base.dx, base.dy - 5.5), width: 8, height: 6),
      math.pi,
      math.pi,
      true,
      capPaint,
    );

    // White specks on scarlet caps
    if (isScarlet) {
      final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
      canvas.drawCircle(Offset(base.dx - 1.8, base.dy - 6.5), 0.6, dotPaint);
      canvas.drawCircle(Offset(base.dx + 1.2, base.dy - 7.0), 0.6, dotPaint);
      canvas.drawCircle(Offset(base.dx, base.dy - 5.5), 0.5, dotPaint);
    }
  }

  void _drawCloverCluster(Canvas canvas, Offset base) {
    final cloverPaint = Paint()..color = (isMoonlit ? const Color(0xFF2E6349) : const Color(0xFF689F38)).withValues(alpha: 0.8);
    // 3 small clover leaves
    canvas.drawCircle(Offset(base.dx - 2.5, base.dy - 2), 2.0, cloverPaint);
    canvas.drawCircle(Offset(base.dx + 2.5, base.dy - 2), 2.0, cloverPaint);
    canvas.drawCircle(Offset(base.dx, base.dy - 4.5), 2.0, cloverPaint);
  }

  void _drawFernCluster(Canvas canvas, Offset base, double sway, Paint paint) {
    // Left arching frond
    final f1 = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(base.dx - 12 + sway, base.dy - 12, base.dx - 22 + sway, base.dy - 16);
    canvas.drawPath(f1, paint);

    // Center tall frond
    final f2 = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(base.dx + sway * 0.5, base.dy - 16, base.dx - 2 + sway, base.dy - 24);
    canvas.drawPath(f2, paint);

    // Right arching frond
    final f3 = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(base.dx + 12 + sway, base.dy - 10, base.dx + 20 + sway, base.dy - 14);
    canvas.drawPath(f3, paint);
  }

  // ─── 7. Z-SORTED ENTITIES (Interactive Heroes) ───
  void _drawZSortedEntities(
    Canvas canvas,
    Size size,
    Offset center,
    double rx,
    double ry,
    int totalSectors,
    double panoramaWidth,
  ) {
    final entities = <IsometricEntity>[];

    for (final t in trees) {
      final isSel = t.id == selectedTreeId;
      final isActive = t.sessionId != null && t.sessionId == activeFocusSessionId;
      entities.add(TreeEntity(tree: t, isSelected: isSel, isActiveFocus: isActive));
    }

    for (final d in decorations) {
      entities.add(DecorationEntity(decoration: d));
    }

    if (wildlife != null) {
      for (final a in wildlife!) {
        if (a.type != WildlifeType.songbird && a.type != WildlifeType.koiFish) {
          entities.add(WildlifeEntity(animal: a));
        }
      }
    }

    // Sort ascending by depth (back to front)
    entities.sort((a, b) => a.depth.compareTo(b.depth));

    final windAngle = math.sin(windPhase * math.pi * 2) * 0.035;

    for (final entity in entities) {
      final screenPos = _getPanoramicEntityScreenPos(
        u: entity.u,
        v: entity.v,
        centerX: center.dx,
        centerY: center.dy,
        radiusX: rx,
        radiusY: ry,
        panoramaWidth: panoramaWidth,
        pan: panOffset,
        viewportWidth: size.width,
      );

      // Culling: If entity is off-screen, skip drawing to preserve 60/120 fps
      if (screenPos.dx < -120 || screenPos.dx > size.width + 120) {
        continue;
      }

      // Depth perspective scale: 0.82 (distant back) to 1.15 (near foreground)
      final depthFactor = (entity.u + entity.v) * 0.5;
      final depthScale = (0.82 + 0.30 * depthFactor).clamp(0.82, 1.16);

      // Density-adaptive scale factor: gently adjusts tree dimensions when glade reaches high population
      final treeCount = trees.length;
      final treesPerSector = treeCount / totalSectors;
      final densityFactor = treesPerSector > 25
          ? math.pow(25.0 / treesPerSector, 0.16).toDouble().clamp(0.75, 1.0)
          : 1.0;
      final effectiveDepthScale = depthScale * densityFactor;

      if (entity is TreeEntity) {
        _drawTreeEntity(canvas, entity, screenPos, windAngle, effectiveDepthScale);
      } else if (entity is DecorationEntity) {
        _drawDecorationEntity(canvas, entity, screenPos, effectiveDepthScale);
      } else if (entity is WildlifeEntity) {
        _drawWildlifeEntity(canvas, entity, screenPos, effectiveDepthScale);
      }
    }
  }

  // ─── TREE RENDERING ───
  void _drawTreeEntity(
    Canvas canvas,
    TreeEntity entity,
    Offset pos,
    double windAngle,
    double depthScale,
  ) {
    final tree = entity.tree;
    final stage = tree.stage;
    final species = tree.species;
    final isSelected = entity.isSelected;
    final isActiveFocus = entity.isActiveFocus;

    // Hitbox tracking scaled with depth perspective
    final hitCenter = Offset(pos.dx, pos.dy - 30 * depthScale);
    final hitRect = Rect.fromCenter(
      center: hitCenter,
      width: 76 * depthScale,
      height: 94 * depthScale,
    );
    treeHitBoxes?[tree.id] = hitRect;

    // Ground shadows:
    // 1. Ambient Occlusion core directly beneath trunk
    final shadowWidth = (34.0 + stage * 7.0) * depthScale;
    final shadowHeight = (14.0 + stage * 3.2) * depthScale;
    _ambientShadowPaint.color = Colors.black.withValues(alpha: isMoonlit ? 0.38 : 0.22);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy + 3), width: shadowWidth, height: shadowHeight),
      _ambientShadowPaint,
    );

    // 2. Directional soft cast shadow extending to bottom-left
    if (!isMoonlit) {
      _castShadowPaint.color = Colors.black.withValues(alpha: 0.12);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(pos.dx - 6 * depthScale, pos.dy + 7 * depthScale),
          width: shadowWidth * 1.15,
          height: shadowHeight * 0.9,
        ),
        _castShadowPaint,
      );
    }

    // Active focus glowing aura or selection halo
    if (isActiveFocus || isSelected) {
      final haloPaint = Paint()
        ..color = (isActiveFocus ? AppColors.safeGreen : species.themeColor).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawCircle(Offset(pos.dx, pos.dy - 35 * depthScale), 48 * depthScale, haloPaint);
    }

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(depthScale);
    canvas.rotate(windAngle);

    // Dual Rendering: High-Res Sprite when present, procedural botanical vector fallback otherwise
    final cachedSprite = TreeAssetService.instance.getCachedSprite(tree.assetPath);
    if (cachedSprite != null) {
      final targetHeight = 55.0 + stage * 16.0;
      TreeAssetService.instance.drawTreeSprite(
        canvas: canvas,
        image: cachedSprite,
        anchorPoint: Offset.zero,
        targetHeight: targetHeight,
      );
    } else {
      if (tree.isWithered) {
        _drawWitheredTreeIllustrated(canvas);
      } else {
        switch (stage) {
          case 1:
            _drawSeedIllustrated(canvas, species);
            break;
          case 2:
            _drawSproutIllustrated(canvas, species);
            break;
          case 3:
            _drawSaplingIllustrated(canvas, species);
            break;
          case 4:
            _drawYoungTreeIllustrated(canvas, species);
            break;
          case 5:
          default:
            _drawFullBloomIllustrated(canvas, species);
            break;
        }
      }
    }

    canvas.restore();

    // Active Focus Beacon or Selection Ring
    if (isActiveFocus) {
      _drawActiveBeacon(canvas, Offset(pos.dx, pos.dy - 82 * depthScale));
    } else if (isSelected) {
      _drawSelectionRing(canvas, Offset(pos.dx, pos.dy - 76 * depthScale), species.themeColor);
    }
  }

  // ─── BOTANICAL GROWTH STAGES ───

  // Stage 1: Seed & Earthen Mound
  void _drawSeedIllustrated(Canvas canvas, TreeSpecies species) {
    final moundPaint = Paint()
      ..color = isMoonlit ? const Color(0xFF2C221A) : const Color(0xFF5D4037);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 0), width: 26, height: 12), moundPaint);

    final seedPaint = Paint()..color = const Color(0xFFFFD166);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -7), width: 11, height: 13), seedPaint);

    final tipPaint = Paint()
      ..color = AppColors.safeGreen
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(0, -13), const Offset(2, -18), tipPaint);

    final glow = Paint()
      ..color = species.themeColor.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(const Offset(0, -9), 9, glow);
  }

  // Stage 2: Vibrant Botanical Sprout (~42px height)
  void _drawSproutIllustrated(Canvas canvas, TreeSpecies species) {
    final moundPaint = Paint()
      ..color = isMoonlit ? const Color(0xFF2C221A) : const Color(0xFF5D4037);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 0), width: 24, height: 10), moundPaint);

    final stemPaint = Paint()
      ..color = isMoonlit ? const Color(0xFF388E3C) : const Color(0xFF66BB6A)
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final stemPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(2, -14, -1, -26);
    canvas.drawPath(stemPath, stemPaint);

    final leafPaint = Paint()..color = species.themeColor;
    final leafHighlight = Paint()..color = const Color(0xFFE8F5E9).withValues(alpha: 0.9);

    final leftLeaf = Path()
      ..moveTo(-1, -24)
      ..cubicTo(-16, -22, -18, -34, -4, -35)
      ..close();
    canvas.drawPath(leftLeaf, leafPaint);
    canvas.drawCircle(const Offset(-9, -28), 2.5, leafHighlight);

    final rightLeaf = Path()
      ..moveTo(-1, -24)
      ..cubicTo(14, -26, 17, -38, 3, -39)
      ..close();
    canvas.drawPath(rightLeaf, leafPaint);
    canvas.drawCircle(const Offset(8, -32), 2.5, leafHighlight);
  }

  // Stage 3: Sapling (~65px height)
  void _drawSaplingIllustrated(Canvas canvas, TreeSpecies species) {
    final trunkPaint = Paint()
      ..color = isMoonlit ? const Color(0xFF3E2723) : const Color(0xFF5D4037)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(0, 0), const Offset(0, -32), trunkPaint);

    final shadowFoliage = Paint()..color = isMoonlit ? const Color(0xFF1B4030) : const Color(0xFF2D5A27);
    final mainFoliage = Paint()..color = species.themeColor;
    final lightFoliage = Paint()..color = species.themeColor.withValues(alpha: 0.85);

    canvas.drawCircle(const Offset(0, -42), 18, shadowFoliage);
    canvas.drawCircle(const Offset(-13, -36), 14, mainFoliage);
    canvas.drawCircle(const Offset(13, -35), 14, mainFoliage);
    canvas.drawCircle(const Offset(0, -52), 15, lightFoliage);
  }

  // Stage 4: Young Tree (~90px height)
  void _drawYoungTreeIllustrated(Canvas canvas, TreeSpecies species) {
    final trunkPaint = Paint()
      ..color = isMoonlit ? const Color(0xFF38261F) : const Color(0xFF4E342E);
    final trunkPath = Path()
      ..moveTo(-7, 0)
      ..lineTo(7, 0)
      ..lineTo(3, -28)
      ..lineTo(14, -44)
      ..lineTo(9, -46)
      ..lineTo(1, -30)
      ..lineTo(-10, -46)
      ..lineTo(-14, -43)
      ..lineTo(-3, -28)
      ..close();
    canvas.drawPath(trunkPath, trunkPaint);

    final darkLobe = Paint()..color = isMoonlit ? const Color(0xFF153828) : const Color(0xFF234B22);
    final mainLobe = Paint()..color = species.themeColor;
    final highlightLobe = Paint()..color = species.themeColor.withValues(alpha: 0.85);

    canvas.drawCircle(const Offset(0, -50), 25, darkLobe);
    canvas.drawCircle(const Offset(-20, -42), 18, mainLobe);
    canvas.drawCircle(const Offset(20, -40), 18, mainLobe);
    canvas.drawCircle(const Offset(-11, -62), 16, highlightLobe);
    canvas.drawCircle(const Offset(11, -61), 16, highlightLobe);
    canvas.drawCircle(const Offset(0, -72), 18, highlightLobe);
  }

  // Stage 5: Full Bloom (Species-Specific Botanical Artwork)
  void _drawFullBloomIllustrated(Canvas canvas, TreeSpecies species) {
    final trunkColor = isMoonlit ? const Color(0xFF32231A) : const Color(0xFF4A3528);

    switch (species) {
      case TreeSpecies.ancientOak:
        _drawOakIllustrated(canvas, trunkColor);
        break;
      case TreeSpecies.mountainPine:
        _drawPineIllustrated(canvas, trunkColor);
        break;
      case TreeSpecies.cherryBlossom:
        _drawCherryBlossomIllustrated(canvas, trunkColor);
        break;
      case TreeSpecies.riverWillow:
        _drawWillowIllustrated(canvas, trunkColor);
        break;
      case TreeSpecies.goldenGinkgo:
        _drawGinkgoIllustrated(canvas, trunkColor);
        break;
      case TreeSpecies.bonsaiJuniper:
        _drawBonsaiIllustrated(canvas, trunkColor);
        break;
      case TreeSpecies.japaneseCedar:
        _drawCedarIllustrated(canvas, trunkColor);
        break;
      case TreeSpecies.jacaranda:
        _drawJacarandaIllustrated(canvas, trunkColor);
        break;
      case TreeSpecies.bambooGrove:
        _drawBambooIllustrated(canvas, trunkColor);
        break;
      case TreeSpecies.giantSequoia:
        _drawSequoiaIllustrated(canvas, trunkColor);
        break;
      case TreeSpecies.sacredBanyan:
        _drawBanyanIllustrated(canvas, trunkColor);
        break;
      case TreeSpecies.silverBirch:
        _drawSilverBirchIllustrated(canvas, trunkColor);
        break;
      case TreeSpecies.flameOfForest:
        _drawFlameIllustrated(canvas, trunkColor);
        break;
      case TreeSpecies.weepingWisteria:
        _drawWisteriaIllustrated(canvas, trunkColor);
        break;
      case TreeSpecies.ancientBaobab:
        _drawBaobabIllustrated(canvas, trunkColor);
        break;
    }
  }

  // Ancient Oak
  void _drawOakIllustrated(Canvas canvas, Color trunkColor) {
    final trunkPaint = Paint()..color = trunkColor;
    final trunk = Path()
      ..moveTo(-11, 0)
      ..lineTo(11, 0)
      ..lineTo(7, -28)
      ..lineTo(24, -46)
      ..lineTo(19, -50)
      ..lineTo(2, -32)
      ..lineTo(-20, -50)
      ..lineTo(-25, -46)
      ..lineTo(-7, -28)
      ..close();
    canvas.drawPath(trunk, trunkPaint);

    final darkLobe = Paint()..color = isMoonlit ? const Color(0xFF143527) : const Color(0xFF285430);
    final midLobe = Paint()..color = isMoonlit ? const Color(0xFF1B4D39) : const Color(0xFF38761D);
    final sunLobe = Paint()..color = isMoonlit ? const Color(0xFF286E53) : const Color(0xFF5F9E38);

    canvas.drawCircle(const Offset(0, -56), 33, darkLobe);
    canvas.drawCircle(const Offset(-28, -48), 24, midLobe);
    canvas.drawCircle(const Offset(28, -46), 24, midLobe);
    canvas.drawCircle(const Offset(-18, -72), 22, sunLobe);
    canvas.drawCircle(const Offset(18, -70), 22, sunLobe);
    canvas.drawCircle(const Offset(0, -84), 26, sunLobe);
  }

  // Mountain Pine
  void _drawPineIllustrated(Canvas canvas, Color trunkColor) {
    final trunkPaint = Paint()..color = trunkColor;
    canvas.drawRect(const Rect.fromLTWH(-4.5, -55, 9, 55), trunkPaint);

    final pineDark = Paint()..color = isMoonlit ? const Color(0xFF113328) : const Color(0xFF1E4D2B);
    final pineMid = Paint()..color = isMoonlit ? const Color(0xFF184738) : const Color(0xFF2D6A3E);
    final pineLight = Paint()..color = isMoonlit ? const Color(0xFF205E4A) : const Color(0xFF40916C);

    _drawPineTier(canvas, -24, 38, 22, pineDark);
    _drawPineTier(canvas, -42, 32, 20, pineMid);
    _drawPineTier(canvas, -58, 25, 18, pineMid);
    _drawPineTier(canvas, -74, 17, 16, pineLight);
  }

  // Cherry Blossom
  void _drawCherryBlossomIllustrated(Canvas canvas, Color trunkColor) {
    final trunkPaint = Paint()..color = trunkColor;
    final trunk = Path()
      ..moveTo(-8, 0)
      ..lineTo(8, 0)
      ..lineTo(4, -26)
      ..lineTo(18, -46)
      ..lineTo(13, -50)
      ..lineTo(2, -30)
      ..lineTo(-16, -50)
      ..lineTo(-20, -46)
      ..lineTo(-3, -26)
      ..close();
    canvas.drawPath(trunk, trunkPaint);

    final pinkDark = Paint()..color = const Color(0xFFE57373);
    final pinkMid = Paint()..color = AppColors.cherryPink;
    final pinkLight = Paint()..color = const Color(0xFFFFCDD2);

    canvas.drawCircle(const Offset(0, -54), 29, pinkDark);
    canvas.drawCircle(const Offset(-24, -46), 22, pinkMid);
    canvas.drawCircle(const Offset(24, -44), 22, pinkMid);
    canvas.drawCircle(const Offset(-14, -70), 20, pinkLight);
    canvas.drawCircle(const Offset(14, -69), 20, pinkLight);
    canvas.drawCircle(const Offset(0, -82), 22, pinkLight);
  }

  // River Willow
  void _drawWillowIllustrated(Canvas canvas, Color trunkColor) {
    final trunkPaint = Paint()..color = trunkColor;
    canvas.drawLine(const Offset(0, 0), const Offset(0, -40), trunkPaint..strokeWidth = 7.0);

    final dome = Paint()..color = isMoonlit ? const Color(0xFF1B4A38) : const Color(0xFF2E7D32);
    canvas.drawCircle(const Offset(0, -52), 29, dome);

    final frondPaint = Paint()
      ..color = isMoonlit ? const Color(0xFF2C6D54) : const Color(0xFF81C784)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final sway = math.sin(windPhase * math.pi * 2) * 3.5;
    canvas.drawLine(const Offset(-20, -46), Offset(-27 + sway, -12), frondPaint);
    canvas.drawLine(const Offset(-10, -44), Offset(-14 + sway, -4), frondPaint);
    canvas.drawLine(const Offset(10, -44), Offset(14 + sway, -4), frondPaint);
    canvas.drawLine(const Offset(20, -46), Offset(27 + sway, -12), frondPaint);
  }

  // Golden Ginkgo
  void _drawGinkgoIllustrated(Canvas canvas, Color trunkColor) {
    final trunkPaint = Paint()..color = trunkColor;
    canvas.drawLine(const Offset(0, 0), const Offset(0, -44), trunkPaint..strokeWidth = 6.5);

    final goldDark = Paint()..color = const Color(0xFFE65100);
    final goldMid = Paint()..color = AppColors.amberWarm;
    final goldLight = Paint()..color = const Color(0xFFFFD54F);

    canvas.drawCircle(const Offset(0, -56), 27, goldDark);
    canvas.drawCircle(const Offset(-22, -46), 20, goldMid);
    canvas.drawCircle(const Offset(22, -44), 20, goldMid);
    canvas.drawCircle(const Offset(-11, -72), 18, goldLight);
    canvas.drawCircle(const Offset(11, -71), 18, goldLight);
    canvas.drawCircle(const Offset(0, -82), 20, goldLight);
  }

  // Bonsai Juniper
  void _drawBonsaiIllustrated(Canvas canvas, Color trunkColor) {
    final trunkPaint = Paint()
      ..color = trunkColor
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final trunk = Path()
      ..moveTo(-5, 0)
      ..cubicTo(16, -18, -18, -34, 4, -50);
    canvas.drawPath(trunk, trunkPaint);

    final cloudDark = Paint()..color = isMoonlit ? const Color(0xFF143026) : const Color(0xFF1B4332);
    final cloudLight = Paint()..color = isMoonlit ? const Color(0xFF265A46) : const Color(0xFF40916C);

    canvas.drawOval(Rect.fromCenter(center: const Offset(20, -22), width: 32, height: 14), cloudDark);
    canvas.drawOval(Rect.fromCenter(center: const Offset(-22, -38), width: 34, height: 15), cloudDark);
    canvas.drawOval(Rect.fromCenter(center: const Offset(12, -56), width: 38, height: 16), cloudLight);
  }

  // Japanese Cedar (Cryptomeria japonica)
  void _drawCedarIllustrated(Canvas canvas, Color trunkColor) {
    final trunkPaint = Paint()..color = trunkColor;
    canvas.drawRect(const Rect.fromLTWH(-5, -68, 10, 68), trunkPaint);

    final cedarDark = Paint()..color = isMoonlit ? const Color(0xFF0F3B20) : const Color(0xFF1B5E20);
    final cedarMid = Paint()..color = isMoonlit ? const Color(0xFF1B522E) : const Color(0xFF2E7D32);
    final cedarLight = Paint()..color = isMoonlit ? const Color(0xFF24683C) : const Color(0xFF388E3C);

    _drawPineTier(canvas, -22, 42, 24, cedarDark);
    _drawPineTier(canvas, -40, 36, 22, cedarMid);
    _drawPineTier(canvas, -56, 30, 20, cedarMid);
    _drawPineTier(canvas, -70, 22, 18, cedarLight);
    _drawPineTier(canvas, -84, 14, 16, cedarLight);
  }

  // Jacaranda (Jacaranda mimosifolia)
  void _drawJacarandaIllustrated(Canvas canvas, Color trunkColor) {
    final trunkPaint = Paint()..color = trunkColor;
    final trunk = Path()
      ..moveTo(-8, 0)
      ..lineTo(8, 0)
      ..lineTo(5, -26)
      ..lineTo(20, -44)
      ..lineTo(15, -48)
      ..lineTo(2, -30)
      ..lineTo(-18, -48)
      ..lineTo(-22, -44)
      ..lineTo(-4, -26)
      ..close();
    canvas.drawPath(trunk, trunkPaint);

    final purpleDeep = Paint()..color = const Color(0xFF5E35B1);
    final purpleMain = Paint()..color = const Color(0xFF7E57C2);
    final lavenderLight = Paint()..color = const Color(0xFFB39DDB);

    canvas.drawCircle(const Offset(0, -56), 30, purpleDeep);
    canvas.drawCircle(const Offset(-26, -46), 22, purpleMain);
    canvas.drawCircle(const Offset(26, -44), 22, purpleMain);
    canvas.drawCircle(const Offset(-14, -72), 20, lavenderLight);
    canvas.drawCircle(const Offset(14, -71), 20, lavenderLight);
    canvas.drawCircle(const Offset(0, -84), 22, lavenderLight);

    // Drifting violet blossom speckles
    final petalPaint = Paint()..color = const Color(0xFFD1C4E9);
    canvas.drawCircle(const Offset(-18, -12), 2.0, petalPaint);
    canvas.drawCircle(const Offset(22, -16), 1.8, petalPaint);
    canvas.drawCircle(const Offset(6, -4), 1.6, petalPaint);
  }

  // Bamboo Grove (Phyllostachys edulis)
  void _drawBambooIllustrated(Canvas canvas, Color trunkColor) {
    final stalkDark = Paint()..color = isMoonlit ? const Color(0xFF1B4D2B) : const Color(0xFF2E7D32);
    final stalkLight = Paint()..color = isMoonlit ? const Color(0xFF2D6A3E) : const Color(0xFF43A047);
    final nodePaint = Paint()
      ..color = isMoonlit ? const Color(0xFF40916C) : const Color(0xFF81C784)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final leafPaint = Paint()..color = isMoonlit ? const Color(0xFF387A5B) : const Color(0xFF66BB6A);
    final sway = math.sin(windPhase * math.pi * 2) * 2.8;

    // Culm 1 (Left)
    canvas.drawLine(const Offset(-12, 0), Offset(-12 + sway * 0.4, -60), stalkLight..strokeWidth = 4.5);
    canvas.drawLine(Offset(-14 + sway * 0.1, -20), Offset(-10 + sway * 0.1, -20), nodePaint);
    canvas.drawLine(Offset(-14 + sway * 0.25, -40), Offset(-10 + sway * 0.25, -40), nodePaint);

    // Culm 2 (Center)
    canvas.drawLine(const Offset(0, 0), Offset(0 + sway * 0.7, -74), stalkDark..strokeWidth = 5.0);
    canvas.drawLine(Offset(-2 + sway * 0.2, -24), Offset(2 + sway * 0.2, -24), nodePaint);
    canvas.drawLine(Offset(-2 + sway * 0.45, -48), Offset(2 + sway * 0.45, -48), nodePaint);

    // Culm 3 (Right)
    canvas.drawLine(const Offset(11, 0), Offset(11 + sway * 0.5, -66), stalkLight..strokeWidth = 4.0);
    canvas.drawLine(Offset(9 + sway * 0.15, -22), Offset(13 + sway * 0.15, -22), nodePaint);
    canvas.drawLine(Offset(9 + sway * 0.35, -44), Offset(13 + sway * 0.35, -44), nodePaint);

    // Lanceolate bamboo culm leaves fluttering at crown
    _drawBambooLeaves(canvas, Offset(-12 + sway * 0.4, -60), sway, leafPaint);
    _drawBambooLeaves(canvas, Offset(sway * 0.7, -74), sway, leafPaint);
    _drawBambooLeaves(canvas, Offset(11 + sway * 0.5, -66), sway, leafPaint);
  }

  void _drawBambooLeaves(Canvas canvas, Offset apex, double sway, Paint paint) {
    final leaf = Path()
      ..moveTo(apex.dx, apex.dy)
      ..quadraticBezierTo(apex.dx - 10 + sway, apex.dy - 6, apex.dx - 18 + sway, apex.dy - 3)
      ..moveTo(apex.dx, apex.dy)
      ..quadraticBezierTo(apex.dx + 12 + sway, apex.dy - 8, apex.dx + 20 + sway, apex.dy - 4)
      ..moveTo(apex.dx, apex.dy)
      ..quadraticBezierTo(apex.dx - 6 + sway, apex.dy - 12, apex.dx - 8 + sway, apex.dy - 18);
    canvas.drawPath(leaf, paint..strokeWidth = 2.4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }

  void _drawPineTier(Canvas canvas, double topY, double width, double height, Paint paint) {
    final path = Path()
      ..moveTo(0, topY)
      ..lineTo(width / 2, topY + height)
      ..lineTo(-width / 2, topY + height)
      ..close();
    canvas.drawPath(path, paint);
  }

  // Giant Sequoia (Ancient cinnamon titan soaring high)
  void _drawSequoiaIllustrated(Canvas canvas, Color trunkColor) {
    final cinnamonBark = Paint()
      ..color = isMoonlit ? const Color(0xFF5D2810) : const Color(0xFF8D4004);
    final buttress = Path()
      ..moveTo(-13, 0)
      ..lineTo(13, 0)
      ..lineTo(7, -35)
      ..lineTo(4, -85)
      ..lineTo(-4, -85)
      ..lineTo(-7, -35)
      ..close();
    canvas.drawPath(buttress, cinnamonBark);

    // Root buttress flares at ground line
    final flarePaint = Paint()
      ..color = isMoonlit ? const Color(0xFF421D0A) : const Color(0xFF6E2D03)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-13, 0), const Offset(-7, -18), flarePaint);
    canvas.drawLine(const Offset(13, 0), const Offset(7, -18), flarePaint);

    final sequoiaDark = Paint()..color = isMoonlit ? const Color(0xFF0F3622) : const Color(0xFF1B4332);
    final sequoiaMid = Paint()..color = isMoonlit ? const Color(0xFF184E34) : const Color(0xFF2D6A4F);
    final sequoiaLight = Paint()..color = isMoonlit ? const Color(0xFF246B48) : const Color(0xFF40916C);

    _drawPineTier(canvas, -32, 46, 26, sequoiaDark);
    _drawPineTier(canvas, -52, 40, 24, sequoiaMid);
    _drawPineTier(canvas, -70, 32, 22, sequoiaMid);
    _drawPineTier(canvas, -86, 22, 20, sequoiaLight);
    _drawPineTier(canvas, -98, 12, 16, sequoiaLight);
  }

  // Sacred Banyan (Immense spreading canopy with prop root pillars)
  void _drawBanyanIllustrated(Canvas canvas, Color trunkColor) {
    final banyanBark = Paint()
      ..color = isMoonlit ? const Color(0xFF2D201A) : const Color(0xFF4E342E);
    final propRootPaint = Paint()
      ..color = isMoonlit ? const Color(0xFF382720) : const Color(0xFF5D4037)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    // Sprawling central trunk
    final trunk = Path()
      ..moveTo(-12, 0)
      ..lineTo(12, 0)
      ..lineTo(8, -26)
      ..lineTo(32, -40)
      ..lineTo(28, -44)
      ..lineTo(2, -30)
      ..lineTo(-28, -44)
      ..lineTo(-32, -40)
      ..lineTo(-8, -26)
      ..close();
    canvas.drawPath(trunk, banyanBark);

    // Iconic descending aerial prop roots anchored into forest earth
    canvas.drawLine(const Offset(-26, -18), const Offset(-26, 0), propRootPaint);
    canvas.drawLine(const Offset(-14, -24), const Offset(-14, 0), propRootPaint);
    canvas.drawLine(const Offset(15, -22), const Offset(15, 0), propRootPaint);
    canvas.drawLine(const Offset(27, -16), const Offset(27, 0), propRootPaint);

    final darkLobe = Paint()..color = isMoonlit ? const Color(0xFF133827) : const Color(0xFF1B5E20);
    final midLobe = Paint()..color = isMoonlit ? const Color(0xFF1C5239) : const Color(0xFF2E7D32);
    final sunLobe = Paint()..color = isMoonlit ? const Color(0xFF2A7252) : const Color(0xFF4CAF50);

    // Vast horizontal crown spread
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -48), width: 72, height: 38), darkLobe);
    canvas.drawCircle(const Offset(-32, -42), 22, midLobe);
    canvas.drawCircle(const Offset(32, -40), 22, midLobe);
    canvas.drawCircle(const Offset(-18, -60), 20, sunLobe);
    canvas.drawCircle(const Offset(18, -58), 20, sunLobe);
    canvas.drawCircle(const Offset(0, -66), 24, sunLobe);
  }

  // Silver Birch (Chalk-white bark with lenticels and fluttering lime leaves)
  void _drawSilverBirchIllustrated(Canvas canvas, Color trunkColor) {
    final chalkBark = Paint()..color = isMoonlit ? const Color(0xFFCFD8DC) : const Color(0xFFECEFF1);
    final lenticelPaint = Paint()
      ..color = const Color(0xFF263238)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    // Slender white trunk
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-3.5, -60, 7, 60), const Radius.circular(3)),
      chalkBark,
    );
    // Distinctive black horizontal bark stripes
    canvas.drawLine(const Offset(-3.5, -12), const Offset(1, -12), lenticelPaint);
    canvas.drawLine(const Offset(-1, -24), const Offset(3.5, -24), lenticelPaint);
    canvas.drawLine(const Offset(-3.5, -36), const Offset(2, -36), lenticelPaint);
    canvas.drawLine(const Offset(-2, -48), const Offset(3.5, -48), lenticelPaint);

    final birchMid = Paint()..color = isMoonlit ? const Color(0xFF2E5830) : const Color(0xFF7CB342);
    final birchLight = Paint()..color = isMoonlit ? const Color(0xFF437A46) : const Color(0xFF9CCC65);

    // Airy shimmering canopy
    canvas.drawCircle(const Offset(-15, -46), 17, birchMid);
    canvas.drawCircle(const Offset(15, -44), 17, birchMid);
    canvas.drawCircle(const Offset(-9, -64), 16, birchLight);
    canvas.drawCircle(const Offset(9, -62), 16, birchLight);
    canvas.drawCircle(const Offset(0, -74), 18, birchLight);
  }

  // Flame of the Forest / Palash (Fiery scarlet-orange springtime blooms)
  void _drawFlameIllustrated(Canvas canvas, Color trunkColor) {
    final charcoalBark = Paint()..color = isMoonlit ? const Color(0xFF1E272C) : const Color(0xFF37474F);
    final trunk = Path()
      ..moveTo(-7, 0)
      ..lineTo(7, 0)
      ..lineTo(4, -26)
      ..lineTo(16, -44)
      ..lineTo(11, -47)
      ..lineTo(1, -29)
      ..lineTo(-15, -47)
      ..lineTo(-18, -44)
      ..lineTo(-3, -26)
      ..close();
    canvas.drawPath(trunk, charcoalBark);

    final crimsonBase = Paint()..color = isMoonlit ? const Color(0xFF881B1B) : const Color(0xFFD32F2F);
    final vermilionMid = Paint()..color = isMoonlit ? const Color(0xFFBF360C) : const Color(0xFFFF5722);
    final flameGold = Paint()..color = isMoonlit ? const Color(0xFFE65100) : const Color(0xFFFF9800);

    canvas.drawCircle(const Offset(0, -50), 28, crimsonBase);
    canvas.drawCircle(const Offset(-22, -44), 20, vermilionMid);
    canvas.drawCircle(const Offset(22, -42), 20, vermilionMid);
    canvas.drawCircle(const Offset(-12, -64), 18, flameGold);
    canvas.drawCircle(const Offset(12, -63), 18, flameGold);
    canvas.drawCircle(const Offset(0, -74), 20, flameGold);
  }

  // Weeping Wisteria (Cascading pendulous violet-lilac racemes)
  void _drawWisteriaIllustrated(Canvas canvas, Color trunkColor) {
    final vineBark = Paint()..color = isMoonlit ? const Color(0xFF2E241E) : const Color(0xFF4E342E);
    canvas.drawRect(const Rect.fromLTWH(-4.5, -46, 9, 46), vineBark);

    final darkViolet = Paint()..color = isMoonlit ? const Color(0xFF4A148C) : const Color(0xFF6A1B9A);
    final royalLilac = Paint()..color = isMoonlit ? const Color(0xFF7B1FA2) : const Color(0xFF9C27B0);
    final paleBlossom = Paint()..color = isMoonlit ? const Color(0xFFBA68C8) : const Color(0xFFCE93D8);

    // Central crown arch
    canvas.drawCircle(const Offset(0, -56), 26, darkViolet);
    canvas.drawCircle(const Offset(-18, -50), 20, royalLilac);
    canvas.drawCircle(const Offset(18, -48), 20, royalLilac);

    final sway = math.sin(windPhase * math.pi * 2) * 2.2;
    // Cascading pendulous blossom racemes
    _drawWisteriaRaceme(canvas, Offset(-24 + sway * 0.4, -38), 26, paleBlossom);
    _drawWisteriaRaceme(canvas, Offset(-12 + sway * 0.7, -34), 32, royalLilac);
    _drawWisteriaRaceme(canvas, Offset(0 + sway, -32), 34, paleBlossom);
    _drawWisteriaRaceme(canvas, Offset(12 + sway * 0.7, -34), 30, royalLilac);
    _drawWisteriaRaceme(canvas, Offset(24 + sway * 0.4, -38), 24, paleBlossom);
  }

  void _drawWisteriaRaceme(Canvas canvas, Offset top, double length, Paint paint) {
    final path = Path()
      ..moveTo(top.dx - 4, top.dy)
      ..lineTo(top.dx + 4, top.dy)
      ..lineTo(top.dx + 2, top.dy + length * 0.7)
      ..lineTo(top.dx, top.dy + length)
      ..lineTo(top.dx - 2, top.dy + length * 0.7)
      ..close();
    canvas.drawPath(path, paint);
  }

  // Ancient Baobab (Massive swollen bottle trunk crowned with succulent tufts)
  void _drawBaobabIllustrated(Canvas canvas, Color trunkColor) {
    final baobabBark = Paint()..color = isMoonlit ? const Color(0xFF3E2D27) : const Color(0xFF6D4C41);
    final crownFoliage = Paint()..color = isMoonlit ? const Color(0xFF1E482A) : const Color(0xFF388E3C);
    final sunFoliage = Paint()..color = isMoonlit ? const Color(0xFF2E633D) : const Color(0xFF66BB6A);

    // Mammoth swollen bottle trunk
    final bottleTrunk = Path()
      ..moveTo(-18, 0)
      ..lineTo(18, 0)
      ..quadraticBezierTo(22, -24, 15, -46)
      ..lineTo(22, -62)
      ..lineTo(17, -64)
      ..lineTo(7, -50)
      ..lineTo(0, -68)
      ..lineTo(-7, -50)
      ..lineTo(-17, -64)
      ..lineTo(-22, -62)
      ..lineTo(-15, -46)
      ..quadraticBezierTo(-22, -24, -18, 0)
      ..close();
    canvas.drawPath(bottleTrunk, baobabBark);

    // Compact starry crowns atop root-like branches
    canvas.drawCircle(const Offset(-19, -64), 13, crownFoliage);
    canvas.drawCircle(const Offset(0, -70), 15, sunFoliage);
    canvas.drawCircle(const Offset(19, -64), 13, crownFoliage);
    canvas.drawCircle(const Offset(-8, -56), 11, sunFoliage);
    canvas.drawCircle(const Offset(8, -56), 11, sunFoliage);
  }

  // Withered Tree
  void _drawWitheredTreeIllustrated(Canvas canvas) {
    final soilPaint = Paint()
      ..color = isMoonlit ? const Color(0xFF221A15) : const Color(0xFF5D4037).withValues(alpha: 0.7);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 0), width: 32, height: 14), soilPaint);

    final barkPaint = Paint()
      ..color = isMoonlit ? const Color(0xFF261C18) : const Color(0xFF3E2723)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final trunkPath = Path()
      ..moveTo(0, 0)
      ..lineTo(-3, -18)
      ..lineTo(4, -36)
      ..lineTo(1, -54);
    canvas.drawPath(trunkPath, barkPaint);

    final branchPaint = Paint()
      ..color = isMoonlit ? const Color(0xFF261C18) : const Color(0xFF3E2723)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final limbL = Path()
      ..moveTo(0, -30)
      ..lineTo(-16, -42)
      ..lineTo(-24, -58);
    canvas.drawPath(limbL, branchPaint);

    final twigL = Path()
      ..moveTo(-12, -38)
      ..lineTo(-15, -52);
    canvas.drawPath(twigL, branchPaint..strokeWidth = 1.8);

    final limbR = Path()
      ..moveTo(3, -36)
      ..lineTo(18, -48)
      ..lineTo(25, -64);
    canvas.drawPath(limbR, branchPaint..strokeWidth = 2.6);

    final twigR = Path()
      ..moveTo(14, -42)
      ..lineTo(18, -34);
    canvas.drawPath(twigR, branchPaint..strokeWidth = 1.8);

    final topSpike = Path()
      ..moveTo(1, -50)
      ..lineTo(-4, -66);
    canvas.drawPath(topSpike, branchPaint..strokeWidth = 2.0);

    final deadLeafPaint = Paint()..color = const Color(0xFF8D6E63);
    canvas.drawCircle(const Offset(-9, 3), 2.4, deadLeafPaint);
    canvas.drawCircle(const Offset(10, 2), 2.2, deadLeafPaint);
    canvas.drawCircle(const Offset(4, 5), 2.0, deadLeafPaint);
  }

  // Active Focus Beacon & Selection Ring
  void _drawActiveBeacon(Canvas canvas, Offset pos) {
    final haloPaint = Paint()
      ..color = AppColors.safeGreen.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(pos, 16, haloPaint);

    final bgPaint = Paint()..color = AppColors.deepForest;
    canvas.drawCircle(pos, 11, bgPaint);

    final iconPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(pos, 5, iconPaint);
  }

  void _drawSelectionRing(Canvas canvas, Offset pos, Color color) {
    final ringPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(pos, 12, ringPaint);
  }

  // ─── 8. FOREGROUND VIGNETTE & BOTANICAL FRONDS ───
  void _drawForegroundBotanicals(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _frondForegroundPaint.color = (isMoonlit ? const Color(0xFF0E241B) : const Color(0xFF2E5A27))
        .withValues(alpha: isMoonlit ? 0.70 : 0.85);

    // Bottom-left broadleaf fern framing camera view
    final blPath = Path()
      ..moveTo(0, h)
      ..quadraticBezierTo(w * 0.10, h * 0.88, w * 0.18, h * 0.90)
      ..quadraticBezierTo(w * 0.10, h * 0.96, 0, h)
      ..close();
    canvas.drawPath(blPath, _frondForegroundPaint);

    // Bottom-right broadleaf frond
    final brPath = Path()
      ..moveTo(w, h)
      ..quadraticBezierTo(w * 0.90, h * 0.86, w * 0.82, h * 0.89)
      ..quadraticBezierTo(w * 0.90, h * 0.95, w, h)
      ..close();
    canvas.drawPath(brPath, _frondForegroundPaint);
  }

  // ─── 9. ENVIRONMENTAL PARTICLES: WIND GUSTS & SWIRLING LEAVES ───
  static const List<_LeafParticleSeed> _leafSeeds = [
    _LeafParticleSeed(0.04, 0.18, 1.15, 2.8, 14.0, 3.2, 7.5, 0), // Oak leaf
    _LeafParticleSeed(0.12, 0.42, 1.40, 3.5, 18.0, 4.5, 6.0, 3), // Sakura petal
    _LeafParticleSeed(0.22, 0.28, 0.95, 2.2, 12.0, 2.8, 8.5, 1), // Ginkgo leaf
    _LeafParticleSeed(0.31, 0.55, 1.25, 4.0, 16.0, 5.0, 6.5, 2), // Birch leaf
    _LeafParticleSeed(0.39, 0.22, 1.50, 3.2, 20.0, 3.8, 5.5, 3), // Sakura petal
    _LeafParticleSeed(0.48, 0.62, 1.05, 2.6, 15.0, 3.0, 8.0, 4), // Maple leaf
    _LeafParticleSeed(0.56, 0.35, 1.35, 3.8, 17.0, 4.2, 7.0, 0), // Oak leaf
    _LeafParticleSeed(0.65, 0.48, 1.10, 2.4, 13.0, 3.5, 8.5, 1), // Ginkgo leaf
    _LeafParticleSeed(0.73, 0.25, 1.45, 3.6, 19.0, 4.8, 6.0, 3), // Sakura petal
    _LeafParticleSeed(0.82, 0.58, 1.20, 3.0, 15.0, 3.4, 6.5, 2), // Birch leaf
    _LeafParticleSeed(0.91, 0.32, 1.30, 3.4, 16.0, 4.0, 7.5, 0), // Oak leaf
    _LeafParticleSeed(0.18, 0.68, 1.15, 2.5, 14.0, 3.2, 8.0, 4), // Maple leaf
    _LeafParticleSeed(0.27, 0.15, 1.60, 4.2, 22.0, 5.5, 5.0, 3), // Sakura petal
    _LeafParticleSeed(0.44, 0.45, 0.90, 2.0, 11.0, 2.6, 9.0, 1), // Ginkgo leaf
    _LeafParticleSeed(0.61, 0.65, 1.25, 3.2, 16.0, 3.8, 6.5, 2), // Birch leaf
    _LeafParticleSeed(0.79, 0.38, 1.40, 3.9, 18.0, 4.4, 7.0, 0), // Oak leaf
    _LeafParticleSeed(0.87, 0.72, 1.05, 2.7, 13.0, 3.1, 7.5, 4), // Maple leaf
    _LeafParticleSeed(0.08, 0.52, 1.35, 3.5, 17.0, 4.6, 5.5, 3), // Sakura petal
    _LeafParticleSeed(0.52, 0.20, 1.55, 4.0, 21.0, 5.2, 6.0, 3), // Sakura petal
    _LeafParticleSeed(0.96, 0.46, 1.15, 2.8, 14.0, 3.3, 8.5, 1), // Ginkgo leaf
  ];

  void _drawEnvironmentalParticles(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Ambient Dynamic Wind Gust Trails (sweeping translucent curves across the canopy)
    final gustSpeed = 1.0 + windGust.abs() * 0.8;
    for (int g = 0; g < 3; g++) {
      final gProgress = ((windPhase * 1.8 * gustSpeed) + g * 0.34) % 1.0;
      final gY = h * (0.22 + g * 0.20);
      final gStartX = -w * 0.20 + gProgress * (w * 1.4);
      final gAlpha = math.sin(gProgress * math.pi) * (isMoonlit ? 0.24 : 0.18);

      if (gAlpha > 0.02) {
        _windTrailPaint
          ..color = (isMoonlit ? const Color(0xFF80DEEA) : Colors.white).withValues(alpha: gAlpha)
          ..strokeWidth = 1.6 + g * 0.5;

        final gPath = Path()
          ..moveTo(gStartX, gY)
          ..quadraticBezierTo(gStartX + w * 0.18, gY - 14 + math.sin(windPhase * 3) * 6, gStartX + w * 0.36, gY + 4);
        canvas.drawPath(gPath, _windTrailPaint);
      }
    }

    // 2. Swirling Forest Leaves & Sakura Petals
    final leafGreen = isMoonlit ? const Color(0xFF2E7D32) : const Color(0xFF43A047);
    final ginkgoGold = isMoonlit ? const Color(0xFFFFB300) : const Color(0xFFFFC107);
    final birchLime = isMoonlit ? const Color(0xFF689F38) : const Color(0xFF8BC34A);
    final sakuraPink = isMoonlit ? const Color(0xFFF48FB1) : const Color(0xFFFF80AB);
    final mapleCoral = isMoonlit ? const Color(0xFFD84315) : const Color(0xFFFF5722);

    for (int i = 0; i < _leafSeeds.length; i++) {
      final seed = _leafSeeds[i];
      final pT = ((windPhase * seed.speed * gustSpeed) + seed.u) % 1.0;
      final px = pT * w;
      final py = (h * seed.v + (pT * h * 0.32) + math.sin(pT * math.pi * seed.swayFreq + i) * seed.swayAmp) % (h * 0.88);

      final driftAngle = 0.25 + math.sin(pT * math.pi * 2.5 + seed.leafType) * 0.35;
      final tumble = math.cos(pT * math.pi * seed.tumbleSpeed + seed.u * 10);
      final s = seed.size * 0.85;

      Color color;
      switch (seed.leafType) {
        case 0:
          color = leafGreen;
          break;
        case 1:
          color = ginkgoGold;
          break;
        case 2:
          color = birchLime;
          break;
        case 3:
          color = sakuraPink;
          break;
        case 4:
        default:
          color = mapleCoral;
          break;
      }

      _leafPaint.color = color.withValues(alpha: isMoonlit ? 0.72 : 0.84);
      _leafVeinPaint.color = Colors.white.withValues(alpha: 0.45);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(driftAngle);
      canvas.scale(tumble.abs().clamp(0.15, 1.0), 1.0); // 3D flip effect in the air!

      if (seed.leafType == 1) {
        // Ginkgo fan leaf
        final gPath = Path()
          ..moveTo(0, s * 0.5)
          ..quadraticBezierTo(-s * 0.6, -s * 0.4, 0, -s * 0.6)
          ..quadraticBezierTo(s * 0.6, -s * 0.4, 0, s * 0.5)
          ..close();
        canvas.drawPath(gPath, _leafPaint);
      } else if (seed.leafType == 3) {
        // Sakura petal with notch
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: s * 1.1, height: s * 0.65), _leafPaint);
      } else {
        // Oak / Birch / Maple lanceolate leaf with central vein
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: s * 1.3, height: s * 0.55), _leafPaint);
        canvas.drawLine(Offset(-s * 0.55, 0), Offset(s * 0.55, 0), _leafVeinPaint);
      }

      canvas.restore();
    }

    // 3. Moonlit Mode: Glowing Fireflies & Bioluminescent Spores
    if (isMoonlit) {
      _leafGlowPaint.color = const Color(0xFFB2DFDB).withValues(alpha: 0.75);
      const fireflySpots = [
        Offset(0.20, 0.48), Offset(0.36, 0.42), Offset(0.58, 0.54),
        Offset(0.72, 0.46), Offset(0.46, 0.62), Offset(0.80, 0.58),
        Offset(0.14, 0.60), Offset(0.66, 0.38),
      ];

      for (int i = 0; i < fireflySpots.length; i++) {
        final spot = fireflySpots[i];
        final bob = math.sin((windPhase * math.pi * 2.2) + i * 1.4) * 5.0;
        final pulse = 1.8 + math.sin(windPhase * math.pi * 3.0 + i) * 0.8;
        canvas.drawCircle(Offset(w * spot.dx, h * spot.dy + bob), pulse, _leafGlowPaint);
      }
    }
  }


  // ─── 10. LIVE FALLING RAIN & SPLASHES ───
  static const List<_RainDropSeed> _rainSeeds = [
    _RainDropSeed(0.02, 0.12, 14.5, 14.0, 1.0, 0.40, false),
    _RainDropSeed(0.04, 0.85, 18.0, 22.0, 1.5, 0.65, true),
    _RainDropSeed(0.06, 0.43, 21.0, 26.0, 1.8, 0.75, true),
    _RainDropSeed(0.08, 0.28, 13.0, 12.0, 0.9, 0.35, false),
    _RainDropSeed(0.11, 0.67, 17.5, 20.0, 1.4, 0.60, true),
    _RainDropSeed(0.13, 0.05, 19.5, 24.0, 1.7, 0.70, true),
    _RainDropSeed(0.15, 0.92, 15.0, 16.0, 1.1, 0.45, false),
    _RainDropSeed(0.17, 0.38, 18.5, 22.0, 1.5, 0.65, true),
    _RainDropSeed(0.19, 0.74, 21.5, 28.0, 1.9, 0.78, true),
    _RainDropSeed(0.22, 0.19, 13.5, 13.0, 0.9, 0.38, false),
    _RainDropSeed(0.24, 0.56, 17.0, 19.0, 1.3, 0.58, true),
    _RainDropSeed(0.26, 0.81, 20.0, 25.0, 1.7, 0.72, true),
    _RainDropSeed(0.28, 0.33, 15.5, 17.0, 1.1, 0.48, false),
    _RainDropSeed(0.31, 0.62, 18.0, 21.0, 1.4, 0.62, true),
    _RainDropSeed(0.33, 0.09, 22.0, 27.0, 1.8, 0.75, true),
    _RainDropSeed(0.35, 0.47, 14.0, 14.0, 1.0, 0.42, false),
    _RainDropSeed(0.37, 0.89, 17.5, 20.0, 1.4, 0.60, true),
    _RainDropSeed(0.40, 0.25, 20.5, 26.0, 1.8, 0.74, true),
    _RainDropSeed(0.42, 0.71, 15.0, 15.0, 1.0, 0.45, false),
    _RainDropSeed(0.44, 0.15, 18.5, 23.0, 1.5, 0.68, true),
    _RainDropSeed(0.46, 0.53, 21.0, 27.0, 1.9, 0.76, true),
    _RainDropSeed(0.49, 0.96, 13.0, 12.0, 0.9, 0.36, false),
    _RainDropSeed(0.51, 0.36, 17.0, 19.0, 1.3, 0.56, true),
    _RainDropSeed(0.53, 0.79, 19.5, 24.0, 1.7, 0.70, true),
    _RainDropSeed(0.55, 0.22, 14.5, 16.0, 1.1, 0.44, false),
    _RainDropSeed(0.58, 0.65, 18.0, 22.0, 1.5, 0.65, true),
    _RainDropSeed(0.60, 0.04, 21.5, 28.0, 1.9, 0.78, true),
    _RainDropSeed(0.62, 0.41, 13.5, 13.0, 0.9, 0.38, false),
    _RainDropSeed(0.64, 0.83, 17.5, 20.0, 1.4, 0.60, true),
    _RainDropSeed(0.67, 0.29, 20.0, 25.0, 1.7, 0.72, true),
    _RainDropSeed(0.69, 0.73, 15.0, 15.0, 1.0, 0.46, false),
    _RainDropSeed(0.71, 0.17, 18.5, 22.0, 1.5, 0.66, true),
    _RainDropSeed(0.73, 0.58, 22.0, 27.0, 1.8, 0.76, true),
    _RainDropSeed(0.76, 0.91, 14.0, 14.0, 1.0, 0.40, false),
    _RainDropSeed(0.78, 0.34, 17.0, 19.0, 1.3, 0.58, true),
    _RainDropSeed(0.80, 0.76, 20.5, 26.0, 1.8, 0.74, true),
    _RainDropSeed(0.82, 0.11, 15.5, 16.0, 1.1, 0.46, false),
    _RainDropSeed(0.85, 0.49, 18.5, 23.0, 1.5, 0.67, true),
    _RainDropSeed(0.87, 0.88, 21.0, 27.0, 1.8, 0.75, true),
    _RainDropSeed(0.89, 0.26, 13.0, 12.0, 0.9, 0.36, false),
    _RainDropSeed(0.91, 0.69, 17.5, 20.0, 1.4, 0.62, true),
    _RainDropSeed(0.93, 0.07, 20.0, 25.0, 1.7, 0.72, true),
    _RainDropSeed(0.96, 0.45, 14.5, 15.0, 1.0, 0.42, false),
    _RainDropSeed(0.98, 0.82, 19.0, 24.0, 1.6, 0.68, true),
  ];

  void _drawRainEffect(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft Overcast Atmospheric Rain Veil
    if (isMoonlit) {
      _rainAtmospherePaint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x3206131D),
          Color(0x240A1A26),
          Color(0x180F2230),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    } else {
      _rainAtmospherePaint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x2A37474F),
          Color(0x1C455A64),
          Color(0x12546E7A),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _rainAtmospherePaint);

    // 2. Rising Forest Floor Mist / Rain Vapor
    _rainMistPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        (isMoonlit ? const Color(0xFF142C33) : const Color(0xFFB0BEC5)).withValues(alpha: 0.16),
      ],
    ).createShader(Rect.fromLTWH(0, h * 0.68, w, h * 0.32));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.68, w, h * 0.32), _rainMistPaint);

    // 3. Falling Rain Streaks & Ground / Water Splashes
    final slantX = (windGust * 2.4 - 0.22) * 22.0;

    for (int i = 0; i < _rainSeeds.length; i++) {
      final seed = _rainSeeds[i];
      final fallProgress = (windPhase * seed.speedMultiplier + seed.yOffsetRatio) % 1.0;
      final dropY = fallProgress * (h + 80.0) - 40.0;
      final dropX = ((seed.xRatio * w + panOffset * 0.12) % w + w) % w + fallProgress * slantX;

      // Rain Streak
      final dropColor = isMoonlit
          ? Color.fromRGBO(190, 235, 255, seed.opacity)
          : Color.fromRGBO(155, 205, 245, seed.opacity * 0.92);
      _rainDropPaint
        ..color = dropColor
        ..strokeWidth = seed.strokeWidth;

      canvas.drawLine(
        Offset(dropX, dropY),
        Offset(dropX + slantX * 0.14, dropY + seed.length),
        _rainDropPaint,
      );

      // Splash ripples on forest floor and glade spring pool
      if (seed.hasSplash && fallProgress > 0.78 && dropY > h * 0.42) {
        final splashProgress = (fallProgress - 0.78) / 0.22;
        final splashAlpha = (1.0 - splashProgress) * seed.opacity * 0.85;
        if (splashAlpha > 0.05) {
          final splashW = 3.5 + splashProgress * 15.0;
          final splashH = 1.4 + splashProgress * 4.8;
          _rainSplashPaint
            ..color = (isMoonlit ? const Color(0xFFB3E5FC) : const Color(0xFF90CAF9))
                .withValues(alpha: splashAlpha)
            ..strokeWidth = 1.0;

          final splashCenter = Offset(dropX + slantX * 0.14, dropY + seed.length * 0.85);
          canvas.drawOval(
            Rect.fromCenter(center: splashCenter, width: splashW, height: splashH),
            _rainSplashPaint,
          );
        }
      }
    }
  }

  // Decoration Rendering
  void _drawDecorationEntity(Canvas canvas, DecorationEntity entity, Offset pos, double depthScale) {
    final dec = entity.decoration;

    decorationHitBoxes?[dec.id] = Rect.fromCenter(
      center: Offset(pos.dx, pos.dy - 12 * depthScale),
      width: 32 * depthScale,
      height: 32 * depthScale,
    );

    _ambientShadowPaint.color = Colors.black.withValues(alpha: isMoonlit ? 0.3 : 0.15);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy + 2), width: 22 * depthScale, height: 10 * depthScale),
      _ambientShadowPaint,
    );

    if (dec.category == DecorationCategory.lighting || dec.id.contains('lantern')) {
      final stonePaint = Paint()..color = isMoonlit ? const Color(0xFF455A64) : const Color(0xFF78909C);
      canvas.drawRect(Rect.fromLTWH(pos.dx - 3 * depthScale, pos.dy - 16 * depthScale, 6 * depthScale, 16 * depthScale), stonePaint);
      canvas.drawRect(Rect.fromLTWH(pos.dx - 6 * depthScale, pos.dy - 20 * depthScale, 12 * depthScale, 5 * depthScale), stonePaint);

      final lightPaint = Paint()..color = const Color(0xFFFFD54F);
      canvas.drawCircle(Offset(pos.dx, pos.dy - 17 * depthScale), 3 * depthScale, lightPaint);

      final glow = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(pos.dx, pos.dy - 17 * depthScale), 7 * depthScale, glow);
    } else {
      final woodPaint = Paint()..color = isMoonlit ? const Color(0xFF4E342E) : const Color(0xFF8D6E63);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(pos.dx, pos.dy - 6 * depthScale), width: 20 * depthScale, height: 6 * depthScale),
          Radius.circular(2 * depthScale),
        ),
        woodPaint,
      );
      canvas.drawRect(Rect.fromLTWH(pos.dx - 8 * depthScale, pos.dy - 3 * depthScale, 2.5 * depthScale, 5 * depthScale), woodPaint);
      canvas.drawRect(Rect.fromLTWH(pos.dx + 5.5 * depthScale, pos.dy - 3 * depthScale, 2.5 * depthScale, 5 * depthScale), woodPaint);
    }
  }

  // ─── 10. WILDLIFE & SKY BIRDS RENDERING ───
  void _drawFlyingSkyBirds(Canvas canvas, Size size, double panoramaWidth) {
    if (wildlife == null) return;

    for (final bird in wildlife!) {
      if (bird.type != WildlifeType.songbird) continue;

      final birdScreenX = _wrapWorldXToScreen(bird.worldU * panoramaWidth, panoramaWidth, panOffset * 0.18, size.width);
      final birdScreenY = size.height * (0.19 + bird.worldV * 0.10) + math.sin(bird.animPhase * 0.9) * 6.0;

      // Cull off-screen
      if (birdScreenX < -60 || birdScreenX > size.width + 60) continue;

      final flap = bird.wingFlap;
      final facing = bird.heading >= 0 ? 1.0 : -1.0;
      final wingLift = flap * 9.0;

      // Hitbox for sky bird
      wildlifeHitBoxes?[bird.id] = Rect.fromCenter(
        center: Offset(birdScreenX, birdScreenY),
        width: 48,
        height: 38,
      );

      canvas.save();
      canvas.translate(birdScreenX, birdScreenY);
      if (facing < 0) {
        canvas.scale(-1.0, 1.0);
      }

      final birdDark = isMoonlit ? const Color(0xFF90A4AE) : const Color(0xFF37474F);
      final birdChest = isMoonlit
          ? const Color(0xFFCFD8DC)
          : (bird.id.contains('robin') ? const Color(0xFFE57373) : const Color(0xFFECEFF1));

      // Wings path (graceful soaring arc)
      final wingPath = Path();
      // Far wing
      wingPath.moveTo(-2, -2);
      wingPath.quadraticBezierTo(-8, -14 - wingLift * 0.7, -18, -11 - wingLift * 0.7);
      wingPath.quadraticBezierTo(-10, -6 - wingLift * 0.4, 0, 0);
      // Near wing
      wingPath.moveTo(0, 0);
      wingPath.quadraticBezierTo(4, -16 - wingLift, 18, -12 - wingLift);
      wingPath.quadraticBezierTo(8, -5 - wingLift * 0.5, 3, 2);
      wingPath.close();

      _animalBodyPaint.color = birdDark;
      canvas.drawPath(wingPath, _animalBodyPaint);

      // Bird Torso
      final bodyPath = Path()
        ..moveTo(-12, 3) // Split tail
        ..lineTo(-18, 7)
        ..lineTo(-13, 2)
        ..lineTo(-17, 0)
        ..lineTo(-8, 0)
        ..quadraticBezierTo(0, -2, 6, -1) // Head
        ..lineTo(10, -1) // Beak
        ..lineTo(6, 1)
        ..quadraticBezierTo(2, 4, -4, 4) // Breast
        ..close();
      canvas.drawPath(bodyPath, _animalBodyPaint);

      // Chest highlight
      _animalFeaturePaint.color = birdChest;
      canvas.drawOval(Rect.fromCenter(center: const Offset(1, 1), width: 7, height: 4), _animalFeaturePaint);

      // Beak tip
      final beakPaint = Paint()..color = const Color(0xFFFFB300);
      canvas.drawCircle(const Offset(9.5, -0.5), 1.0, beakPaint);

      canvas.restore();

      // If bird was tapped, show reaction heart in the sky!
      if (bird.isReacting) {
        _drawReactionHeart(canvas, bird, Offset(birdScreenX, birdScreenY), 1.0);
      }
    }
  }

  void _drawWildlifeEntity(Canvas canvas, WildlifeEntity entity, Offset pos, double depthScale) {
    final animal = entity.animal;

    switch (animal.type) {
      case WildlifeType.rabbit:
        _drawBunny(canvas, animal, pos, depthScale);
        break;
      case WildlifeType.babyElephant:
        _drawBabyElephant(canvas, animal, pos, depthScale);
        break;
      case WildlifeType.giraffe:
        _drawGiraffe(canvas, animal, pos, depthScale);
        break;
      case WildlifeType.fawn:
        _drawFawn(canvas, animal, pos, depthScale);
        break;
      case WildlifeType.butterfly:
        _drawButterflies(canvas, animal, pos, depthScale);
        break;
      case WildlifeType.redFox:
        _drawRedFox(canvas, animal, pos, depthScale);
        break;
      case WildlifeType.wiseOwl:
        _drawWiseOwl(canvas, animal, pos, depthScale);
        break;
      case WildlifeType.chipmunk:
        _drawChipmunk(canvas, animal, pos, depthScale);
        break;
      case WildlifeType.mossTortoise:
        _drawMossTortoise(canvas, animal, pos, depthScale);
        break;
      case WildlifeType.koiFish:
        _drawKoiFish(canvas, animal, pos, depthScale);
        break;
      case WildlifeType.songbird:
        break;
    }

    if (animal.isReacting) {
      _drawReactionHeart(canvas, animal, pos, depthScale);
    }
  }

  void _drawReactionHeart(Canvas canvas, ForestWildlife animal, Offset pos, double depthScale) {
    final progress = animal.reactionProgress;
    if (progress <= 0.0 || progress >= 1.0) return;

    final heartY = pos.dy - (animal.type == WildlifeType.giraffe ? 95 : 42) * depthScale - progress * 40.0;
    final heartX = pos.dx + math.sin(progress * math.pi * 2) * 6.0;
    final heartScale = (0.9 + math.sin(progress * math.pi) * 0.4) * depthScale;
    final alpha = ((1.0 - progress) * 1.3).clamp(0.0, 1.0);

    _animalHeartGlowPaint.color = const Color(0xFFFF4081).withValues(alpha: alpha * 0.45);
    canvas.drawCircle(Offset(heartX, heartY), 12 * heartScale, _animalHeartGlowPaint);

    _animalHeartPaint.color = const Color(0xFFFF2A6D).withValues(alpha: alpha);
    _drawHeart(canvas, Offset(heartX, heartY), 14.0 * heartScale, _animalHeartPaint);

    final sparklePaint = Paint()..color = Colors.white.withValues(alpha: alpha);
    canvas.drawCircle(Offset(heartX - 7 * heartScale, heartY - 5 * heartScale), 1.4 * heartScale, sparklePaint);
    canvas.drawCircle(Offset(heartX + 6 * heartScale, heartY + 4 * heartScale), 1.2 * heartScale, sparklePaint);
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final half = size / 2.0;
    path.moveTo(center.dx, center.dy + half * 0.7);
    path.cubicTo(
      center.dx - half * 1.3, center.dy - half * 0.3,
      center.dx - half * 1.3, center.dy - half * 1.5,
      center.dx, center.dy - half * 0.7,
    );
    path.cubicTo(
      center.dx + half * 1.3, center.dy - half * 1.5,
      center.dx + half * 1.3, center.dy - half * 0.3,
      center.dx, center.dy + half * 0.7,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawBunny(Canvas canvas, ForestWildlife bunny, Offset pos, double depthScale) {
    final facing = bunny.heading >= 0 ? 1.0 : -1.0;
    final hopY = -bunny.hopDisplacement * depthScale;
    final reactJump = bunny.isReacting ? -math.sin(bunny.reactionProgress * math.pi) * 26.0 * depthScale : 0.0;
    final totalYOffset = hopY + reactJump;

    // Ground shadow: stays on grass while bunny hops!
    final shadowScale = (1.0 - (totalYOffset.abs() / (40.0 * depthScale))).clamp(0.4, 1.0);
    _ambientShadowPaint.color = Colors.black.withValues(alpha: (isMoonlit ? 0.35 : 0.22) * shadowScale);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(pos.dx, pos.dy + 3),
        width: 26 * depthScale * shadowScale,
        height: 10 * depthScale * shadowScale,
      ),
      _ambientShadowPaint,
    );

    // Hitbox
    wildlifeHitBoxes?[bunny.id] = Rect.fromCenter(
      center: Offset(pos.dx, pos.dy - 16 * depthScale),
      width: 44 * depthScale,
      height: 44 * depthScale,
    );

    final bY = pos.dy + totalYOffset;

    canvas.save();
    canvas.translate(pos.dx, bY);
    if (facing < 0) {
      canvas.scale(-1.0, 1.0);
    }

    final s = depthScale;

    // 1. Tail (fluffy cotton ball)
    _animalBodyPaint.color = isMoonlit ? const Color(0xFFD4E6F1) : const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset(-13 * s, -8 * s), 5 * s, _animalBodyPaint);

    // 2. Hind Leg / Thigh
    _animalDetailPaint.color = isMoonlit ? const Color(0xFF90A4AE) : const Color(0xFFF0EBE1);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-5 * s, -7 * s), width: 14 * s, height: 11 * s),
      _animalDetailPaint,
    );
    // Back paw
    _animalBodyPaint.color = isMoonlit ? const Color(0xFFB0BEC5) : const Color(0xFFFAF7F2);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-2 * s, -1 * s), width: 10 * s, height: 5 * s),
      _animalBodyPaint,
    );

    // 3. Main Torso / Body (Soft rounded fluffy curve)
    _animalBodyPaint.color = isMoonlit ? const Color(0xFFCFD8DC) : const Color(0xFFFFFFFF);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(1 * s, -12 * s), width: 22 * s, height: 17 * s),
      _animalBodyPaint,
    );

    // Front paw
    canvas.drawOval(
      Rect.fromCenter(center: Offset(8 * s, -2 * s), width: 7 * s, height: 5 * s),
      _animalBodyPaint,
    );

    // 4. Ears (with twitch animation & pink inner ear)
    final earTwitch = bunny.earTwitchAngle;
    canvas.save();
    canvas.translate(6 * s, -22 * s);
    canvas.rotate(earTwitch);
    // Back ear
    _animalDetailPaint.color = isMoonlit ? const Color(0xFFB0BEC5) : const Color(0xFFEBE5DB);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-3 * s, -18 * s, 6 * s, 19 * s),
        Radius.circular(3 * s),
      ),
      _animalDetailPaint,
    );
    // Front ear
    _animalBodyPaint.color = isMoonlit ? const Color(0xFFCFD8DC) : const Color(0xFFFFFFFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1 * s, -20 * s, 6.5 * s, 21 * s),
        Radius.circular(3.5 * s),
      ),
      _animalBodyPaint,
    );
    // Inner pink ear
    _animalFeaturePaint.color = const Color(0xFFFFB3BA);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2.2 * s, -18 * s, 4 * s, 16 * s),
        Radius.circular(2 * s),
      ),
      _animalFeaturePaint,
    );
    canvas.restore();

    // 5. Head
    _animalBodyPaint.color = isMoonlit ? const Color(0xFFECEFF1) : const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset(8 * s, -19 * s), 9.5 * s, _animalBodyPaint);

    // Chubby cheek
    canvas.drawCircle(Offset(12 * s, -16 * s), 5 * s, _animalBodyPaint);

    // Eye (Black gleaming eye with specular sparkle)
    _animalEyePaint.color = const Color(0xFF1E272C);
    canvas.drawCircle(Offset(10.5 * s, -20 * s), 2.2 * s, _animalEyePaint);
    _animalEyeWhitePaint.color = Colors.white;
    canvas.drawCircle(Offset(11.2 * s, -20.8 * s), 0.9 * s, _animalEyeWhitePaint);

    // Pink nose
    _animalFeaturePaint.color = const Color(0xFFFF8DA1);
    canvas.drawCircle(Offset(16.5 * s, -17.5 * s), 1.6 * s, _animalFeaturePaint);

    // Whiskers
    final whiskerPaint = Paint()
      ..color = (isMoonlit ? Colors.white38 : Colors.black26)
      ..strokeWidth = 0.8 * s;
    canvas.drawLine(Offset(16 * s, -16.5 * s), Offset(21 * s, -15.5 * s), whiskerPaint);
    canvas.drawLine(Offset(16 * s, -17.5 * s), Offset(22 * s, -18.5 * s), whiskerPaint);

    canvas.restore();
  }

  void _drawBabyElephant(Canvas canvas, ForestWildlife elephant, Offset pos, double depthScale) {
    final facing = elephant.heading >= 0 ? 1.0 : -1.0;
    final walkSwing = math.sin(elephant.animPhase * 2.8) * 4.0 * depthScale;
    final reactJump = elephant.isReacting ? -math.sin(elephant.reactionProgress * math.pi) * 18.0 * depthScale : 0.0;
    final s = depthScale;

    // Ground shadow
    _ambientShadowPaint.color = Colors.black.withValues(alpha: isMoonlit ? 0.38 : 0.24);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy + 3), width: 48 * s, height: 16 * s),
      _ambientShadowPaint,
    );

    // Hitbox
    wildlifeHitBoxes?[elephant.id] = Rect.fromCenter(
      center: Offset(pos.dx, pos.dy - 22 * s),
      width: 58 * s,
      height: 52 * s,
    );

    final eY = pos.dy + reactJump;

    canvas.save();
    canvas.translate(pos.dx, eY);
    if (facing < 0) {
      canvas.scale(-1.0, 1.0);
    }

    final bodyColor = isMoonlit ? const Color(0xFF607D8B) : const Color(0xFF8DA3B0);
    final shadowBodyColor = isMoonlit ? const Color(0xFF455A64) : const Color(0xFF718896);

    // 1. Back Tail
    final tailPaint = Paint()
      ..color = shadowBodyColor
      ..strokeWidth = 2.0 * s
      ..style = PaintingStyle.stroke;
    final tailPath = Path()
      ..moveTo(-18 * s, -18 * s)
      ..quadraticBezierTo(-24 * s, -12 * s, -22 * s + math.sin(elephant.animPhase * 3.0) * 3 * s, -6 * s);
    canvas.drawPath(tailPath, tailPaint);
    _animalFeaturePaint.color = const Color(0xFF424242);
    canvas.drawCircle(Offset(-22 * s + math.sin(elephant.animPhase * 3.0) * 3 * s, -5 * s), 2.2 * s, _animalFeaturePaint);

    // 2. Far Legs (Back-left and Front-left)
    _animalDetailPaint.color = shadowBodyColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-14 * s - walkSwing, -14 * s, 8 * s, 16 * s),
        Radius.circular(4 * s),
      ),
      _animalDetailPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8 * s + walkSwing, -14 * s, 8 * s, 16 * s),
        Radius.circular(4 * s),
      ),
      _animalDetailPaint,
    );

    // 3. Big Plump Body
    _animalBodyPaint.color = bodyColor;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-3 * s, -18 * s), width: 34 * s, height: 26 * s),
      _animalBodyPaint,
    );

    // 4. Near Legs (Back-right and Front-right with alternating stride)
    _animalBodyPaint.color = bodyColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-10 * s + walkSwing, -12 * s, 8.5 * s, 14 * s),
        Radius.circular(4 * s),
      ),
      _animalBodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4 * s - walkSwing, -12 * s, 8.5 * s, 14 * s),
        Radius.circular(4 * s),
      ),
      _animalBodyPaint,
    );

    // Cute toenail dots on near feet
    _animalEyeWhitePaint.color = const Color(0xFFE0E0E0);
    canvas.drawCircle(Offset(-8 * s + walkSwing, 0.5 * s), 1.2 * s, _animalEyeWhitePaint);
    canvas.drawCircle(Offset(-5 * s + walkSwing, 0.5 * s), 1.2 * s, _animalEyeWhitePaint);
    canvas.drawCircle(Offset(6 * s - walkSwing, 0.5 * s), 1.2 * s, _animalEyeWhitePaint);
    canvas.drawCircle(Offset(9 * s - walkSwing, 0.5 * s), 1.2 * s, _animalEyeWhitePaint);

    // 5. Head
    canvas.drawCircle(Offset(12 * s, -24 * s), 13 * s, _animalBodyPaint);

    // 6. Trunk (Animated curling trunk!)
    final trunkAngle = elephant.trunkSwingAngle;
    final trunkPath = Path();
    trunkPath.moveTo(18 * s, -21 * s);
    if (elephant.isReacting) {
      trunkPath.cubicTo(
        24 * s, -18 * s,
        30 * s, -26 * s - trunkAngle * 10 * s,
        28 * s, -34 * s - trunkAngle * 12 * s,
      );
    } else {
      trunkPath.cubicTo(
        23 * s, -18 * s,
        25 * s + trunkAngle * 8 * s, -10 * s,
        22 * s + trunkAngle * 12 * s, -4 * s,
      );
    }
    final trunkPaint = Paint()
      ..color = bodyColor
      ..strokeWidth = 6.0 * s
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(trunkPath, trunkPaint);

    // Baby tusk stub
    final tuskPaint = Paint()..color = const Color(0xFFFFF9E6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(18 * s, -19 * s), width: 4 * s, height: 2.5 * s),
      tuskPaint,
    );

    // 7. Eye (Sweet black eye with specular sparkle)
    _animalEyePaint.color = const Color(0xFF1E272C);
    canvas.drawCircle(Offset(14 * s, -25 * s), 2.2 * s, _animalEyePaint);
    _animalEyeWhitePaint.color = Colors.white;
    canvas.drawCircle(Offset(14.6 * s, -25.8 * s), 0.9 * s, _animalEyeWhitePaint);

    // 8. Big Floppy Ear
    final earFlap = math.sin(elephant.animPhase * 2.0) * 2.0 * s;
    canvas.save();
    canvas.translate(5 * s + earFlap, -26 * s);
    _animalBodyPaint.color = bodyColor;
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 14 * s, height: 19 * s),
      _animalBodyPaint,
    );
    _animalFeaturePaint.color = const Color(0xFFD8BAC2);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 1 * s), width: 9 * s, height: 13 * s),
      _animalFeaturePaint,
    );
    canvas.restore();

    canvas.restore();
  }

  void _drawGiraffe(Canvas canvas, ForestWildlife giraffe, Offset pos, double depthScale) {
    final facing = giraffe.heading >= 0 ? 1.0 : -1.0;
    final stride = math.sin(giraffe.animPhase * 2.2) * 5.0 * depthScale;
    final reactJump = giraffe.isReacting ? -math.sin(giraffe.reactionProgress * math.pi) * 14.0 * depthScale : 0.0;
    final s = depthScale;

    // Ground shadow
    _ambientShadowPaint.color = Colors.black.withValues(alpha: isMoonlit ? 0.35 : 0.22);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy + 2), width: 42 * s, height: 14 * s),
      _ambientShadowPaint,
    );

    // Hitbox (Tall giraffe hitbox extending up to head)
    wildlifeHitBoxes?[giraffe.id] = Rect.fromCenter(
      center: Offset(pos.dx, pos.dy - 45 * s),
      width: 52 * s,
      height: 95 * s,
    );

    final gY = pos.dy + reactJump;

    canvas.save();
    canvas.translate(pos.dx, gY);
    if (facing < 0) {
      canvas.scale(-1.0, 1.0);
    }

    final yellowBody = isMoonlit ? const Color(0xFFD4AC0D) : const Color(0xFFF9C74F);
    final brownPatch = isMoonlit ? const Color(0xFF7E5109) : const Color(0xFFA45A2A);
    final hoofColor = const Color(0xFF3E2723);

    // 1. Slender Tall Legs
    final legPaint = Paint()
      ..color = yellowBody
      ..strokeWidth = 3.6 * s
      ..strokeCap = StrokeCap.round;
    final farLegPaint = Paint()
      ..color = isMoonlit ? const Color(0xFFB7950B) : const Color(0xFFE5B038)
      ..strokeWidth = 3.2 * s
      ..strokeCap = StrokeCap.round;

    // Far back leg & front leg
    canvas.drawLine(Offset(-12 * s, -26 * s), Offset(-12 * s - stride, 0), farLegPaint);
    canvas.drawLine(Offset(10 * s, -28 * s), Offset(10 * s + stride, 0), farLegPaint);

    final hoofPaint = Paint()..color = hoofColor;
    canvas.drawRect(Rect.fromLTWH(-14 * s - stride, -2.5 * s, 4 * s, 3 * s), hoofPaint);
    canvas.drawRect(Rect.fromLTWH(8 * s + stride, -2.5 * s, 4 * s, 3 * s), hoofPaint);

    // 2. Tail with bushy brush
    final tailPath = Path()
      ..moveTo(-16 * s, -34 * s)
      ..quadraticBezierTo(-23 * s, -24 * s, -22 * s + math.sin(giraffe.animPhase * 2.5) * 4 * s, -12 * s);
    canvas.drawPath(
      tailPath,
      Paint()
        ..color = yellowBody
        ..strokeWidth = 1.8 * s
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(Offset(-22 * s + math.sin(giraffe.animPhase * 2.5) * 4 * s, -11 * s), 3 * s, hoofPaint);

    // 3. Body Torso
    final bodyPath = Path()
      ..moveTo(12 * s, -38 * s)
      ..lineTo(-16 * s, -32 * s)
      ..quadraticBezierTo(-18 * s, -22 * s, -10 * s, -24 * s)
      ..quadraticBezierTo(0, -23 * s, 8 * s, -27 * s)
      ..close();
    _animalBodyPaint.color = yellowBody;
    canvas.drawPath(bodyPath, _animalBodyPaint);

    // Body patches
    _animalFeaturePaint.color = brownPatch;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-12 * s, -32 * s, 7 * s, 6 * s), Radius.circular(2 * s)), _animalFeaturePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-3 * s, -34 * s, 8 * s, 7 * s), Radius.circular(2.5 * s)), _animalFeaturePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-4 * s, -26 * s, 6 * s, 5 * s), Radius.circular(2 * s)), _animalFeaturePaint);

    // Near front & back legs
    canvas.drawLine(Offset(-8 * s, -25 * s), Offset(-8 * s + stride, 0), legPaint);
    canvas.drawLine(Offset(6 * s, -27 * s), Offset(6 * s - stride, 0), legPaint);
    canvas.drawRect(Rect.fromLTWH(-10 * s + stride, -2.5 * s, 4.5 * s, 3 * s), hoofPaint);
    canvas.drawRect(Rect.fromLTWH(4 * s - stride, -2.5 * s, 4.5 * s, 3 * s), hoofPaint);

    // 4. Elegant Long Neck
    final neckSway = giraffe.neckSway * s;
    final headCenter = Offset(18 * s + neckSway, -74 * s);

    final neckPath = Path()
      ..moveTo(8 * s, -37 * s)
      ..lineTo(headCenter.dx - 3 * s, headCenter.dy + 8 * s)
      ..lineTo(headCenter.dx + 4 * s, headCenter.dy + 8 * s)
      ..lineTo(14 * s, -35 * s)
      ..close();
    canvas.drawPath(neckPath, _animalBodyPaint);

    // Mane along back of neck
    final manePaint = Paint()
      ..color = brownPatch
      ..strokeWidth = 2.2 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(7 * s, -37 * s), Offset(headCenter.dx - 4 * s, headCenter.dy + 10 * s), manePaint);

    // Neck spots
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(9 * s + neckSway * 0.3, -48 * s, 5 * s, 6 * s), Radius.circular(2 * s)), _animalFeaturePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(12 * s + neckSway * 0.6, -60 * s, 4.5 * s, 5.5 * s), Radius.circular(1.5 * s)), _animalFeaturePaint);

    // 5. Head
    _animalBodyPaint.color = yellowBody;
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: headCenter, width: 14 * s, height: 11 * s),
      Radius.circular(4 * s),
    );
    canvas.drawRRect(headRect, _animalBodyPaint);

    // Muzzle
    _animalDetailPaint.color = isMoonlit ? const Color(0xFFC7B198) : const Color(0xFFF0DEC5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(headCenter.dx + 7 * s, headCenter.dy + 1 * s), width: 7 * s, height: 6 * s),
      _animalDetailPaint,
    );
    canvas.drawCircle(Offset(headCenter.dx + 8.5 * s, headCenter.dy + 0.5 * s), 0.9 * s, hoofPaint);

    // Eye
    _animalEyePaint.color = const Color(0xFF1E272C);
    canvas.drawCircle(Offset(headCenter.dx + 2 * s, headCenter.dy - 1.5 * s), 1.8 * s, _animalEyePaint);
    _animalEyeWhitePaint.color = Colors.white;
    canvas.drawCircle(Offset(headCenter.dx + 2.4 * s, headCenter.dy - 2.0 * s), 0.7 * s, _animalEyeWhitePaint);

    // Ossicones
    final hornPaint = Paint()
      ..color = yellowBody
      ..strokeWidth = 2.0 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(headCenter.dx - 1 * s, headCenter.dy - 5 * s), Offset(headCenter.dx - 1 * s, headCenter.dy - 10 * s), hornPaint);
    canvas.drawLine(Offset(headCenter.dx + 2 * s, headCenter.dy - 5 * s), Offset(headCenter.dx + 3 * s, headCenter.dy - 10 * s), hornPaint);
    canvas.drawCircle(Offset(headCenter.dx - 1 * s, headCenter.dy - 10.5 * s), 1.6 * s, hoofPaint);
    canvas.drawCircle(Offset(headCenter.dx + 3 * s, headCenter.dy - 10.5 * s), 1.6 * s, hoofPaint);

    // Ear
    canvas.drawOval(
      Rect.fromCenter(center: Offset(headCenter.dx - 4 * s, headCenter.dy - 3 * s), width: 7 * s, height: 3.5 * s),
      _animalBodyPaint,
    );

    canvas.restore();
  }

  void _drawFawn(Canvas canvas, ForestWildlife fawn, Offset pos, double depthScale) {
    final facing = fawn.heading >= 0 ? 1.0 : -1.0;
    final walk = math.sin(fawn.animPhase * 2.4) * 4.0 * depthScale;
    final reactJump = fawn.isReacting ? -math.sin(fawn.reactionProgress * math.pi) * 22.0 * depthScale : 0.0;
    final s = depthScale;

    // Ground shadow
    _ambientShadowPaint.color = Colors.black.withValues(alpha: isMoonlit ? 0.35 : 0.22);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy + 2), width: 34 * s, height: 11 * s),
      _ambientShadowPaint,
    );

    // Hitbox
    wildlifeHitBoxes?[fawn.id] = Rect.fromCenter(
      center: Offset(pos.dx, pos.dy - 24 * s),
      width: 44 * s,
      height: 52 * s,
    );

    final fY = pos.dy + reactJump;

    canvas.save();
    canvas.translate(pos.dx, fY);
    if (facing < 0) {
      canvas.scale(-1.0, 1.0);
    }

    final coatColor = isMoonlit ? const Color(0xFF8D6E63) : const Color(0xFFC87D55);
    final darkHoof = const Color(0xFF2C1E18);

    // Far legs
    final farLegPaint = Paint()
      ..color = isMoonlit ? const Color(0xFF6D4C41) : const Color(0xFFA66340)
      ..strokeWidth = 2.4 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-8 * s, -14 * s), Offset(-8 * s - walk, 0), farLegPaint);
    canvas.drawLine(Offset(6 * s, -14 * s), Offset(6 * s + walk, 0), farLegPaint);

    // Body
    _animalBodyPaint.color = coatColor;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-1 * s, -16 * s), width: 22 * s, height: 14 * s),
      _animalBodyPaint,
    );

    // Bambi white dapples
    final spotPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(Offset(-5 * s, -19 * s), 1.2 * s, spotPaint);
    canvas.drawCircle(Offset(-1 * s, -20 * s), 1.3 * s, spotPaint);
    canvas.drawCircle(Offset(3 * s, -19 * s), 1.1 * s, spotPaint);
    canvas.drawCircle(Offset(-3 * s, -16 * s), 1.0 * s, spotPaint);

    // Tail
    final tailPaint = Paint()
      ..color = coatColor
      ..strokeWidth = 2.2 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-10 * s, -18 * s), Offset(-14 * s, -15 * s), tailPaint);
    canvas.drawCircle(Offset(-14 * s, -15 * s), 1.2 * s, spotPaint);

    // Near legs
    final nearLegPaint = Paint()
      ..color = coatColor
      ..strokeWidth = 2.6 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-5 * s, -13 * s), Offset(-5 * s + walk, 0), nearLegPaint);
    canvas.drawLine(Offset(4 * s, -13 * s), Offset(4 * s - walk, 0), nearLegPaint);

    // Hooves
    final hoofPaint = Paint()..color = darkHoof;
    canvas.drawCircle(Offset(-5 * s + walk, 0), 1.3 * s, hoofPaint);
    canvas.drawCircle(Offset(4 * s - walk, 0), 1.3 * s, hoofPaint);

    // Slender Neck & Head
    final neckPath = Path()
      ..moveTo(4 * s, -19 * s)
      ..lineTo(8 * s, -30 * s)
      ..lineTo(12 * s, -30 * s)
      ..lineTo(9 * s, -17 * s)
      ..close();
    canvas.drawPath(neckPath, _animalBodyPaint);

    // Head
    canvas.drawOval(
      Rect.fromCenter(center: Offset(11 * s, -31 * s), width: 10 * s, height: 8 * s),
      _animalBodyPaint,
    );

    // White muzzle
    _animalDetailPaint.color = Colors.white70;
    canvas.drawCircle(Offset(14.5 * s, -30 * s), 2.5 * s, _animalDetailPaint);
    canvas.drawCircle(Offset(16 * s, -30.5 * s), 1.0 * s, hoofPaint);

    // Sweet large dark eye
    _animalEyePaint.color = const Color(0xFF1E272C);
    canvas.drawCircle(Offset(11 * s, -32 * s), 1.8 * s, _animalEyePaint);
    _animalEyeWhitePaint.color = Colors.white;
    canvas.drawCircle(Offset(11.4 * s, -32.5 * s), 0.7 * s, _animalEyeWhitePaint);

    // Tall alert ears
    final earPath = Path()
      ..moveTo(8 * s, -33 * s)
      ..quadraticBezierTo(7 * s, -41 * s, 10 * s, -40 * s)
      ..lineTo(11 * s, -34 * s)
      ..close();
    canvas.drawPath(earPath, _animalBodyPaint);
    final earInner = Path()
      ..moveTo(8.5 * s, -34 * s)
      ..quadraticBezierTo(8 * s, -39 * s, 9.8 * s, -38.5 * s)
      ..close();
    canvas.drawPath(earInner, Paint()..color = const Color(0xFFFFCDD2));

    canvas.restore();
  }

  void _drawButterflies(Canvas canvas, ForestWildlife butterfly, Offset pos, double depthScale) {
    final flutterScale = butterfly.butterflyFlap;
    final flutterBob = math.sin(butterfly.animPhase * 5.0) * 8.0 * depthScale;
    final s = depthScale;

    final bX = pos.dx;
    final bY = pos.dy - 12 * s + flutterBob;

    wildlifeHitBoxes?[butterfly.id] = Rect.fromCenter(
      center: Offset(bX, bY),
      width: 32 * s,
      height: 32 * s,
    );

    canvas.save();
    canvas.translate(bX, bY);

    final isAzure = butterfly.id.contains('azure');
    final wingPrimary = isAzure
        ? (isMoonlit ? const Color(0xFF29B6F6) : const Color(0xFF039BE5))
        : (isMoonlit ? const Color(0xFFFFCA28) : const Color(0xFFFFB300));
    final wingSecondary = isAzure ? const Color(0xFFE1F5FE) : const Color(0xFFFFF9C4);

    final wingWidth = 10 * s * flutterScale;
    final wingHeight = 12 * s;

    // Left wing
    final leftWing = Path()
      ..moveTo(0, 0)
      ..cubicTo(-wingWidth * 1.4, -wingHeight * 1.2, -wingWidth * 1.6, -wingHeight * 0.4, 0, -wingHeight * 0.2)
      ..cubicTo(-wingWidth * 1.3, wingHeight * 0.2, -wingWidth * 0.9, wingHeight * 0.8, 0, wingHeight * 0.4)
      ..close();
    _animalBodyPaint.color = wingPrimary;
    canvas.drawPath(leftWing, _animalBodyPaint);

    // Right wing
    final rightWing = Path()
      ..moveTo(0, 0)
      ..cubicTo(wingWidth * 1.4, -wingHeight * 1.2, wingWidth * 1.6, -wingHeight * 0.4, 0, -wingHeight * 0.2)
      ..cubicTo(wingWidth * 1.3, wingHeight * 0.2, wingWidth * 0.9, wingHeight * 0.8, 0, wingHeight * 0.4)
      ..close();
    canvas.drawPath(rightWing, _animalBodyPaint);

    // Wing highlights
    final highlightPaint = Paint()..color = wingSecondary.withValues(alpha: 0.7);
    canvas.drawCircle(Offset(-wingWidth * 0.6, -wingHeight * 0.5), 2.2 * s * flutterScale, highlightPaint);
    canvas.drawCircle(Offset(wingWidth * 0.6, -wingHeight * 0.5), 2.2 * s * flutterScale, highlightPaint);

    // Center slender body
    final bodyPaint = Paint()..color = const Color(0xFF212121);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 2.2 * s, height: 10 * s), bodyPaint);

    // Sparkle trail
    if (!isMoonlit) {
      final sparklePaint = Paint()..color = wingPrimary.withValues(alpha: 0.4);
      canvas.drawCircle(Offset(math.sin(butterfly.animPhase * 3.0) * 8 * s, 10 * s), 1.2 * s, sparklePaint);
    }

    canvas.restore();
  }

  void _drawShootingStars(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // 2 staggered shooting stars streaking across the velvet sky
    for (int i = 0; i < 2; i++) {
      final cycle = (windPhase * 1.6 + i * 0.54) % 1.0;
      if (cycle < 0.32) {
        final p = cycle / 0.32;
        final startX = w * (0.88 - i * 0.36) - p * (w * 0.50);
        final startY = h * (0.13 + i * 0.05) + p * (h * 0.16);
        final len = 50.0 * (1.0 - (p - 0.5).abs() * 0.7);
        final tailX = startX + len * 0.86;
        final tailY = startY - len * 0.50;

        final alpha = math.sin(p * math.pi);
        final grad = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: alpha),
            const Color(0xFF80DEEA).withValues(alpha: alpha * 0.8),
            const Color(0x0080DEEA),
          ],
        );
        _shootingStarPaint
          ..shader = grad.createShader(Rect.fromPoints(Offset(startX, startY), Offset(tailX, tailY)))
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(startX, startY), Offset(tailX, tailY), _shootingStarPaint);

        // Bright sparkling star head
        final headPaint = Paint()..color = Colors.white.withValues(alpha: alpha);
        canvas.drawCircle(Offset(startX, startY), 1.8, headPaint);
      }
    }
  }

  void _drawGladeSpringPool(Canvas canvas, Size size, int totalSectors, double panoramaWidth) {
    final w = size.width;
    final h = size.height;
    final poolWorldX = 0.52 * panoramaWidth;
    final poolScreenX = _wrapWorldXToScreen(poolWorldX, panoramaWidth, panOffset, w);

    if (poolScreenX < -180 || poolScreenX > w + 180) return;

    // Spacious glade pool nested naturally in the meadow
    final poolCenter = Offset(poolScreenX, h * 0.70);
    const poolRadiusX = 96.0;
    const poolRadiusY = 38.0;

    final waterBasinPath = Path()
      ..addOval(Rect.fromCenter(center: poolCenter, width: poolRadiusX * 2, height: poolRadiusY * 2));

    // 1. Soft bank shadow under pool basin
    _ambientShadowPaint.color = Colors.black.withValues(alpha: isMoonlit ? 0.30 : 0.16);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(poolCenter.dx, poolCenter.dy + 4), width: poolRadiusX * 2.12, height: poolRadiusY * 2.12),
      _ambientShadowPaint,
    );

    // 2. Shoreline sand rim
    _shorelinePaint.color = (isMoonlit ? const Color(0xFF1E2F2B) : const Color(0xFF8D7B68)).withValues(alpha: 0.45);
    canvas.drawOval(
      Rect.fromCenter(center: poolCenter, width: poolRadiusX * 2 + 10, height: poolRadiusY * 2 + 6),
      _shorelinePaint,
    );

    // 3. Smooth River Stones rimming the spring pool
    _waterStonePaint.color = isMoonlit ? const Color(0xFF455A64) : const Color(0xFF78909C);
    const pebbleCount = 18;
    for (int i = 0; i < pebbleCount; i++) {
      final angle = (i / pebbleCount) * math.pi * 2;
      final px = poolCenter.dx + math.cos(angle) * (poolRadiusX + 3.0);
      final py = poolCenter.dy + math.sin(angle) * (poolRadiusY + 2.0);
      final pRadius = 3.6 + (math.sin(i * 1.7).abs() * 2.5);
      canvas.drawCircle(Offset(px, py), pRadius, _waterStonePaint);
      if (i % 3 == 0) {
        _stoneMossPaint.color = isMoonlit ? const Color(0xFF2E7D32) : const Color(0xFF81C784);
        canvas.drawCircle(Offset(px, py - 1), pRadius * 0.55, _stoneMossPaint);
      }
    }

    // 4. Clear Spring Water Basin (Deep teal gradient)
    _waterSpringPaint.shader = RadialGradient(
      center: const Alignment(0.08, -0.18),
      radius: 0.88,
      colors: isMoonlit
          ? [
              const Color(0xFF15333F),
              const Color(0xFF0C2029),
              const Color(0xFF061318),
            ]
          : [
              const Color(0xFF4DD0E1), // Sunlit crystal turquoise
              const Color(0xFF26A69A), // Clear stream teal
              const Color(0xFF00695C), // Deep spring emerald
              const Color(0xFF004D40), // Serene bottom depths
            ],
      stops: isMoonlit ? const [0.0, 0.65, 1.0] : const [0.0, 0.35, 0.72, 1.0],
    ).createShader(Rect.fromCenter(center: poolCenter, width: poolRadiusX * 2, height: poolRadiusY * 2));
    canvas.drawPath(waterBasinPath, _waterSpringPaint);

    // 5. Submerged Riverbed Pebbles on the bottom of the pool
    final bedPaint = Paint()..color = (isMoonlit ? const Color(0xFF0A1E26) : const Color(0xFF004D40)).withValues(alpha: 0.40);
    canvas.drawCircle(Offset(poolCenter.dx - 30, poolCenter.dy + 8), 4.2, bedPaint);
    canvas.drawCircle(Offset(poolCenter.dx + 25, poolCenter.dy - 6), 3.5, bedPaint);
    canvas.drawCircle(Offset(poolCenter.dx - 12, poolCenter.dy - 10), 3.0, bedPaint);
    canvas.drawCircle(Offset(poolCenter.dx + 40, poolCenter.dy + 6), 4.8, bedPaint);

    // 6. Concentric Animated Water Ripples
    final ripplePhase = ((windPhase * 2.5) % 1.0);
    for (int r = 0; r < 2; r++) {
      final progress = (ripplePhase + r * 0.5) % 1.0;
      final rx = (poolRadiusX * 0.20) + progress * (poolRadiusX * 0.62);
      final ry = (poolRadiusY * 0.20) + progress * (poolRadiusY * 0.62);
      final alpha = ((1.0 - progress) * 0.42).clamp(0.0, 1.0);
      _waterRipplePaint
        ..color = (isMoonlit ? const Color(0xFF80DEEA) : Colors.white).withValues(alpha: alpha)
        ..strokeWidth = 1.3;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(poolCenter.dx, poolCenter.dy - 1), width: rx * 2, height: ry * 2),
        _waterRipplePaint,
      );
    }

    // 7. Swimming Golden Koi Fish strictly submerged inside water basin
    if (wildlife != null) {
      for (final a in wildlife!) {
        if (a.type == WildlifeType.koiFish) {
          // Hard clipping ensures zero fish pixels can ever render on dry land
          canvas.save();
          canvas.clipPath(waterBasinPath);

          final swimT = (windPhase * math.pi * 2 * 0.75) + (a.animPhase * 0.04);
          final orbitX = poolRadiusX * 0.44;
          final orbitY = poolRadiusY * 0.38;

          final kx = poolCenter.dx + math.cos(swimT) * orbitX;
          final ky = poolCenter.dy + math.sin(swimT) * orbitY;

          final swimAngle = math.atan2(
            math.cos(swimT) * orbitY,
            -math.sin(swimT) * orbitX,
          );

          // Underwater contact shadow on pool bed (3D depth perception)
          _underwaterShadowPaint.color = Colors.black.withValues(alpha: isMoonlit ? 0.35 : 0.22);
          canvas.drawOval(
            Rect.fromCenter(center: Offset(kx + 2, ky + 6), width: 20, height: 9),
            _underwaterShadowPaint,
          );

          _drawKoiFishInPond(canvas, a, Offset(kx, ky), swimAngle);
          canvas.restore();

          // Register tap hitbox directly over the swimming fish
          wildlifeHitBoxes?[a.id] = Rect.fromCenter(
            center: Offset(kx, ky),
            width: 64,
            height: 44,
          );

          // If reacting, float heart above water in the air
          if (a.isReacting) {
            _drawReactionHeart(canvas, a, Offset(kx, ky), 0.85);
          }
          break;
        }
      }
    }

    // 8. Floating Lily Pads with pink Lotus Bloom (drawn over water surface)
    final padPaint = Paint()..color = isMoonlit ? const Color(0xFF1B5E20) : const Color(0xFF388E3C);
    final pad1Center = Offset(poolCenter.dx - poolRadiusX * 0.58, poolCenter.dy - poolRadiusY * 0.18);
    canvas.drawOval(Rect.fromCenter(center: pad1Center, width: 22, height: 13), padPaint);
    final lilyPaint = Paint()..color = const Color(0xFFFF80AB);
    canvas.drawCircle(Offset(pad1Center.dx + 3, pad1Center.dy - 2), 4.0, lilyPaint);
    final lilyCore = Paint()..color = const Color(0xFFFFEB3B);
    canvas.drawCircle(Offset(pad1Center.dx + 3, pad1Center.dy - 2), 1.6, lilyCore);

    final pad2Center = Offset(poolCenter.dx + poolRadiusX * 0.62, poolCenter.dy + poolRadiusY * 0.22);
    canvas.drawOval(Rect.fromCenter(center: pad2Center, width: 18, height: 11), padPaint);

    final pad3Center = Offset(poolCenter.dx + poolRadiusX * 0.25, poolCenter.dy - poolRadiusY * 0.55);
    canvas.drawOval(Rect.fromCenter(center: pad3Center, width: 14, height: 8), padPaint);
  }

  void _drawKoiFishInPond(
    Canvas canvas,
    ForestWildlife koi,
    Offset pos,
    double swimAngle,
  ) {
    final s = 0.72; // Sleek, perfectly proportioned storybook koi
    final wiggle = koi.koiSwimWiggle;
    final isReacting = koi.isReacting;
    final reactProgress = koi.reactionProgress;
    final reactJump = isReacting ? -math.sin(reactProgress * math.pi) * 8.0 : 0.0;

    // If reacting with leap, draw splash droplets
    if (isReacting && reactProgress < 0.85) {
      final splashPaint = Paint()
        ..color = (isMoonlit ? const Color(0xFF80DEEA) : Colors.white).withValues(alpha: (1.0 - reactProgress) * 0.8)
        ..style = PaintingStyle.fill;
      final splashDist = reactProgress * 12.0;
      canvas.drawCircle(Offset(pos.dx - splashDist, pos.dy + 2), 1.6, splashPaint);
      canvas.drawCircle(Offset(pos.dx + splashDist, pos.dy + 2), 1.6, splashPaint);
      canvas.drawCircle(Offset(pos.dx, pos.dy - 4 - splashDist * 0.6), 1.4, splashPaint);
    }

    canvas.save();
    canvas.translate(pos.dx, pos.dy + reactJump);
    canvas.rotate(swimAngle);

    final koiOrange = isMoonlit ? const Color(0xFFFF9800) : const Color(0xFFFF6D00);
    final koiWhite = isMoonlit ? const Color(0xFFECEFF1) : const Color(0xFFFFF9C4);

    // 1. Curved Body
    final bodyPath = Path()
      ..moveTo(12 * s, 0)
      ..quadraticBezierTo(2 * s, -6 * s, -10 * s, wiggle * 0.4 * s)
      ..quadraticBezierTo(0, 6 * s, 12 * s, 0)
      ..close();
    _animalBodyPaint.color = koiOrange;
    canvas.drawPath(bodyPath, _animalBodyPaint);

    // White scale shimmer
    _animalDetailPaint.color = koiWhite;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(3 * s, 0), width: 8 * s, height: 4 * s),
      _animalDetailPaint,
    );

    // 2. Fluttering Caudal Tail Fin
    final tailPath = Path()
      ..moveTo(-10 * s, wiggle * 0.4 * s)
      ..quadraticBezierTo(-16 * s + wiggle * 0.8 * s, -7 * s, -20 * s + wiggle * s, -4 * s)
      ..quadraticBezierTo(-14 * s, 0, -20 * s + wiggle * s, 4 * s)
      ..quadraticBezierTo(-16 * s + wiggle * 0.8 * s, 7 * s, -10 * s, wiggle * 0.4 * s)
      ..close();
    final finPaint = Paint()..color = koiWhite.withValues(alpha: 0.85);
    canvas.drawPath(tailPath, finPaint);

    // Pectoral fins
    canvas.drawOval(
      Rect.fromCenter(center: Offset(6 * s, -4 * s), width: 6 * s, height: 3 * s),
      finPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(6 * s, 4 * s), width: 6 * s, height: 3 * s),
      finPaint,
    );

    // Black shiny eye
    _animalEyePaint.color = const Color(0xFF1E272C);
    canvas.drawCircle(Offset(10 * s, -1.5 * s), 1.2 * s, _animalEyePaint);

    // Translucent water caustics over fish when swimming underwater
    if (!isReacting) {
      final waterSheen = Paint()..color = (isMoonlit ? const Color(0xFF004D40) : const Color(0xFF4DD0E1)).withValues(alpha: 0.28);
      canvas.drawPath(bodyPath, waterSheen);
    }

    canvas.restore();
  }

  void _drawRedFox(Canvas canvas, ForestWildlife fox, Offset pos, double depthScale) {
    final facing = fox.heading >= 0 ? 1.0 : -1.0;
    final walk = math.sin(fox.animPhase * 3.2) * 3.5 * depthScale;
    final reactJump = fox.isReacting ? -math.sin(fox.reactionProgress * math.pi) * 20.0 * depthScale : 0.0;
    final s = depthScale;

    // Ground shadow
    _ambientShadowPaint.color = Colors.black.withValues(alpha: isMoonlit ? 0.35 : 0.22);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy + 2), width: 36 * s, height: 12 * s),
      _ambientShadowPaint,
    );

    // Hitbox
    wildlifeHitBoxes?[fox.id] = Rect.fromCenter(
      center: Offset(pos.dx, pos.dy - 18 * s),
      width: 48 * s,
      height: 40 * s,
    );

    final fY = pos.dy + reactJump;

    canvas.save();
    canvas.translate(pos.dx, fY);
    if (facing < 0) {
      canvas.scale(-1.0, 1.0);
    }

    final furOrange = isMoonlit ? const Color(0xFFD35400) : const Color(0xFFE65100);
    final furDark = const Color(0xFFBF360C);
    final furWhite = isMoonlit ? const Color(0xFFECEFF1) : const Color(0xFFFFFFFF);
    final sockBlack = const Color(0xFF263238);

    // 1. Bushy Tail with white tip & wagging animation
    final tailWag = fox.foxTailWag;
    canvas.save();
    canvas.translate(-12 * s, -12 * s);
    canvas.rotate(tailWag);
    final tailPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-18 * s, -8 * s, -24 * s, 2 * s)
      ..quadraticBezierTo(-12 * s, 10 * s, 0, 4 * s)
      ..close();
    _animalBodyPaint.color = furOrange;
    canvas.drawPath(tailPath, _animalBodyPaint);

    // White bushy tail tip
    final tailTip = Path()
      ..moveTo(-18 * s, -4 * s)
      ..quadraticBezierTo(-24 * s, 2 * s, -24 * s, 2 * s)
      ..quadraticBezierTo(-18 * s, 7 * s, -14 * s, 6 * s)
      ..close();
    _animalDetailPaint.color = furWhite;
    canvas.drawPath(tailTip, _animalDetailPaint);
    canvas.restore();

    // 2. Far legs (with black socks)
    final farLegPaint = Paint()
      ..color = furDark
      ..strokeWidth = 2.4 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-8 * s, -8 * s), Offset(-8 * s - walk, 0), farLegPaint);
    canvas.drawLine(Offset(8 * s, -8 * s), Offset(8 * s + walk, 0), farLegPaint);

    // 3. Body Torso (slender agile vulpine curve)
    _animalBodyPaint.color = furOrange;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, -12 * s), width: 26 * s, height: 15 * s),
      _animalBodyPaint,
    );

    // White underbelly
    _animalDetailPaint.color = furWhite;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(2 * s, -8 * s), width: 14 * s, height: 7 * s),
      _animalDetailPaint,
    );

    // 4. Near legs (with black socks)
    final nearLegPaint = Paint()
      ..color = furOrange
      ..strokeWidth = 2.8 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-5 * s, -8 * s), Offset(-5 * s + walk, 0), nearLegPaint);
    canvas.drawLine(Offset(6 * s, -8 * s), Offset(6 * s - walk, 0), nearLegPaint);

    // Black paws/socks
    final sockPaint = Paint()..color = sockBlack;
    canvas.drawCircle(Offset(-5 * s + walk, 0), 1.6 * s, sockPaint);
    canvas.drawCircle(Offset(6 * s - walk, 0), 1.6 * s, sockPaint);

    // 5. Head and alert ears
    final headCenter = Offset(12 * s, -18 * s);
    canvas.drawOval(
      Rect.fromCenter(center: headCenter, width: 14 * s, height: 12 * s),
      _animalBodyPaint,
    );

    // White fluffy cheek tufts
    canvas.drawOval(
      Rect.fromCenter(center: Offset(headCenter.dx + 2 * s, headCenter.dy + 3 * s), width: 10 * s, height: 6 * s),
      _animalDetailPaint,
    );

    // Pointed Ears (with black backs)
    final ear1 = Path()
      ..moveTo(headCenter.dx - 3 * s, headCenter.dy - 5 * s)
      ..lineTo(headCenter.dx - 2 * s, headCenter.dy - 16 * s)
      ..lineTo(headCenter.dx + 3 * s, headCenter.dy - 5 * s)
      ..close();
    canvas.drawPath(ear1, _animalBodyPaint);
    final ear1Inner = Path()
      ..moveTo(headCenter.dx - 1.5 * s, headCenter.dy - 5 * s)
      ..lineTo(headCenter.dx - 1 * s, headCenter.dy - 13 * s)
      ..lineTo(headCenter.dx + 2 * s, headCenter.dy - 5 * s)
      ..close();
    canvas.drawPath(ear1Inner, _animalDetailPaint);

    // Cute pointed muzzle
    final muzzle = Path()
      ..moveTo(headCenter.dx + 4 * s, headCenter.dy - 1 * s)
      ..lineTo(headCenter.dx + 11 * s, headCenter.dy + 2 * s)
      ..lineTo(headCenter.dx + 4 * s, headCenter.dy + 5 * s)
      ..close();
    canvas.drawPath(muzzle, _animalDetailPaint);

    // Black nose tip
    canvas.drawCircle(Offset(headCenter.dx + 11 * s, headCenter.dy + 2 * s), 1.2 * s, sockPaint);

    // Gleaming amber eye
    _animalEyePaint.color = const Color(0xFF1E272C);
    canvas.drawCircle(Offset(headCenter.dx + 4 * s, headCenter.dy - 1.5 * s), 1.8 * s, _animalEyePaint);
    _animalEyeWhitePaint.color = Colors.white;
    canvas.drawCircle(Offset(headCenter.dx + 4.5 * s, headCenter.dy - 2.0 * s), 0.7 * s, _animalEyeWhitePaint);

    canvas.restore();
  }

  void _drawWiseOwl(Canvas canvas, ForestWildlife owl, Offset pos, double depthScale) {
    final s = depthScale;
    final isBlinking = owl.isOwlBlinking;
    final headTurn = owl.owlHeadTurn * 0.15;
    final reactBob = owl.isReacting ? -math.sin(owl.reactionProgress * math.pi) * 14.0 * s : 0.0;

    // Hitbox
    wildlifeHitBoxes?[owl.id] = Rect.fromCenter(
      center: Offset(pos.dx, pos.dy - 26 * s),
      width: 44 * s,
      height: 52 * s,
    );

    canvas.save();
    canvas.translate(pos.dx, pos.dy + reactBob);

    // 1. Mossy Stone Pedestal the owl perches upon
    _stoneBasePaint.color = isMoonlit ? const Color(0xFF37474F) : const Color(0xFF607D8B);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 4 * s), width: 36 * s, height: 16 * s),
      _stoneBasePaint,
    );
    _stoneMossPaint.color = isMoonlit ? const Color(0xFF1B5E20) : const Color(0xFF66BB6A);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-4 * s, 2 * s), width: 16 * s, height: 7 * s),
      _stoneMossPaint,
    );

    final owlBrown = isMoonlit ? const Color(0xFF4E342E) : const Color(0xFF6D4C41);
    final owlTawny = isMoonlit ? const Color(0xFF6D4C41) : const Color(0xFF8D6E63);
    final owlCream = isMoonlit ? const Color(0xFFD7CCC8) : const Color(0xFFF5F5F5);

    // 2. Plump Feathered Body
    _animalBodyPaint.color = owlBrown;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, -18 * s), width: 24 * s, height: 26 * s),
      _animalBodyPaint,
    );

    // 3. Folded Wings
    _animalDetailPaint.color = owlTawny;
    final leftWing = Path()
      ..moveTo(-8 * s, -28 * s)
      ..quadraticBezierTo(-16 * s, -18 * s, -11 * s, -6 * s)
      ..quadraticBezierTo(-6 * s, -14 * s, -6 * s, -24 * s)
      ..close();
    canvas.drawPath(leftWing, _animalDetailPaint);

    final rightWing = Path()
      ..moveTo(8 * s, -28 * s)
      ..quadraticBezierTo(16 * s, -18 * s, 11 * s, -6 * s)
      ..quadraticBezierTo(6 * s, -14 * s, 6 * s, -24 * s)
      ..close();
    canvas.drawPath(rightWing, _animalDetailPaint);

    // 4. Feathered Tawny Chest
    _animalDetailPaint.color = owlCream;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, -16 * s), width: 14 * s, height: 18 * s),
      _animalDetailPaint,
    );
    // V-shaped feather bars on chest
    final barPaint = Paint()
      ..color = owlBrown.withValues(alpha: 0.6)
      ..strokeWidth = 1.2 * s
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(-3 * s, -20 * s), Offset(0, -18 * s), barPaint);
    canvas.drawLine(Offset(0, -18 * s), Offset(3 * s, -20 * s), barPaint);
    canvas.drawLine(Offset(-3 * s, -14 * s), Offset(0, -12 * s), barPaint);
    canvas.drawLine(Offset(0, -12 * s), Offset(3 * s, -14 * s), barPaint);

    // 5. Talons gripping the stone
    final talonPaint = Paint()..color = const Color(0xFFFFB300);
    canvas.drawCircle(Offset(-5 * s, -5 * s), 2.0 * s, talonPaint);
    canvas.drawCircle(Offset(5 * s, -5 * s), 2.0 * s, talonPaint);

    // 6. Head with gentle rotation
    canvas.save();
    canvas.translate(0, -32 * s);
    canvas.rotate(headTurn);

    _animalBodyPaint.color = owlBrown;
    canvas.drawCircle(Offset.zero, 13 * s, _animalBodyPaint);

    // Feathered Ear Tufts (Horns)
    final tuft1 = Path()
      ..moveTo(-10 * s, -8 * s)
      ..lineTo(-9 * s, -19 * s)
      ..lineTo(-3 * s, -10 * s)
      ..close();
    canvas.drawPath(tuft1, _animalBodyPaint);

    final tuft2 = Path()
      ..moveTo(10 * s, -8 * s)
      ..lineTo(9 * s, -19 * s)
      ..lineTo(3 * s, -10 * s)
      ..close();
    canvas.drawPath(tuft2, _animalBodyPaint);

    // White Facial Discs
    _animalDetailPaint.color = owlCream;
    canvas.drawCircle(Offset(-4.5 * s, -1 * s), 5.5 * s, _animalDetailPaint);
    canvas.drawCircle(Offset(4.5 * s, -1 * s), 5.5 * s, _animalDetailPaint);

    // Luminous Golden Eyes (or blinking slits)
    if (isBlinking) {
      final blinkPaint = Paint()
        ..color = const Color(0xFF1E272C)
        ..strokeWidth = 1.6 * s
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(-7 * s, -1 * s), Offset(-2 * s, -1 * s), blinkPaint);
      canvas.drawLine(Offset(2 * s, -1 * s), Offset(7 * s, -1 * s), blinkPaint);
    } else {
      final goldPaint = Paint()..color = const Color(0xFFFFC107);
      canvas.drawCircle(Offset(-4.5 * s, -1 * s), 3.2 * s, goldPaint);
      canvas.drawCircle(Offset(4.5 * s, -1 * s), 3.2 * s, goldPaint);

      _animalEyePaint.color = const Color(0xFF1E272C);
      canvas.drawCircle(Offset(-4.5 * s, -1 * s), 1.8 * s, _animalEyePaint);
      canvas.drawCircle(Offset(4.5 * s, -1 * s), 1.8 * s, _animalEyePaint);

      _animalEyeWhitePaint.color = Colors.white;
      canvas.drawCircle(Offset(-3.8 * s, -1.8 * s), 0.7 * s, _animalEyeWhitePaint);
      canvas.drawCircle(Offset(5.2 * s, -1.8 * s), 0.7 * s, _animalEyeWhitePaint);
    }

    // Curved golden beak
    final beak = Path()
      ..moveTo(-1.5 * s, 1 * s)
      ..lineTo(0, 6 * s)
      ..lineTo(1.5 * s, 1 * s)
      ..close();
    canvas.drawPath(beak, Paint()..color = const Color(0xFFFFB300));

    canvas.restore();
    canvas.restore();
  }

  void _drawChipmunk(Canvas canvas, ForestWildlife chipmunk, Offset pos, double depthScale) {
    final facing = chipmunk.heading >= 0 ? 1.0 : -1.0;
    final scurry = math.sin(chipmunk.animPhase * 5.0) * 3.0 * depthScale;
    final reactJump = chipmunk.isReacting ? -math.sin(chipmunk.reactionProgress * math.pi) * 18.0 * depthScale : 0.0;
    final s = depthScale;

    // Ground shadow
    _ambientShadowPaint.color = Colors.black.withValues(alpha: isMoonlit ? 0.35 : 0.20);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy + 2), width: 28 * s, height: 10 * s),
      _ambientShadowPaint,
    );

    // Hitbox
    wildlifeHitBoxes?[chipmunk.id] = Rect.fromCenter(
      center: Offset(pos.dx, pos.dy - 16 * s),
      width: 40 * s,
      height: 38 * s,
    );

    canvas.save();
    canvas.translate(pos.dx, pos.dy + reactJump);
    if (facing < 0) {
      canvas.scale(-1.0, 1.0);
    }

    final furBase = isMoonlit ? const Color(0xFF795548) : const Color(0xFFA16838);
    final furStripeDark = const Color(0xFF3E2723);
    final furStripeLight = isMoonlit ? const Color(0xFFD7CCC8) : const Color(0xFFFFF8E1);

    // 1. S-Curved Bushy Tail with energetic flick
    final tailFlick = chipmunk.squirrelTailFlick;
    final tailPath = Path()
      ..moveTo(-8 * s, -10 * s)
      ..cubicTo(
        -18 * s + tailFlick * 6 * s, -18 * s,
        -16 * s + tailFlick * 8 * s, -28 * s,
        -8 * s + tailFlick * 5 * s, -26 * s,
      )
      ..cubicTo(
        -4 * s, -24 * s,
        -8 * s, -16 * s,
        -4 * s, -8 * s,
      )
      ..close();
    _animalBodyPaint.color = furBase;
    canvas.drawPath(tailPath, _animalBodyPaint);

    // 2. Chubby Body
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, -9 * s), width: 18 * s, height: 14 * s),
      _animalBodyPaint,
    );

    // White belly
    _animalDetailPaint.color = furStripeLight;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(2 * s, -6 * s), width: 10 * s, height: 6 * s),
      _animalDetailPaint,
    );

    // Dorsal Racing Stripes
    final darkStripePaint = Paint()
      ..color = furStripeDark
      ..strokeWidth = 1.3 * s
      ..strokeCap = StrokeCap.round;
    final lightStripePaint = Paint()
      ..color = furStripeLight
      ..strokeWidth = 1.1 * s
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(-6 * s, -12 * s), Offset(2 * s, -12 * s), darkStripePaint);
    canvas.drawLine(Offset(-6 * s, -10.5 * s), Offset(2 * s, -10.5 * s), lightStripePaint);
    canvas.drawLine(Offset(-6 * s, -9 * s), Offset(2 * s, -9 * s), darkStripePaint);

    // Feet
    final footPaint = Paint()..color = furBase;
    canvas.drawOval(Rect.fromCenter(center: Offset(-4 * s + scurry, -1 * s), width: 6 * s, height: 3.5 * s), footPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(4 * s - scurry, -1 * s), width: 6 * s, height: 3.5 * s), footPaint);

    // 3. Head & Chubby Cheek
    final headCenter = Offset(8 * s, -15 * s);
    canvas.drawCircle(headCenter, 7.5 * s, _animalBodyPaint);
    // Chubby cheek pouch
    canvas.drawCircle(Offset(headCenter.dx + 3 * s, headCenter.dy + 2 * s), 4.5 * s, _animalBodyPaint);

    // Small rounded ear
    canvas.drawCircle(Offset(headCenter.dx - 4 * s, headCenter.dy - 6 * s), 2.8 * s, _animalBodyPaint);
    canvas.drawCircle(Offset(headCenter.dx - 4 * s, headCenter.dy - 6 * s), 1.4 * s, Paint()..color = const Color(0xFFFFCDD2));

    // Eye
    _animalEyePaint.color = const Color(0xFF1E272C);
    canvas.drawCircle(Offset(headCenter.dx + 2 * s, headCenter.dy - 1.5 * s), 1.6 * s, _animalEyePaint);
    _animalEyeWhitePaint.color = Colors.white;
    canvas.drawCircle(Offset(headCenter.dx + 2.5 * s, headCenter.dy - 2.0 * s), 0.6 * s, _animalEyeWhitePaint);

    // Tiny black nose
    canvas.drawCircle(Offset(headCenter.dx + 7 * s, headCenter.dy + 1.5 * s), 0.9 * s, Paint()..color = furStripeDark);

    // 4. Shiny Golden Acorn clutched in tiny paws!
    final acornCenter = Offset(headCenter.dx + 4 * s, headCenter.dy + 6 * s);
    final acornCapPaint = Paint()..color = const Color(0xFF5D4037);
    final acornNutPaint = Paint()..color = const Color(0xFFFFB300);
    canvas.drawOval(Rect.fromCenter(center: Offset(acornCenter.dx, acornCenter.dy - 2 * s), width: 6 * s, height: 3 * s), acornCapPaint);
    canvas.drawOval(Rect.fromCenter(center: acornCenter, width: 5.5 * s, height: 6 * s), acornNutPaint);

    canvas.restore();
  }

  void _drawMossTortoise(Canvas canvas, ForestWildlife tortoise, Offset pos, double depthScale) {
    final facing = tortoise.heading >= 0 ? 1.0 : -1.0;
    final crawl = math.sin(tortoise.animPhase * 1.5) * 2.0 * depthScale;
    final reactBob = tortoise.isReacting ? -math.sin(tortoise.reactionProgress * math.pi) * 8.0 * depthScale : 0.0;
    final s = depthScale;

    // Ground shadow
    _ambientShadowPaint.color = Colors.black.withValues(alpha: isMoonlit ? 0.38 : 0.22);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy + 2), width: 44 * s, height: 16 * s),
      _ambientShadowPaint,
    );

    // Hitbox
    wildlifeHitBoxes?[tortoise.id] = Rect.fromCenter(
      center: Offset(pos.dx, pos.dy - 14 * s),
      width: 50 * s,
      height: 38 * s,
    );

    canvas.save();
    canvas.translate(pos.dx, pos.dy + reactBob);
    if (facing < 0) {
      canvas.scale(-1.0, 1.0);
    }

    final skinOlive = isMoonlit ? const Color(0xFF556B2F) : const Color(0xFF689F38);
    final shellMoss = isMoonlit ? const Color(0xFF2E4C1E) : const Color(0xFF33691E);
    final shellPlate = isMoonlit ? const Color(0xFF3E6627) : const Color(0xFF558B2F);

    // 1. Sturdy Scaly Feet
    final footPaint = Paint()..color = skinOlive;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-14 * s - crawl, -6 * s, 8 * s, 8 * s), Radius.circular(3 * s)),
      footPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(8 * s + crawl, -6 * s, 8 * s, 8 * s), Radius.circular(3 * s)),
      footPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-8 * s + crawl, -4 * s, 8 * s, 6 * s), Radius.circular(3 * s)),
      footPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(2 * s - crawl, -4 * s, 8 * s, 6 * s), Radius.circular(3 * s)),
      footPaint,
    );

    // Tiny pointed tail
    final tailPath = Path()
      ..moveTo(-16 * s, -8 * s)
      ..lineTo(-22 * s, -6 * s)
      ..lineTo(-16 * s, -4 * s)
      ..close();
    canvas.drawPath(tailPath, footPaint);

    // 2. High Domed Moss Shell
    final shellPath = Path()
      ..moveTo(-18 * s, -6 * s)
      ..cubicTo(-20 * s, -22 * s, 18 * s, -22 * s, 16 * s, -6 * s)
      ..close();
    _animalBodyPaint.color = shellMoss;
    canvas.drawPath(shellPath, _animalBodyPaint);

    // Geometric scute plates on shell
    final scutePaint = Paint()..color = shellPlate;
    canvas.drawCircle(Offset(-4 * s, -14 * s), 4.5 * s, scutePaint);
    canvas.drawCircle(Offset(5 * s, -14 * s), 4.2 * s, scutePaint);
    canvas.drawCircle(Offset(0, -9 * s), 4.0 * s, scutePaint);
    canvas.drawCircle(Offset(-11 * s, -10 * s), 3.2 * s, scutePaint);
    canvas.drawCircle(Offset(10 * s, -10 * s), 3.2 * s, scutePaint);

    // 3. Living Sprout & Flower atop the shell
    final sway = tortoise.tortoiseFlowerSway;
    final stemPaint = Paint()
      ..color = const Color(0xFF81C784)
      ..strokeWidth = 1.8 * s
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final stemPath = Path()
      ..moveTo(0, -18 * s)
      ..quadraticBezierTo(2 * s + sway * 4 * s, -24 * s, 1 * s + sway * 6 * s, -28 * s);
    canvas.drawPath(stemPath, stemPaint);

    // Tiny pink sakura flower blooming
    final bloomCenter = Offset(1 * s + sway * 6 * s, -28 * s);
    final flowerPaint = Paint()..color = const Color(0xFFFF80AB);
    canvas.drawCircle(bloomCenter, 3.2 * s, flowerPaint);
    canvas.drawCircle(bloomCenter, 1.2 * s, Paint()..color = const Color(0xFFFFEB3B));

    // 4. Serene Head & Gentle Smile
    final headCenter = Offset(18 * s, -10 * s);
    canvas.drawOval(
      Rect.fromCenter(center: headCenter, width: 11 * s, height: 9 * s),
      footPaint,
    );

    // Contented eye
    _animalEyePaint.color = const Color(0xFF1E272C);
    canvas.drawCircle(Offset(headCenter.dx + 2 * s, headCenter.dy - 1.5 * s), 1.4 * s, _animalEyePaint);
    _animalEyeWhitePaint.color = Colors.white;
    canvas.drawCircle(Offset(headCenter.dx + 2.4 * s, headCenter.dy - 2.0 * s), 0.5 * s, _animalEyeWhitePaint);

    // Gentle smile line
    final smilePaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..strokeWidth = 0.9 * s
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(headCenter.dx + 2 * s, headCenter.dy + 1.5 * s), Offset(headCenter.dx + 5 * s, headCenter.dy + 1.0 * s), smilePaint);

    canvas.restore();
  }

  void _drawKoiFish(Canvas canvas, ForestWildlife koi, Offset pos, double depthScale) {
    final s = depthScale;
    final wiggle = koi.koiSwimWiggle;
    final reactJump = koi.isReacting ? -math.sin(koi.reactionProgress * math.pi) * 12.0 * s : 0.0;

    // Hitbox
    wildlifeHitBoxes?[koi.id] = Rect.fromCenter(
      center: Offset(pos.dx, pos.dy - 4 * s),
      width: 38 * s,
      height: 26 * s,
    );

    canvas.save();
    canvas.translate(pos.dx, pos.dy + reactJump);

    final koiOrange = isMoonlit ? const Color(0xFFFF9800) : const Color(0xFFFF6D00);
    final koiWhite = isMoonlit ? const Color(0xFFECEFF1) : const Color(0xFFFFF9C4);

    // 1. Curved Body
    final bodyPath = Path()
      ..moveTo(12 * s, 0)
      ..quadraticBezierTo(2 * s, -6 * s, -10 * s, wiggle * 0.4 * s)
      ..quadraticBezierTo(0, 6 * s, 12 * s, 0)
      ..close();
    _animalBodyPaint.color = koiOrange;
    canvas.drawPath(bodyPath, _animalBodyPaint);

    // White scale shimmer
    _animalDetailPaint.color = koiWhite;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(3 * s, 0), width: 8 * s, height: 4 * s),
      _animalDetailPaint,
    );

    // 2. Fluttering Caudal Tail Fin
    final tailPath = Path()
      ..moveTo(-10 * s, wiggle * 0.4 * s)
      ..quadraticBezierTo(-16 * s + wiggle * 0.8 * s, -7 * s, -20 * s + wiggle * s, -4 * s)
      ..quadraticBezierTo(-14 * s, 0, -20 * s + wiggle * s, 4 * s)
      ..quadraticBezierTo(-16 * s + wiggle * 0.8 * s, 7 * s, -10 * s, wiggle * 0.4 * s)
      ..close();
    final finPaint = Paint()..color = koiWhite.withValues(alpha: 0.85);
    canvas.drawPath(tailPath, finPaint);

    // Pectoral fins
    canvas.drawOval(
      Rect.fromCenter(center: Offset(6 * s, -4 * s), width: 6 * s, height: 3 * s),
      finPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(6 * s, 4 * s), width: 6 * s, height: 3 * s),
      finPaint,
    );

    // Black shiny eye
    _animalEyePaint.color = const Color(0xFF1E272C);
    canvas.drawCircle(Offset(10 * s, -1.5 * s), 1.2 * s, _animalEyePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant IsometricForestPainter oldDelegate) {
    return oldDelegate.windPhase != windPhase ||
        oldDelegate.isMoonlit != isMoonlit ||
        oldDelegate.isRaining != isRaining ||
        oldDelegate.trees != trees ||
        oldDelegate.decorations != decorations ||
        oldDelegate.wildlife != wildlife ||
        oldDelegate.selectedTreeId != selectedTreeId ||
        oldDelegate.activeFocusSessionId != activeFocusSessionId ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.windGust != windGust;
  }
}

class _MeadowFlower {
  final double u;
  final double v;
  final Color petalColor;
  final Color coreColor;

  const _MeadowFlower(this.u, this.v, this.petalColor, this.coreColor);
}

class _RainDropSeed {
  final double xRatio;
  final double yOffsetRatio;
  final double speedMultiplier;
  final double length;
  final double strokeWidth;
  final double opacity;
  final bool hasSplash;

  const _RainDropSeed(
    this.xRatio,
    this.yOffsetRatio,
    this.speedMultiplier,
    this.length,
    this.strokeWidth,
    this.opacity, [
    this.hasSplash = true,
  ]);
}

class _LeafParticleSeed {
  final double u;
  final double v;
  final double speed;
  final double swayFreq;
  final double swayAmp;
  final double tumbleSpeed;
  final double size;
  final int leafType;

  const _LeafParticleSeed(
    this.u,
    this.v,
    this.speed,
    this.swayFreq,
    this.swayAmp,
    this.tumbleSpeed,
    this.size,
    this.leafType,
  );
}
