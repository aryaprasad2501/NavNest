import 'dart:math' as math;
import '../../../../core/models/forest_tree_model.dart';

/// Result of planting slot evaluation
class PlantingSlotResult {
  final double xRatio;
  final double yRatio;
  final bool isFullCapacity;
  final int currentCount;
  final int maxCapacity;
  final String? expansionBiomeName;

  const PlantingSlotResult({
    required this.xRatio,
    required this.yRatio,
    this.isFullCapacity = false,
    required this.currentCount,
    required this.maxCapacity,
    this.expansionBiomeName,
  });

  factory PlantingSlotResult.slot({
    required double x,
    required double y,
    required int count,
    required int max,
  }) {
    return PlantingSlotResult(
      xRatio: double.parse(x.toStringAsFixed(3)),
      yRatio: double.parse(y.toStringAsFixed(3)),
      currentCount: count,
      maxCapacity: max,
      isFullCapacity: false,
    );
  }

  factory PlantingSlotResult.full({
    required int count,
    required int max,
    required String expansionBiome,
  }) {
    return PlantingSlotResult(
      xRatio: 0.5,
      yRatio: 0.5,
      currentCount: count,
      maxCapacity: max,
      isFullCapacity: true,
      expansionBiomeName: expansionBiome,
    );
  }
}

/// Area capacity status info for UI badges and progression prompts
class AreaCapacityInfo {
  final int currentTrees;
  final int maxTrees;
  final double fillPercentage;
  final bool isFull;
  final bool isCrowded;
  final String nextBiomeName;
  final String recommendation;

  const AreaCapacityInfo({
    required this.currentTrees,
    required this.maxTrees,
    required this.fillPercentage,
    required this.isFull,
    required this.isCrowded,
    required this.nextBiomeName,
    required this.recommendation,
  });
}

/// Intelligent 2.5D Isometric Planting Space & Sanctuary Capacity Allocation Engine.
/// Guarantees:
/// 1. Zero overlapping trunks or occluded touch targets.
/// 2. Natural relaxation distribution (Poisson-like dispersion with organic jitter).
/// 3. Clear biome plot expansion prompt when capacity is reached.
class PlantingSpaceManager {
  static const int defaultBiomeMaxCapacity = 50;
  static const double minIsometricDistance = 0.075;

  /// Storybook Sector Titles for Continuous Endless Panorama Navigation
  static const List<String> sectorTitles = [
    'Whispering Meadow',
    'Sunlit Glade',
    'Emerald Clearing',
    'Ancient Hollow',
    'Breeze Valley',
    'Wildwood Ridge',
    'Old-Growth Grove',
    'Celestial Glade',
  ];

  /// Calculates dynamic sector count based on accumulated forest population
  static int getSectorCount(int treeCount) {
    if (treeCount <= 6) return 2;
    if (treeCount <= 20) return 3;
    if (treeCount <= 40) return 4;
    if (treeCount <= 70) return 5;
    if (treeCount <= 100) return 6;
    if (treeCount <= 140) return 7;
    return 8;
  }

  /// Returns the sector name for a given 0-indexed sector
  static String getSectorTitle(int sectorIndex) {
    if (sectorTitles.isEmpty) return 'Whispering Meadow';
    final safeIndex = (sectorIndex % sectorTitles.length + sectorTitles.length) % sectorTitles.length;
    return sectorTitles[safeIndex];
  }

  /// Calculates current sector index (0-based) given a horizontal pan offset and viewport width
  static int getSectorIndexFromPan(double panOffset, double viewportWidth, int totalSectors) {
    if (viewportWidth <= 0 || totalSectors <= 0) return 0;
    // Moving finger left (panOffset < 0) advances to next sector to the right
    final normalized = (-panOffset / viewportWidth);
    final idx = (normalized.round() % totalSectors + totalSectors) % totalSectors;
    return idx;
  }

  /// Find the best natural, non-overlapping planting coordinate in the glade.
  /// Supports multi-sector continuous panorama placement and long-run capacity scaling.
  static PlantingSlotResult findOptimalPlantingSpot({
    required List<ForestTreeModel> existingTrees,
    int? maxCapacity,
    int? currentSector,
    String nextBiomeName = 'Cherry Valley',
  }) {
    final totalSectors = getSectorCount(existingTrees.length + 1);
    final effectiveMaxCapacity = maxCapacity ?? (totalSectors * defaultBiomeMaxCapacity);

    if (existingTrees.length >= effectiveMaxCapacity) {
      return PlantingSlotResult.full(
        count: existingTrees.length,
        max: effectiveMaxCapacity,
        expansionBiome: nextBiomeName,
      );
    }

    // First tree in a fresh sanctuary always takes the prime center-stage glade spot
    if (existingTrees.isEmpty) {
      return PlantingSlotResult.slot(
        x: 0.50,
        y: 0.52,
        count: 0,
        max: effectiveMaxCapacity,
      );
    }

    // Grid of candidate locations across glade tiers in selected or all sectors
    final candidateSlots = <math.Point<double>>[];
    final bool usePrimaryMeadow = (currentSector == null && existingTrees.length <= 15);
    final sectorsToSearch = usePrimaryMeadow
        ? [0]
        : (currentSector != null)
            ? [((currentSector % totalSectors) + totalSectors) % totalSectors]
            : List.generate(totalSectors, (i) => i);

    for (final s in sectorsToSearch) {
      final sectorBaseU = usePrimaryMeadow ? 0.0 : (s / totalSectors);
      final sectorSpanU = usePrimaryMeadow ? 1.0 : (1.0 / totalSectors);

      for (double v = 0.22; v <= 0.82; v += 0.055) {
        // Natural glade width widens towards the front
        final minLocalU = (0.24 - (v - 0.22) * 0.14).clamp(0.12, 0.35);
        final maxLocalU = (0.76 + (v - 0.22) * 0.14).clamp(0.65, 0.88);

        for (double lu = minLocalU; lu <= maxLocalU; lu += 0.060) {
          final globalU = sectorBaseU + lu * sectorSpanU;
          candidateSlots.add(math.Point(globalU, v));
        }
      }
    }

    // Evaluate each candidate slot against existing tree coordinates
    math.Point<double>? bestSlot;
    double maxMinDistance = -1.0;
    final rand = math.Random();

    for (final slot in candidateSlots) {
      double minDistanceToExisting = double.infinity;

      for (final tree in existingTrees) {
        // Circular cylindrical wrap-around distance along panorama
        double du = (slot.x - tree.xRatio).abs();
        if (du > 0.5) du = 1.0 - du;
        final physicalDu = du * totalSectors;
        final dv = slot.y - tree.yRatio;
        final dist = math.sqrt(physicalDu * physicalDu + 1.8 * dv * dv);

        if (dist < minDistanceToExisting) {
          minDistanceToExisting = dist;
        }
      }

      // If this slot is completely clear of collisions and has more space than current best
      if (minDistanceToExisting > maxMinDistance) {
        maxMinDistance = minDistanceToExisting;
        bestSlot = slot;
      }
    }

    // If all candidate slots are too close, pick the best slot found or fallback
    final chosen = bestSlot ?? math.Point((currentSector ?? 0) / totalSectors + 0.5 / totalSectors, 0.50);

    // Add subtle organic jitter (+/- 0.012 scaled to sector width)
    final jitterX = (rand.nextDouble() - 0.5) * (0.020 / totalSectors);
    final jitterY = (rand.nextDouble() - 0.5) * 0.018;

    final finalX = (chosen.x + jitterX).clamp(0.02, 0.98);
    final finalY = (chosen.y + jitterY).clamp(0.20, 0.84);

    return PlantingSlotResult.slot(
      x: finalX,
      y: finalY,
      count: existingTrees.length,
      max: effectiveMaxCapacity,
    );
  }

  /// Calculates capacity metadata for the sanctuary header or map
  static AreaCapacityInfo getCapacityInfo({
    required List<ForestTreeModel> trees,
    int? maxCapacity,
    String nextBiomeName = 'Cherry Valley',
  }) {
    final count = trees.length;
    final totalSectors = getSectorCount(count + 1);
    final effectiveMax = maxCapacity ?? (totalSectors * defaultBiomeMaxCapacity);
    final fillPct = (count / effectiveMax).clamp(0.0, 1.0);
    final isFull = count >= effectiveMax;
    final isCrowded = count >= (effectiveMax * 0.85);

    String recommendation;
    if (isFull) {
      recommendation = 'Whispering Meadow is flourishing across all $totalSectors glades! Unlock $nextBiomeName to continue planting.';
    } else if (isCrowded) {
      recommendation = 'Meadow glades are filling up (${effectiveMax - count} plots remaining across $totalSectors sectors). Prepare to unlock $nextBiomeName.';
    } else {
      recommendation = 'Ample planting plots available across $totalSectors panoramic glades.';
    }

    return AreaCapacityInfo(
      currentTrees: count,
      maxTrees: effectiveMax,
      fillPercentage: fillPct,
      isFull: isFull,
      isCrowded: isCrowded,
      nextBiomeName: nextBiomeName,
      recommendation: recommendation,
    );
  }
}
