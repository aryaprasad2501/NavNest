import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/models/forest_tree_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// 3D Vector for pure-Dart software 3D rendering pipeline
class Vector3D {
  final double x;
  final double y;
  final double z;

  const Vector3D(this.x, this.y, this.z);

  Vector3D operator +(Vector3D o) => Vector3D(x + o.x, y + o.y, z + o.z);
  Vector3D operator -(Vector3D o) => Vector3D(x - o.x, y - o.y, z - o.z);
  Vector3D operator *(double s) => Vector3D(x * s, y * s, z * s);

  double dot(Vector3D o) => x * o.x + y * o.y + z * o.z;

  Vector3D cross(Vector3D o) => Vector3D(
        y * o.z - z * o.y,
        z * o.x - x * o.z,
        x * o.y - y * o.x,
      );

  double get length => math.sqrt(x * x + y * y + z * z);

  Vector3D normalized() {
    final len = length;
    if (len == 0.0) return const Vector3D(0, 0, 1);
    return Vector3D(x / len, y / len, z / len);
  }

  Vector3D rotateX(double rad) {
    final cos = math.cos(rad);
    final sin = math.sin(rad);
    return Vector3D(x, y * cos - z * sin, y * sin + z * cos);
  }

  Vector3D rotateY(double rad) {
    final cos = math.cos(rad);
    final sin = math.sin(rad);
    return Vector3D(x * cos + z * sin, y, -x * sin + z * cos);
  }

  Vector3D rotateZ(double rad) {
    final cos = math.cos(rad);
    final sin = math.sin(rad);
    return Vector3D(x * cos - y * sin, x * sin + y * cos, z);
  }
}

/// Polygonal 3D Face with normal calculation and directional lighting support
class PolygonFace3D {
  final List<Vector3D> vertices;
  final Color baseColor;
  final Vector3D normal;
  final double specular;
  final bool isFlatLit;

  PolygonFace3D(
    this.vertices,
    this.baseColor, {
    Vector3D? normal,
    this.specular = 0.2,
    this.isFlatLit = false,
  }) : normal = normal ?? _calculateNormal(vertices);

  static Vector3D _calculateNormal(List<Vector3D> v) {
    if (v.length < 3) return const Vector3D(0, 0, 1);
    final ab = v[1] - v[0];
    final ac = v[2] - v[0];
    return ab.cross(ac).normalized();
  }

  double get centerZ {
    if (vertices.isEmpty) return 0.0;
    double sum = 0.0;
    for (final v in vertices) {
      sum += v.z;
    }
    return sum / vertices.length;
  }
}

/// Mesh structure for a 3D model
class Tree3DMesh {
  final List<PolygonFace3D> faces;

  const Tree3DMesh(this.faces);
}

/// Procedural 3D Mesh Generator for all 6 sanctuary species across 5 growth stages
class Tree3DGeometryGenerator {
  static Tree3DMesh generateTree({
    required TreeSpecies species,
    required int stage,
    required bool isDark,
  }) {
    final faces = <PolygonFace3D>[];

    // 1. Pedestal Base (Floating hexagonal island)
    _addIslandPedestal(faces, isDark);

    // 2. Species & Stage-specific 3D geometry
    switch (stage) {
      case 1:
        _buildSeed3D(faces, species, isDark);
        break;
      case 2:
        _buildSprout3D(faces, species, isDark);
        break;
      case 3:
        _buildSapling3D(faces, species, isDark);
        break;
      case 4:
        _buildYoungTree3D(faces, species, isDark);
        break;
      case 5:
      default:
        _buildFullBloom3D(faces, species, isDark);
        break;
    }

    return Tree3DMesh(faces);
  }

  // --- Pedestal Base ---
  static void _addIslandPedestal(List<PolygonFace3D> faces, bool isDark) {
    const segments = 12;
    const radius = 95.0;
    const height = 18.0;
    const baseY = 80.0;

    final topColor = isDark ? const Color(0xFF1E3A2B) : const Color(0xFF5E8C61);
    final sideColor = isDark ? const Color(0xFF2E221B) : const Color(0xFF6D4C41);

    // Top surface
    final topVerts = <Vector3D>[];
    for (int i = 0; i < segments; i++) {
      final angle = (i * 2 * math.pi) / segments;
      topVerts.add(Vector3D(
        radius * math.cos(angle),
        baseY,
        radius * math.sin(angle),
      ));
    }

    final centerTop = Vector3D(0, baseY, 0);
    for (int i = 0; i < segments; i++) {
      final next = (i + 1) % segments;
      faces.add(PolygonFace3D(
        [centerTop, topVerts[i], topVerts[next]],
        topColor,
        normal: const Vector3D(0, -1, 0),
      ));
    }

    // Side cliff facets
    for (int i = 0; i < segments; i++) {
      final next = (i + 1) % segments;
      final t1 = topVerts[i];
      final t2 = topVerts[next];
      final b1 = Vector3D(t1.x * 0.88, baseY + height, t1.z * 0.88);
      final b2 = Vector3D(t2.x * 0.88, baseY + height, t2.z * 0.88);

      faces.add(PolygonFace3D(
        [t1, b1, b2, t2],
        sideColor,
      ));
    }
  }

  // --- STAGE 1: SEED ---
  static void _buildSeed3D(List<PolygonFace3D> faces, TreeSpecies species, bool isDark) {
    const seedY = 68.0;
    final seedColor = const Color(0xFFFFD166);
    final coreColor = species.themeColor;

    // Glowing faceted gem/seed
    _addIcosahedron(
      faces,
      center: const Vector3D(0, seedY, 0),
      radius: 20.0,
      color: seedColor,
      specular: 0.6,
    );
    // Inner vibrant nucleus
    _addOctahedron(
      faces,
      center: const Vector3D(0, seedY - 2, 0),
      radius: 12.0,
      color: coreColor,
      specular: 0.8,
    );

    // Earthen mound
    _addPyramidMound(faces, baseY: 80.0, radius: 36.0, height: 14.0, isDark: isDark);
  }

  // --- STAGE 2: SPROUT ---
  static void _buildSprout3D(List<PolygonFace3D> faces, TreeSpecies species, bool isDark) {
    final stemColor = isDark ? const Color(0xFF4CAF50) : const Color(0xFF66BB6A);
    final leafColor = species.themeColor;

    // Earthen mound
    _addPyramidMound(faces, baseY: 80.0, radius: 40.0, height: 16.0, isDark: isDark);

    // Stem cylinder
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, 72, 0),
      topCenter: const Vector3D(0, 15, 0),
      radius: 4.5,
      color: stemColor,
      segments: 8,
    );

    // Two 3D cotyledon leaves tilting upwards
    _add3DLeaf(
      faces,
      origin: const Vector3D(0, 18, 0),
      tip: const Vector3D(-24, 0, 10),
      width: 14.0,
      color: leafColor,
    );
    _add3DLeaf(
      faces,
      origin: const Vector3D(0, 18, 0),
      tip: const Vector3D(24, 2, -10),
      width: 14.0,
      color: leafColor,
    );

    // Tiny sprout bud on top
    _addOctahedron(
      faces,
      center: const Vector3D(0, 10, 0),
      radius: 6.0,
      color: Colors.amberAccent,
    );
  }

  // --- STAGE 3: SAPLING ---
  static void _buildSapling3D(List<PolygonFace3D> faces, TreeSpecies species, bool isDark) {
    final barkColor = isDark ? const Color(0xFF4E342E) : const Color(0xFF6D4C41);
    final foliageColor = species.themeColor;

    // Earthen mound
    _addPyramidMound(faces, baseY: 80.0, radius: 46.0, height: 18.0, isDark: isDark);

    // Trunk
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, 70, 0),
      topCenter: const Vector3D(0, -10, 0),
      radius: 7.0,
      topRadius: 4.5,
      color: barkColor,
      segments: 8,
    );

    // Primary branches
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, 10, 0),
      topCenter: const Vector3D(-18, -12, 10),
      radius: 3.5,
      color: barkColor,
      segments: 6,
    );
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, 15, 0),
      topCenter: const Vector3D(18, -8, -10),
      radius: 3.5,
      color: barkColor,
      segments: 6,
    );

    // Foliage 3D Clusters (dodecahedrons / icosahedrons)
    _addIcosahedron(
      faces,
      center: const Vector3D(0, -32, 0),
      radius: 26.0,
      color: foliageColor,
    );
    _addIcosahedron(
      faces,
      center: const Vector3D(-20, -16, 12),
      radius: 18.0,
      color: foliageColor.withValues(alpha: 0.95),
    );
    _addIcosahedron(
      faces,
      center: const Vector3D(20, -14, -10),
      radius: 19.0,
      color: foliageColor.withValues(alpha: 0.95),
    );
  }

  // --- STAGE 4: YOUNG TREE ---
  static void _buildYoungTree3D(List<PolygonFace3D> faces, TreeSpecies species, bool isDark) {
    final barkColor = isDark ? const Color(0xFF3E2723) : const Color(0xFF5D4037);
    final foliageColor = species.themeColor;

    // Earthen mound
    _addPyramidMound(faces, baseY: 80.0, radius: 52.0, height: 20.0, isDark: isDark);

    // Sturdy Trunk
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, 70, 0),
      topCenter: const Vector3D(0, -20, 0),
      radius: 11.0,
      topRadius: 6.5,
      color: barkColor,
      segments: 8,
    );

    // Multi-limb branches
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, 5, 0),
      topCenter: const Vector3D(-28, -25, 14),
      radius: 5.0,
      color: barkColor,
      segments: 6,
    );
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, 10, 0),
      topCenter: const Vector3D(30, -20, -14),
      radius: 5.0,
      color: barkColor,
      segments: 6,
    );
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, -5, 0),
      topCenter: const Vector3D(0, -42, 22),
      radius: 4.5,
      color: barkColor,
      segments: 6,
    );

    // Dense Layered Canopies
    _addIcosahedron(faces, center: const Vector3D(0, -48, 0), radius: 34.0, color: foliageColor);
    _addIcosahedron(faces, center: const Vector3D(-32, -32, 16), radius: 24.0, color: foliageColor);
    _addIcosahedron(faces, center: const Vector3D(34, -28, -16), radius: 25.0, color: foliageColor);
    _addIcosahedron(faces, center: const Vector3D(0, -50, 26), radius: 22.0, color: foliageColor);
    _addIcosahedron(faces, center: const Vector3D(0, -46, -24), radius: 22.0, color: foliageColor);
  }

  // --- STAGE 5: FULL BLOOM (SPECIES SPECIFIC) ---
  static void _buildFullBloom3D(List<PolygonFace3D> faces, TreeSpecies species, bool isDark) {
    switch (species) {
      case TreeSpecies.cherryBlossom:
        _buildCherryBlossomFullBloom(faces, isDark);
        break;
      case TreeSpecies.mountainPine:
        _buildMountainPineFullBloom(faces, isDark);
        break;
      case TreeSpecies.ancientOak:
        _buildAncientOakFullBloom(faces, isDark);
        break;
      case TreeSpecies.riverWillow:
        _buildRiverWillowFullBloom(faces, isDark);
        break;
      case TreeSpecies.goldenGinkgo:
        _buildGoldenGinkgoFullBloom(faces, isDark);
        break;
      case TreeSpecies.bonsaiJuniper:
        _buildBonsaiJuniperFullBloom(faces, isDark);
        break;
      case TreeSpecies.japaneseCedar:
        _buildJapaneseCedarFullBloom(faces, isDark);
        break;
      case TreeSpecies.jacaranda:
        _buildJacarandaFullBloom(faces, isDark);
        break;
      case TreeSpecies.bambooGrove:
        _buildBambooGroveFullBloom(faces, isDark);
        break;
      case TreeSpecies.giantSequoia:
        _buildGiantSequoiaFullBloom(faces, isDark);
        break;
      case TreeSpecies.sacredBanyan:
        _buildSacredBanyanFullBloom(faces, isDark);
        break;
      case TreeSpecies.silverBirch:
        _buildSilverBirchFullBloom(faces, isDark);
        break;
      case TreeSpecies.flameOfForest:
        _buildFlameOfForestFullBloom(faces, isDark);
        break;
      case TreeSpecies.weepingWisteria:
        _buildWeepingWisteriaFullBloom(faces, isDark);
        break;
      case TreeSpecies.ancientBaobab:
        _buildAncientBaobabFullBloom(faces, isDark);
        break;
    }
  }

  // 1. Cherry Blossom (Curved arching trunk, billowing sakura cloud puffs, floating florets)
  static void _buildCherryBlossomFullBloom(List<PolygonFace3D> faces, bool isDark) {
    final bark = isDark ? const Color(0xFF38291F) : const Color(0xFF4E342E);
    const blossomPrimary = AppColors.cherryPink;
    final blossomSoft = const Color(0xFFFFB7B2);

    _addPyramidMound(faces, baseY: 80.0, radius: 56.0, height: 20.0, isDark: isDark);

    // Twisted elegant trunk
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, 70, 0),
      topCenter: const Vector3D(-8, 15, 0),
      radius: 14.0,
      topRadius: 10.0,
      color: bark,
      segments: 8,
    );
    _addCylinder(
      faces,
      baseCenter: const Vector3D(-8, 15, 0),
      topCenter: const Vector3D(6, -28, 0),
      radius: 10.0,
      topRadius: 7.0,
      color: bark,
      segments: 8,
    );

    // Arching branches
    _addCylinder(
      faces,
      baseCenter: const Vector3D(6, -25, 0),
      topCenter: const Vector3D(-38, -48, 22),
      radius: 6.0,
      color: bark,
      segments: 6,
    );
    _addCylinder(
      faces,
      baseCenter: const Vector3D(6, -25, 0),
      topCenter: const Vector3D(42, -42, -18),
      radius: 6.0,
      color: bark,
      segments: 6,
    );
    _addCylinder(
      faces,
      baseCenter: const Vector3D(6, -25, 0),
      topCenter: const Vector3D(4, -62, 0),
      radius: 5.5,
      color: bark,
      segments: 6,
    );

    // Grand Sakura Blossom Canopies
    _addIcosahedron(faces, center: const Vector3D(4, -72, 0), radius: 40.0, color: blossomPrimary, specular: 0.35);
    _addIcosahedron(faces, center: const Vector3D(-42, -56, 24), radius: 30.0, color: blossomSoft, specular: 0.4);
    _addIcosahedron(faces, center: const Vector3D(46, -48, -20), radius: 32.0, color: blossomPrimary, specular: 0.35);
    _addIcosahedron(faces, center: const Vector3D(20, -65, 30), radius: 25.0, color: blossomSoft, specular: 0.4);
    _addIcosahedron(faces, center: const Vector3D(-24, -68, -26), radius: 26.0, color: blossomPrimary, specular: 0.35);

    // Floating Sakura Petals
    _addOctahedron(faces, center: const Vector3D(50, -10, 20), radius: 4.5, color: blossomSoft, specular: 0.6);
    _addOctahedron(faces, center: const Vector3D(-44, -15, -15), radius: 4.0, color: blossomPrimary, specular: 0.6);
    _addOctahedron(faces, center: const Vector3D(15, 30, 40), radius: 5.0, color: blossomSoft, specular: 0.6);
  }

  // 2. Mountain Pine (Tiered conical evergreen pagoda silhouettes)
  static void _buildMountainPineFullBloom(List<PolygonFace3D> faces, bool isDark) {
    final bark = isDark ? const Color(0xFF2C241E) : const Color(0xFF4A3B32);
    final pineGreen = isDark ? const Color(0xFF1B4D3E) : AppColors.sageGreen;
    final deepPine = isDark ? const Color(0xFF13382C) : const Color(0xFF2D5A46);

    _addPyramidMound(faces, baseY: 80.0, radius: 56.0, height: 20.0, isDark: isDark);

    // Tall upright trunk
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, 70, 0),
      topCenter: const Vector3D(0, -75, 0),
      radius: 13.0,
      topRadius: 4.5,
      color: bark,
      segments: 8,
    );

    // Tiered Pine Foliage Cones (4 conical pagoda layers)
    _addConeFoliage(faces, baseY: 25.0, topY: -10.0, radius: 52.0, color: deepPine);
    _addConeFoliage(faces, baseY: -5.0, topY: -38.0, radius: 42.0, color: pineGreen);
    _addConeFoliage(faces, baseY: -32.0, topY: -62.0, radius: 32.0, color: deepPine);
    _addConeFoliage(faces, baseY: -58.0, topY: -86.0, radius: 22.0, color: pineGreen);
    _addConeFoliage(faces, baseY: -82.0, topY: -104.0, radius: 12.0, color: const Color(0xFF7CB342));
  }

  // 3. Ancient Oak (Massive girth, sprawling limbs, colossal domed canopy)
  static void _buildAncientOakFullBloom(List<PolygonFace3D> faces, bool isDark) {
    final bark = isDark ? const Color(0xFF2B1D14) : const Color(0xFF3E2723);
    const oakGreen = AppColors.deepForest;
    final oakBright = isDark ? const Color(0xFF2C5E43) : const Color(0xFF388E3C);

    _addPyramidMound(faces, baseY: 80.0, radius: 62.0, height: 22.0, isDark: isDark);

    // Massive Trunk with root flares
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, 70, 0),
      topCenter: const Vector3D(0, -15, 0),
      radius: 20.0,
      topRadius: 13.0,
      color: bark,
      segments: 10,
    );

    // 4 Heavy Sprawling Limbs
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, -10, 0),
      topCenter: const Vector3D(-46, -38, 0),
      radius: 8.5,
      color: bark,
      segments: 6,
    );
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, -10, 0),
      topCenter: const Vector3D(46, -35, 0),
      radius: 8.5,
      color: bark,
      segments: 6,
    );
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, -10, 0),
      topCenter: const Vector3D(0, -40, 42),
      radius: 8.0,
      color: bark,
      segments: 6,
    );
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, -10, 0),
      topCenter: const Vector3D(0, -40, -42),
      radius: 8.0,
      color: bark,
      segments: 6,
    );

    // Colossal Majestic Canopy
    _addIcosahedron(faces, center: const Vector3D(0, -68, 0), radius: 46.0, color: oakGreen);
    _addIcosahedron(faces, center: const Vector3D(-50, -46, 0), radius: 34.0, color: oakBright);
    _addIcosahedron(faces, center: const Vector3D(50, -44, 0), radius: 34.0, color: oakGreen);
    _addIcosahedron(faces, center: const Vector3D(0, -48, 46), radius: 32.0, color: oakBright);
    _addIcosahedron(faces, center: const Vector3D(0, -48, -46), radius: 32.0, color: oakGreen);
    _addIcosahedron(faces, center: const Vector3D(0, -90, 0), radius: 28.0, color: oakBright);
  }

  // 4. River Willow (Gracefully weeping cascading foliage fronds)
  static void _buildRiverWillowFullBloom(List<PolygonFace3D> faces, bool isDark) {
    final bark = isDark ? const Color(0xFF3E3529) : const Color(0xFF5D4037);
    const willowGreen = AppColors.forestEmerald;
    final willowLime = const Color(0xFF81C784);

    _addPyramidMound(faces, baseY: 80.0, radius: 56.0, height: 20.0, isDark: isDark);

    // Trunk
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, 70, 0),
      topCenter: const Vector3D(0, -30, 0),
      radius: 13.0,
      topRadius: 8.0,
      color: bark,
      segments: 8,
    );

    // Arching canopy center
    _addIcosahedron(faces, center: const Vector3D(0, -50, 0), radius: 36.0, color: willowGreen);

    // Cascading weeping foliage tendrils
    const frondAngles = [0, 45, 90, 135, 180, 225, 270, 315];
    for (final deg in frondAngles) {
      final rad = (deg * math.pi) / 180.0;
      final x = 38.0 * math.cos(rad);
      final z = 38.0 * math.sin(rad);

      // Weeping droplet clusters
      _addCylinder(
        faces,
        baseCenter: Vector3D(x, 25, z),
        topCenter: Vector3D(x * 0.7, -42, z * 0.7),
        radius: 7.0,
        topRadius: 10.0,
        color: willowLime,
        segments: 6,
      );
    }
  }

  // 5. Golden Ginkgo (Upright elegant trunk, tiered fan-shaped honey canopies)
  static void _buildGoldenGinkgoFullBloom(List<PolygonFace3D> faces, bool isDark) {
    final bark = isDark ? const Color(0xFF42352B) : const Color(0xFF6D4C41);
    const goldenAmber = AppColors.amberWarm;
    final goldenLight = const Color(0xFFFFD166);

    _addPyramidMound(faces, baseY: 80.0, radius: 54.0, height: 20.0, isDark: isDark);

    // Slender upright trunk
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, 70, 0),
      topCenter: const Vector3D(0, -60, 0),
      radius: 11.0,
      topRadius: 5.0,
      color: bark,
      segments: 8,
    );

    // Upward-pointing branches
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, 0, 0),
      topCenter: const Vector3D(-32, -40, 16),
      radius: 5.0,
      color: bark,
      segments: 6,
    );
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, 5, 0),
      topCenter: const Vector3D(32, -35, -16),
      radius: 5.0,
      color: bark,
      segments: 6,
    );

    // Brilliant golden fan clusters
    _addIcosahedron(faces, center: const Vector3D(0, -78, 0), radius: 32.0, color: goldenLight, specular: 0.5);
    _addIcosahedron(faces, center: const Vector3D(-36, -50, 18), radius: 26.0, color: goldenAmber, specular: 0.4);
    _addIcosahedron(faces, center: const Vector3D(36, -45, -18), radius: 26.0, color: goldenLight, specular: 0.5);
    _addIcosahedron(faces, center: const Vector3D(18, -62, 28), radius: 22.0, color: goldenAmber, specular: 0.4);
    _addIcosahedron(faces, center: const Vector3D(-18, -65, -28), radius: 22.0, color: goldenLight, specular: 0.5);
  }

  // 6. Bonsai Juniper (Sculpted windswept serpentine trunk, cloud-pruned foliage pads)
  static void _buildBonsaiJuniperFullBloom(List<PolygonFace3D> faces, bool isDark) {
    final bark = isDark ? const Color(0xFF33261C) : const Color(0xFF4E342E);
    const juniperGreen = AppColors.sageGreen;
    final darkJuniper = const Color(0xFF264653);

    _addPyramidMound(faces, baseY: 80.0, radius: 52.0, height: 18.0, isDark: isDark);

    // Serpentine windswept S-curve trunk
    _addCylinder(
      faces,
      baseCenter: const Vector3D(-10, 70, 0),
      topCenter: const Vector3D(18, 28, 5),
      radius: 12.0,
      topRadius: 9.0,
      color: bark,
      segments: 8,
    );
    _addCylinder(
      faces,
      baseCenter: const Vector3D(18, 28, 5),
      topCenter: const Vector3D(-24, -12, -5),
      radius: 9.0,
      topRadius: 7.0,
      color: bark,
      segments: 8,
    );
    _addCylinder(
      faces,
      baseCenter: const Vector3D(-24, -12, -5),
      topCenter: const Vector3D(12, -45, 0),
      radius: 7.0,
      topRadius: 5.0,
      color: bark,
      segments: 8,
    );

    // Cloud-pruned pads (flattened horizontal ellipsoids)
    _addCloudPad(faces, center: const Vector3D(32, 10, 8), rx: 24, ry: 10, rz: 20, color: juniperGreen);
    _addCloudPad(faces, center: const Vector3D(-38, -22, -8), rx: 28, ry: 11, rz: 22, color: darkJuniper);
    _addCloudPad(faces, center: const Vector3D(16, -56, 0), rx: 32, ry: 12, rz: 26, color: juniperGreen);
    _addCloudPad(faces, center: const Vector3D(-8, -42, 22), rx: 20, ry: 9, rz: 18, color: darkJuniper);
  }

  // 7. Japanese Cedar (Towering conical spire, majestic straight timber trunk, steep needle tiers)
  static void _buildJapaneseCedarFullBloom(List<PolygonFace3D> faces, bool isDark) {
    final bark = isDark ? const Color(0xFF231A14) : const Color(0xFF3E2723);
    final darkCedar = isDark ? const Color(0xFF0F3B20) : const Color(0xFF1B5E20);
    final midCedar = isDark ? const Color(0xFF1B522E) : const Color(0xFF2E7D32);
    final lightCedar = isDark ? const Color(0xFF24683C) : const Color(0xFF388E3C);

    _addPyramidMound(faces, baseY: 80.0, radius: 52.0, height: 18.0, isDark: isDark);

    // Monumental straight columnar cedar trunk
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, 70, 0),
      topCenter: const Vector3D(0, -35, 0),
      radius: 13.0,
      topRadius: 6.0,
      color: bark,
      segments: 8,
    );

    // 5 Steep tapering conical tiers soaring to a sharp alpine spire
    _addConeFoliage(faces, baseY: 30.0, topY: -2.0, radius: 48.0, color: darkCedar);
    _addConeFoliage(faces, baseY: 4.0, topY: -28.0, radius: 42.0, color: darkCedar);
    _addConeFoliage(faces, baseY: -22.0, topY: -50.0, radius: 34.0, color: midCedar);
    _addConeFoliage(faces, baseY: -46.0, topY: -72.0, radius: 26.0, color: midCedar);
    _addConeFoliage(faces, baseY: -68.0, topY: -96.0, radius: 18.0, color: lightCedar);
  }

  // 8. Jacaranda (Expressive hardwood trunk with billowing indigo-lavender bloom cloud)
  static void _buildJacarandaFullBloom(List<PolygonFace3D> faces, bool isDark) {
    final bark = isDark ? const Color(0xFF2C241E) : const Color(0xFF422F26);
    const purpleDeep = Color(0xFF5E35B1);
    const purpleMain = Color(0xFF7E57C2);
    const lavenderLight = Color(0xFFB39DDB);
    const petalColor = Color(0xFFD1C4E9);

    _addPyramidMound(faces, baseY: 80.0, radius: 56.0, height: 20.0, isDark: isDark);

    // Grand spreading hardwood trunk
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, 70, 0),
      topCenter: const Vector3D(4, 18, 0),
      radius: 15.0,
      topRadius: 11.0,
      color: bark,
      segments: 8,
    );
    _addCylinder(
      faces,
      baseCenter: const Vector3D(4, 18, 0),
      topCenter: const Vector3D(-24, -22, 14),
      radius: 9.0,
      topRadius: 6.5,
      color: bark,
      segments: 6,
    );
    _addCylinder(
      faces,
      baseCenter: const Vector3D(4, 18, 0),
      topCenter: const Vector3D(28, -20, -12),
      radius: 9.0,
      topRadius: 6.5,
      color: bark,
      segments: 6,
    );
    _addCylinder(
      faces,
      baseCenter: const Vector3D(4, 18, 0),
      topCenter: const Vector3D(0, -42, 0),
      radius: 8.5,
      topRadius: 6.0,
      color: bark,
      segments: 6,
    );

    // Billowing purple-lavender foliage clouds
    _addIcosahedron(faces, center: const Vector3D(0, -64, 0), radius: 38.0, color: purpleMain, specular: 0.35);
    _addIcosahedron(faces, center: const Vector3D(-34, -40, 18), radius: 30.0, color: lavenderLight, specular: 0.4);
    _addIcosahedron(faces, center: const Vector3D(36, -38, -16), radius: 31.0, color: purpleDeep, specular: 0.35);
    _addIcosahedron(faces, center: const Vector3D(18, -58, 24), radius: 26.0, color: lavenderLight, specular: 0.4);
    _addIcosahedron(faces, center: const Vector3D(-20, -60, -22), radius: 26.0, color: purpleMain, specular: 0.35);

    // Drifting Jacaranda florets
    _addOctahedron(faces, center: const Vector3D(46, -6, 16), radius: 4.5, color: petalColor, specular: 0.55);
    _addOctahedron(faces, center: const Vector3D(-40, -8, -12), radius: 4.0, color: lavenderLight, specular: 0.55);
    _addOctahedron(faces, center: const Vector3D(12, 32, 34), radius: 4.8, color: petalColor, specular: 0.55);
  }

  // 9. Bamboo Grove (Cluster of resilient green culms with ring nodes and lanceolate leaves)
  static void _buildBambooGroveFullBloom(List<PolygonFace3D> faces, bool isDark) {
    final stalkDark = isDark ? const Color(0xFF1B4D2B) : const Color(0xFF2E7D32);
    final stalkLight = isDark ? const Color(0xFF2D6A3E) : const Color(0xFF43A047);
    final ringNode = isDark ? const Color(0xFF40916C) : const Color(0xFF81C784);
    final leafColor = isDark ? const Color(0xFF52B788) : const Color(0xFF66BB6A);

    _addPyramidMound(faces, baseY: 80.0, radius: 52.0, height: 16.0, isDark: isDark);

    // 4 Distinct Bamboo culms at staggered offsets and heights
    final culmConfigs = [
      {'x': -18.0, 'z': -10.0, 'h': 130.0, 'r': 6.0},
      {'x': 14.0, 'z': -14.0, 'h': 145.0, 'r': 6.5},
      {'x': -6.0, 'z': 16.0, 'h': 120.0, 'r': 5.5},
      {'x': 20.0, 'z': 12.0, 'h': 138.0, 'r': 6.0},
    ];

    for (final c in culmConfigs) {
      final cx = c['x']!;
      final cz = c['z']!;
      final totalH = c['h']!;
      final rad = c['r']!;

      const segments = 4;
      final segH = totalH / segments;

      for (int s = 0; s < segments; s++) {
        final bY = 70.0 - s * segH;
        final tY = bY - segH + 2.0;

        _addCylinder(
          faces,
          baseCenter: Vector3D(cx, bY, cz),
          topCenter: Vector3D(cx, tY, cz),
          radius: rad,
          topRadius: rad * 0.92,
          color: s % 2 == 0 ? stalkLight : stalkDark,
          segments: 6,
        );

        // Bamboo node ring
        _addCylinder(
          faces,
          baseCenter: Vector3D(cx, tY - 1.0, cz),
          topCenter: Vector3D(cx, tY + 1.0, cz),
          radius: rad * 1.18,
          color: ringNode,
          segments: 6,
        );
      }

      // Foliage fan atop each culm
      final topY = 70.0 - totalH;
      _addCloudPad(faces, center: Vector3D(cx, topY - 8, cz), rx: 18, ry: 7, rz: 16, color: leafColor);
      _addCloudPad(faces, center: Vector3D(cx + 8, topY - 18, cz - 6), rx: 14, ry: 6, rz: 12, color: ringNode);
    }
  }

  // 10. Giant Sequoia (Ancient cinnamon titan soaring high with conical evergreen shelves)
  static void _buildGiantSequoiaFullBloom(List<PolygonFace3D> faces, bool isDark) {
    final bark = isDark ? const Color(0xFF5D2810) : const Color(0xFF8D4004);
    final needleDark = isDark ? const Color(0xFF0F3622) : const Color(0xFF1B4332);
    final needleMid = isDark ? const Color(0xFF184E34) : const Color(0xFF2D6A4F);
    final needleLight = isDark ? const Color(0xFF246B48) : const Color(0xFF40916C);

    _addPyramidMound(faces, baseY: 80.0, radius: 64.0, height: 22.0, isDark: isDark);

    // Massive tapered cinnamon trunk
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, 70, 0),
      topCenter: const Vector3D(0, -78, 0),
      radius: 18.0,
      topRadius: 7.0,
      color: bark,
      segments: 8,
    );

    // 5 Tiered conical branch shelves
    _addConeFoliage(faces, baseY: -82.0, topY: -96.0, radius: 20.0, color: needleLight);
    _addConeFoliage(faces, baseY: -62.0, topY: -80.0, radius: 30.0, color: needleLight);
    _addConeFoliage(faces, baseY: -40.0, topY: -60.0, radius: 38.0, color: needleMid);
    _addConeFoliage(faces, baseY: -16.0, topY: -38.0, radius: 46.0, color: needleMid);
    _addConeFoliage(faces, baseY: 10.0, topY: -14.0, radius: 54.0, color: needleDark);
  }

  // 11. Sacred Banyan (Immense sprawling crown with aerial prop root pillars)
  static void _buildSacredBanyanFullBloom(List<PolygonFace3D> faces, bool isDark) {
    final bark = isDark ? const Color(0xFF2D201A) : const Color(0xFF4E342E);
    final propRootColor = isDark ? const Color(0xFF382720) : const Color(0xFF5D4037);
    final deepFoliage = isDark ? const Color(0xFF133827) : const Color(0xFF1B5E20);
    final midFoliage = isDark ? const Color(0xFF1C5239) : const Color(0xFF2E7D32);
    final sunFoliage = isDark ? const Color(0xFF2A7252) : const Color(0xFF4CAF50);

    _addPyramidMound(faces, baseY: 80.0, radius: 68.0, height: 18.0, isDark: isDark);

    // Sturdy central trunk
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, 70, 0),
      topCenter: const Vector3D(0, 10, 0),
      radius: 16.0,
      topRadius: 12.0,
      color: bark,
      segments: 8,
    );

    // Sprawling massive horizontal primary branches
    _addCylinder(faces, baseCenter: const Vector3D(0, 15, 0), topCenter: const Vector3D(-34, -8, 0), radius: 7.0, topRadius: 5.5, color: bark, segments: 6);
    _addCylinder(faces, baseCenter: const Vector3D(0, 15, 0), topCenter: const Vector3D(34, -6, 0), radius: 7.0, topRadius: 5.5, color: bark, segments: 6);
    _addCylinder(faces, baseCenter: const Vector3D(0, 18, 0), topCenter: const Vector3D(0, -6, 32), radius: 6.5, topRadius: 5.0, color: bark, segments: 6);
    _addCylinder(faces, baseCenter: const Vector3D(0, 18, 0), topCenter: const Vector3D(0, -6, -32), radius: 6.5, topRadius: 5.0, color: bark, segments: 6);

    // 4 Iconic vertical prop root pillars reaching down to the soil
    _addCylinder(faces, baseCenter: const Vector3D(-32, 70, 0), topCenter: const Vector3D(-32, -6, 0), radius: 4.5, color: propRootColor, segments: 6);
    _addCylinder(faces, baseCenter: const Vector3D(32, 70, 0), topCenter: const Vector3D(32, -4, 0), radius: 4.5, color: propRootColor, segments: 6);
    _addCylinder(faces, baseCenter: const Vector3D(0, 70, 30), topCenter: const Vector3D(0, -4, 30), radius: 4.0, color: propRootColor, segments: 6);
    _addCylinder(faces, baseCenter: const Vector3D(0, 70, -30), topCenter: const Vector3D(0, -4, -30), radius: 4.0, color: propRootColor, segments: 6);

    // Expansive horizontal domed canopy
    _addIcosahedron(faces, center: const Vector3D(0, -36, 0), radius: 36.0, color: sunFoliage);
    _addIcosahedron(faces, center: const Vector3D(-34, -22, 4), radius: 28.0, color: midFoliage);
    _addIcosahedron(faces, center: const Vector3D(34, -20, -4), radius: 28.0, color: midFoliage);
    _addIcosahedron(faces, center: const Vector3D(4, -22, 32), radius: 26.0, color: deepFoliage);
    _addIcosahedron(faces, center: const Vector3D(-4, -22, -32), radius: 26.0, color: deepFoliage);
    _addIcosahedron(faces, center: const Vector3D(0, -48, 0), radius: 26.0, color: sunFoliage);
  }

  // 12. Silver Birch (Slender chalk-white trunk with delicate lime foliage)
  static void _buildSilverBirchFullBloom(List<PolygonFace3D> faces, bool isDark) {
    final chalkWhite = isDark ? const Color(0xFFCFD8DC) : const Color(0xFFECEFF1);
    final darkBand = const Color(0xFF263238);
    final limeFoliage = isDark ? const Color(0xFF437A46) : const Color(0xFF7CB342);
    final sunLime = isDark ? const Color(0xFF529856) : const Color(0xFF9CCC65);

    _addPyramidMound(faces, baseY: 80.0, radius: 48.0, height: 16.0, isDark: isDark);

    // Slender white trunk
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, 70, 0),
      topCenter: const Vector3D(0, -30, 0),
      radius: 7.0,
      topRadius: 4.5,
      color: chalkWhite,
      segments: 8,
    );

    // Distinct dark lenticel bands on bark
    _addCylinder(faces, baseCenter: const Vector3D(0, 40, 0), topCenter: const Vector3D(0, 37, 0), radius: 7.2, color: darkBand, segments: 8);
    _addCylinder(faces, baseCenter: const Vector3D(0, 10, 0), topCenter: const Vector3D(0, 7, 0), radius: 6.2, color: darkBand, segments: 8);
    _addCylinder(faces, baseCenter: const Vector3D(0, -15, 0), topCenter: const Vector3D(0, -18, 0), radius: 5.2, color: darkBand, segments: 8);

    // Airy fluttering cloud clusters
    _addIcosahedron(faces, center: const Vector3D(0, -56, 0), radius: 26.0, color: sunLime);
    _addIcosahedron(faces, center: const Vector3D(-22, -40, 12), radius: 22.0, color: limeFoliage);
    _addIcosahedron(faces, center: const Vector3D(22, -38, -12), radius: 22.0, color: limeFoliage);
    _addIcosahedron(faces, center: const Vector3D(8, -44, 20), radius: 20.0, color: sunLime);
    _addIcosahedron(faces, center: const Vector3D(-8, -42, -20), radius: 20.0, color: limeFoliage);
  }

  // 13. Flame of the Forest (Knotted charcoal trunk with blazing vermilion blooms)
  static void _buildFlameOfForestFullBloom(List<PolygonFace3D> faces, bool isDark) {
    final charcoalBark = isDark ? const Color(0xFF1E272C) : const Color(0xFF37474F);
    final crimsonBase = isDark ? const Color(0xFF881B1B) : const Color(0xFFD32F2F);
    final vermilionMid = isDark ? const Color(0xFFBF360C) : const Color(0xFFFF5722);
    final flameGold = isDark ? const Color(0xFFE65100) : const Color(0xFFFF9800);

    _addPyramidMound(faces, baseY: 80.0, radius: 52.0, height: 18.0, isDark: isDark);

    // Gnarled dark trunk with spreading branches
    _addCylinder(faces, baseCenter: const Vector3D(0, 70, 0), topCenter: const Vector3D(0, -10, 0), radius: 11.0, topRadius: 7.0, color: charcoalBark, segments: 8);
    _addCylinder(faces, baseCenter: const Vector3D(0, 0, 0), topCenter: const Vector3D(-24, -28, 12), radius: 5.5, color: charcoalBark, segments: 6);
    _addCylinder(faces, baseCenter: const Vector3D(0, 0, 0), topCenter: const Vector3D(26, -24, -12), radius: 5.5, color: charcoalBark, segments: 6);

    // Blazing floral clusters
    _addIcosahedron(faces, center: const Vector3D(0, -48, 0), radius: 30.0, color: vermilionMid);
    _addIcosahedron(faces, center: const Vector3D(-26, -34, 14), radius: 24.0, color: crimsonBase);
    _addIcosahedron(faces, center: const Vector3D(28, -32, -14), radius: 24.0, color: flameGold);
    _addIcosahedron(faces, center: const Vector3D(0, -66, 0), radius: 22.0, color: flameGold);
  }

  // 14. Weeping Wisteria (Graceful hanging violet-lilac blossom cascades)
  static void _buildWeepingWisteriaFullBloom(List<PolygonFace3D> faces, bool isDark) {
    final vineBark = isDark ? const Color(0xFF2E241E) : const Color(0xFF4E342E);
    final darkViolet = isDark ? const Color(0xFF4A148C) : const Color(0xFF6A1B9A);
    final royalLilac = isDark ? const Color(0xFF7B1FA2) : const Color(0xFF9C27B0);
    final paleAmethyst = isDark ? const Color(0xFFBA68C8) : const Color(0xFFCE93D8);

    _addPyramidMound(faces, baseY: 80.0, radius: 50.0, height: 18.0, isDark: isDark);

    // Twisted liana stem
    _addCylinder(faces, baseCenter: const Vector3D(0, 70, 0), topCenter: const Vector3D(0, -15, 0), radius: 9.0, topRadius: 6.0, color: vineBark, segments: 8);

    // Horizontal trellis boughs
    _addCylinder(faces, baseCenter: const Vector3D(0, -5, 0), topCenter: const Vector3D(-30, -22, 10), radius: 5.0, color: vineBark, segments: 6);
    _addCylinder(faces, baseCenter: const Vector3D(0, -5, 0), topCenter: const Vector3D(30, -20, -10), radius: 5.0, color: vineBark, segments: 6);
    _addCylinder(faces, baseCenter: const Vector3D(0, -5, 0), topCenter: const Vector3D(10, -22, 28), radius: 4.5, color: vineBark, segments: 6);
    _addCylinder(faces, baseCenter: const Vector3D(0, -5, 0), topCenter: const Vector3D(-10, -22, -28), radius: 4.5, color: vineBark, segments: 6);

    // Crown canopy dome
    _addIcosahedron(faces, center: const Vector3D(0, -42, 0), radius: 28.0, color: royalLilac);

    // Cascading pendulous racemes hanging downwards
    _addCylinder(faces, baseCenter: const Vector3D(-28, -18, 10), topCenter: const Vector3D(-28, 22, 10), radius: 6.0, topRadius: 2.0, color: paleAmethyst, segments: 6);
    _addCylinder(faces, baseCenter: const Vector3D(28, -16, -10), topCenter: const Vector3D(28, 24, -10), radius: 6.0, topRadius: 2.0, color: darkViolet, segments: 6);
    _addCylinder(faces, baseCenter: const Vector3D(10, -18, 26), topCenter: const Vector3D(10, 20, 26), radius: 5.5, topRadius: 2.0, color: paleAmethyst, segments: 6);
    _addCylinder(faces, baseCenter: const Vector3D(-10, -18, -26), topCenter: const Vector3D(-10, 20, -26), radius: 5.5, topRadius: 2.0, color: royalLilac, segments: 6);
  }

  // 15. Ancient Baobab (Mammoth swollen bottle trunk crowned with compact acacia tufts)
  static void _buildAncientBaobabFullBloom(List<PolygonFace3D> faces, bool isDark) {
    final baobabBark = isDark ? const Color(0xFF3E2D27) : const Color(0xFF6D4C41);
    final crownFoliage = isDark ? const Color(0xFF1E482A) : const Color(0xFF388E3C);
    final sunFoliage = isDark ? const Color(0xFF2E633D) : const Color(0xFF66BB6A);

    _addPyramidMound(faces, baseY: 80.0, radius: 66.0, height: 22.0, isDark: isDark);

    // Mammoth bulbous bottle trunk
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, 70, 0),
      topCenter: const Vector3D(0, 15, 0),
      radius: 24.0,
      topRadius: 27.0,
      color: baobabBark,
      segments: 10,
    );
    _addCylinder(
      faces,
      baseCenter: const Vector3D(0, 15, 0),
      topCenter: const Vector3D(0, -32, 0),
      radius: 27.0,
      topRadius: 17.0,
      color: baobabBark,
      segments: 10,
    );

    // Root-like branches radiating from top
    _addCylinder(faces, baseCenter: const Vector3D(0, -30, 0), topCenter: const Vector3D(-26, -56, 12), radius: 7.0, topRadius: 4.5, color: baobabBark, segments: 6);
    _addCylinder(faces, baseCenter: const Vector3D(0, -30, 0), topCenter: const Vector3D(28, -54, -12), radius: 7.0, topRadius: 4.5, color: baobabBark, segments: 6);
    _addCylinder(faces, baseCenter: const Vector3D(0, -30, 0), topCenter: const Vector3D(0, -62, 0), radius: 8.0, topRadius: 5.0, color: baobabBark, segments: 6);

    // Compact starry acacia cushions
    _addIcosahedron(faces, center: const Vector3D(0, -72, 0), radius: 20.0, color: sunFoliage);
    _addIcosahedron(faces, center: const Vector3D(-28, -62, 14), radius: 17.0, color: crownFoliage);
    _addIcosahedron(faces, center: const Vector3D(30, -60, -14), radius: 17.0, color: crownFoliage);
  }

  // --- Geometry Primitives Helpers ---

  static void _addPyramidMound(
    List<PolygonFace3D> faces, {
    required double baseY,
    required double radius,
    required double height,
    required bool isDark,
  }) {
    final soilColor = isDark ? const Color(0xFF2A2019) : const Color(0xFF5D4037);
    const segments = 8;
    final topCenter = Vector3D(0, baseY - height, 0);

    for (int i = 0; i < segments; i++) {
      final a1 = (i * 2 * math.pi) / segments;
      final a2 = ((i + 1) * 2 * math.pi) / segments;
      final v1 = Vector3D(radius * math.cos(a1), baseY, radius * math.sin(a1));
      final v2 = Vector3D(radius * math.cos(a2), baseY, radius * math.sin(a2));

      faces.add(PolygonFace3D([topCenter, v1, v2], soilColor));
    }
  }

  static void _addCylinder(
    List<PolygonFace3D> faces, {
    required Vector3D baseCenter,
    required Vector3D topCenter,
    required double radius,
    double? topRadius,
    required Color color,
    int segments = 8,
  }) {
    final tRadius = topRadius ?? radius;
    final dir = (topCenter - baseCenter).normalized();
    final up = dir.y.abs() > 0.9 ? const Vector3D(1, 0, 0) : const Vector3D(0, 1, 0);
    final side1 = dir.cross(up).normalized();
    final side2 = dir.cross(side1).normalized();

    final baseVerts = <Vector3D>[];
    final topVerts = <Vector3D>[];

    for (int i = 0; i < segments; i++) {
      final a = (i * 2 * math.pi) / segments;
      final offset = side1 * (math.cos(a) * radius) + side2 * (math.sin(a) * radius);
      final topOffset = side1 * (math.cos(a) * tRadius) + side2 * (math.sin(a) * tRadius);

      baseVerts.add(baseCenter + offset);
      topVerts.add(topCenter + topOffset);
    }

    for (int i = 0; i < segments; i++) {
      final next = (i + 1) % segments;
      faces.add(PolygonFace3D(
        [baseVerts[i], topVerts[i], topVerts[next], baseVerts[next]],
        color,
      ));
    }
  }

  static void _add3DLeaf(
    List<PolygonFace3D> faces, {
    required Vector3D origin,
    required Vector3D tip,
    required double width,
    required Color color,
  }) {
    final dir = (tip - origin).normalized();
    final side = dir.cross(const Vector3D(0, 1, 0)).normalized() * (width / 2);
    final mid = origin + (tip - origin) * 0.5;

    final left = mid + side;
    final right = mid - side;

    faces.add(PolygonFace3D([origin, left, tip], color));
    faces.add(PolygonFace3D([origin, tip, right], color));
  }

  static void _addConeFoliage(
    List<PolygonFace3D> faces, {
    required double baseY,
    required double topY,
    required double radius,
    required Color color,
    int segments = 8,
  }) {
    final top = Vector3D(0, topY, 0);
    final baseVerts = <Vector3D>[];

    for (int i = 0; i < segments; i++) {
      final a = (i * 2 * math.pi) / segments;
      baseVerts.add(Vector3D(radius * math.cos(a), baseY, radius * math.sin(a)));
    }

    for (int i = 0; i < segments; i++) {
      final next = (i + 1) % segments;
      faces.add(PolygonFace3D([top, baseVerts[i], baseVerts[next]], color));
    }
  }

  static void _addCloudPad(
    List<PolygonFace3D> faces, {
    required Vector3D center,
    required double rx,
    required double ry,
    required double rz,
    required Color color,
  }) {
    const latCount = 4;
    const lonCount = 8;

    final grid = <List<Vector3D>>[];

    for (int i = 0; i <= latCount; i++) {
      final lat = (i * math.pi) / latCount;
      final row = <Vector3D>[];
      for (int j = 0; j < lonCount; j++) {
        final lon = (j * 2 * math.pi) / lonCount;
        row.add(Vector3D(
          center.x + rx * math.sin(lat) * math.cos(lon),
          center.y + ry * math.cos(lat),
          center.z + rz * math.sin(lat) * math.sin(lon),
        ));
      }
      grid.add(row);
    }

    for (int i = 0; i < latCount; i++) {
      for (int j = 0; j < lonCount; j++) {
        final nextJ = (j + 1) % lonCount;
        final v1 = grid[i][j];
        final v2 = grid[i + 1][j];
        final v3 = grid[i + 1][nextJ];
        final v4 = grid[i][nextJ];

        faces.add(PolygonFace3D([v1, v2, v3, v4], color));
      }
    }
  }

  static void _addOctahedron(
    List<PolygonFace3D> faces, {
    required Vector3D center,
    required double radius,
    required Color color,
    double specular = 0.3,
  }) {
    final pX = center + Vector3D(radius, 0, 0);
    final nX = center + Vector3D(-radius, 0, 0);
    final pY = center + Vector3D(0, -radius, 0);
    final nY = center + Vector3D(0, radius, 0);
    final pZ = center + Vector3D(0, 0, radius);
    final nZ = center + Vector3D(0, 0, -radius);

    faces.add(PolygonFace3D([pY, pX, pZ], color, specular: specular));
    faces.add(PolygonFace3D([pY, pZ, nX], color, specular: specular));
    faces.add(PolygonFace3D([pY, nX, nZ], color, specular: specular));
    faces.add(PolygonFace3D([pY, nZ, pX], color, specular: specular));

    faces.add(PolygonFace3D([nY, pZ, pX], color, specular: specular));
    faces.add(PolygonFace3D([nY, nX, pZ], color, specular: specular));
    faces.add(PolygonFace3D([nY, nZ, nX], color, specular: specular));
    faces.add(PolygonFace3D([nY, pX, nZ], color, specular: specular));
  }

  static void _addIcosahedron(
    List<PolygonFace3D> faces, {
    required Vector3D center,
    required double radius,
    required Color color,
    double specular = 0.25,
  }) {
    final phi = (1.0 + math.sqrt(5.0)) / 2.0;
    final a = radius / math.sqrt(1.0 + phi * phi);
    final b = a * phi;

    final verts = [
      Vector3D(-a, b, 0),
      Vector3D(a, b, 0),
      Vector3D(-a, -b, 0),
      Vector3D(a, -b, 0),
      Vector3D(0, -a, b),
      Vector3D(0, a, b),
      Vector3D(0, -a, -b),
      Vector3D(0, a, -b),
      Vector3D(b, 0, -a),
      Vector3D(b, 0, a),
      Vector3D(-b, 0, -a),
      Vector3D(-b, 0, a),
    ].map((v) => center + v).toList();

    const triIndices = [
      [0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
      [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
      [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
      [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1],
    ];

    for (final tri in triIndices) {
      faces.add(PolygonFace3D(
        [verts[tri[0]], verts[tri[1]], verts[tri[2]]],
        color,
        specular: specular,
      ));
    }
  }
}

/// Interactive 3D Tree Viewer with 360° Touch Orbital Controls, Lighting, and Stage Preview
class InteractiveTree3DViewer extends StatefulWidget {
  final TreeSpecies species;
  final int initialStage;
  final bool isDark;
  final double height;
  final bool showStageSelector;
  final bool autoSpin;
  final ValueChanged<int>? onStageChanged;

  const InteractiveTree3DViewer({
    super.key,
    required this.species,
    this.initialStage = 5,
    this.isDark = false,
    this.height = 320,
    this.showStageSelector = true,
    this.autoSpin = true,
    this.onStageChanged,
  });

  @override
  State<InteractiveTree3DViewer> createState() => _InteractiveTree3DViewerState();
}

class _InteractiveTree3DViewerState extends State<InteractiveTree3DViewer>
    with SingleTickerProviderStateMixin {
  late int _currentStage;
  late Tree3DMesh _mesh;

  // Orbital Camera state
  double _yaw = 0.5; // horizontal rotation in radians
  double _pitch = 0.22; // vertical angle in radians
  double _scale = 1.0;

  bool _isAutoSpinning = true;
  late AnimationController _spinController;

  // Touch Drag Tracking
  double _lastFocalX = 0;
  double _lastFocalY = 0;
  double _baseScale = 1.0;

  @override
  void initState() {
    super.initState();
    _currentStage = widget.initialStage.clamp(1, 5);
    _rebuildMesh();
    _isAutoSpinning = widget.autoSpin;

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );

    if (_isAutoSpinning) {
      _spinController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant InteractiveTree3DViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.species != widget.species ||
        oldWidget.isDark != widget.isDark ||
        oldWidget.initialStage != widget.initialStage) {
      _currentStage = widget.initialStage.clamp(1, 5);
      _rebuildMesh();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _rebuildMesh() {
    _mesh = Tree3DGeometryGenerator.generateTree(
      species: widget.species,
      stage: _currentStage,
      isDark: widget.isDark,
    );
  }

  void _resetCamera() {
    setState(() {
      _yaw = 0.5;
      _pitch = 0.22;
      _scale = 1.0;
      _isAutoSpinning = true;
      _spinController.reset();
      _spinController.repeat();
    });
  }

  void _toggleAutoSpin() {
    setState(() {
      if (_isAutoSpinning) {
        _yaw = (_yaw + _spinController.value * 2 * math.pi) % (2 * math.pi);
        _spinController.stop();
        _isAutoSpinning = false;
      } else {
        _spinController.reset();
        _spinController.repeat();
        _isAutoSpinning = true;
      }
    });
  }

  void _setStage(int stage) {
    if (_currentStage == stage) return;
    setState(() {
      _currentStage = stage;
      _rebuildMesh();
    });
    widget.onStageChanged?.call(stage);
  }

  @override
  Widget build(BuildContext context) {
    final bgGlow = widget.isDark
        ? const Color(0xFF1B3828).withValues(alpha: 0.4)
        : widget.species.themeColor.withValues(alpha: 0.12);

    return Container(
      width: double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : AppColors.cardSurface,
        borderRadius: AppRadius.roundedXL,
        border: Border.all(
          color: widget.isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          width: 1.5,
        ),
        boxShadow: AppShadows.softCard,
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Background ambient circular radial glow
          Center(
            child: Container(
              width: widget.height * 0.75,
              height: widget.height * 0.75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgGlow,
              ),
            ),
          ),

          // 3D Canvas with Gesture Detector
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (details) {
                _lastFocalX = details.focalPoint.dx;
                _lastFocalY = details.focalPoint.dy;
                _baseScale = _scale;
                if (_isAutoSpinning) {
                  _yaw = (_yaw + _spinController.value * 2 * math.pi) % (2 * math.pi);
                  _spinController.stop();
                  setState(() => _isAutoSpinning = false);
                }
              },
              onScaleUpdate: (details) {
                final dx = details.focalPoint.dx - _lastFocalX;
                final dy = details.focalPoint.dy - _lastFocalY;
                _lastFocalX = details.focalPoint.dx;
                _lastFocalY = details.focalPoint.dy;

                setState(() {
                  _yaw += dx * 0.012;
                  _pitch = (_pitch - dy * 0.012).clamp(-0.8, 0.9);
                  _scale = (_baseScale * details.scale).clamp(0.65, 2.4);
                });
              },
              child: AnimatedBuilder(
                animation: _spinController,
                builder: (context, child) {
                  final effectiveYaw = _yaw + (_isAutoSpinning ? _spinController.value * 2 * math.pi : 0.0);
                  return CustomPaint(
                    painter: Tree3DPainter(
                      mesh: _mesh,
                      yaw: effectiveYaw,
                      pitch: _pitch,
                      zoom: _scale,
                      isDark: widget.isDark,
                    ),
                  );
                },
              ),
            ),
          ),

          // Top Left: 360° Interactive Badge
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (widget.isDark ? AppColors.darkCard : Colors.white).withValues(alpha: 0.92),
                borderRadius: AppRadius.roundedFull,
                border: Border.all(
                  color: widget.isDark ? AppColors.darkBorder : AppColors.borderSubtle,
                ),
                boxShadow: AppShadows.softCard,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.threed_rotation_rounded,
                    size: 16,
                    color: widget.species.themeColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '360° Real 3D View',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Right: Controls (Auto-spin toggle & Reset camera)
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              children: [
                IconButton.filledTonal(
                  icon: Icon(
                    _isAutoSpinning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  tooltip: _isAutoSpinning ? 'Pause Rotation' : 'Auto Rotate',
                  visualDensity: VisualDensity.compact,
                  onPressed: _toggleAutoSpin,
                ),
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  tooltip: 'Reset View',
                  visualDensity: VisualDensity.compact,
                  onPressed: _resetCamera,
                ),
              ],
            ),
          ),

          // Bottom Hint & Optional Stage Selector
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gesture hint
                Text(
                  'Drag to rotate 360° • Pinch to zoom',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
                if (widget.showStageSelector) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    decoration: BoxDecoration(
                      color: (widget.isDark ? AppColors.darkCard : Colors.white).withValues(alpha: 0.94),
                      borderRadius: AppRadius.roundedFull,
                      border: Border.all(
                        color: widget.isDark ? AppColors.darkBorder : AppColors.borderSubtle,
                      ),
                      boxShadow: AppShadows.softCard,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStagePill(1, 'Seed 🌱'),
                        _buildStagePill(2, 'Sprout 🌿'),
                        _buildStagePill(3, 'Sapling 🪴'),
                        _buildStagePill(4, 'Young 🌳'),
                        _buildStagePill(5, 'Bloom 🌸'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStagePill(int stage, String label) {
    final isSelected = _currentStage == stage;
    return GestureDetector(
      onTap: () => _setStage(stage),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? widget.species.themeColor : Colors.transparent,
          borderRadius: AppRadius.roundedFull,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (widget.isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Pure-Dart Perspective 3D Painter with Directional Lighting and Depth Sorting
class Tree3DPainter extends CustomPainter {
  final Tree3DMesh mesh;
  final double yaw;
  final double pitch;
  final double zoom;
  final bool isDark;

  // Directional Light Source from top-right-front
  static final Vector3D _lightDir = const Vector3D(0.45, -0.75, -0.48).normalized();
  static const double _focalLength = 480.0;

  Tree3DPainter({
    required this.mesh,
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.52;

    // Contact drop shadow on ground
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 96 * zoom), width: 170 * zoom, height: 44 * zoom),
      shadowPaint,
    );

    // 1. Transform vertices to camera space
    final transformedFaces = <_TransformedFace>[];

    for (final face in mesh.faces) {
      final rotatedVerts = <Vector3D>[];
      for (final v in face.vertices) {
        // Rotate Pitch (X axis) then Yaw (Y axis)
        final rv = v.rotateX(pitch).rotateY(yaw);
        rotatedVerts.add(rv);
      }

      // Calculate camera normal
      final cameraNormal = face.normal.rotateX(pitch).rotateY(yaw);

      // Average depth for painter's depth sorting
      double zSum = 0;
      for (final v in rotatedVerts) {
        zSum += v.z;
      }
      final avgZ = zSum / rotatedVerts.length;

      transformedFaces.add(_TransformedFace(
        verts: rotatedVerts,
        baseColor: face.baseColor,
        normal: cameraNormal,
        avgZ: avgZ,
        specular: face.specular,
      ));
    }

    // 2. Depth sort (Painter's algorithm: draw farthest Z first, nearest Z last)
    transformedFaces.sort((a, b) => a.avgZ.compareTo(b.avgZ));

    // 3. Render shaded polygon facets
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = Colors.black.withValues(alpha: 0.08);

    for (final face in transformedFaces) {
      // 2D Perspective Projection
      final points = <Offset>[];
      for (final v in face.verts) {
        final scale = (_focalLength / (_focalLength + v.z)) * zoom;
        points.add(Offset(
          cx + v.x * scale,
          cy + v.y * scale,
        ));
      }

      if (points.length < 3) continue;

      // Lighting computation: Ambient + Diffuse Lambertian
      final diff = math.max(0.0, face.normal.dot(_lightDir));
      final ambient = isDark ? 0.38 : 0.48;
      final intensity = (ambient + diff * (1.0 - ambient)).clamp(0.0, 1.0);

      final shadedColor = _applyLighting(face.baseColor, intensity, face.specular, diff);

      fillPaint.color = shadedColor;

      final path = Path()..moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.close();

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
    }
  }

  Color _applyLighting(Color base, double intensity, double specular, double diff) {
    int r = (base.r * 255 * intensity).clamp(0, 255).toInt();
    int g = (base.g * 255 * intensity).clamp(0, 255).toInt();
    int b = (base.b * 255 * intensity).clamp(0, 255).toInt();

    if (diff > 0.8 && specular > 0) {
      final highlight = ((diff - 0.8) * 5.0 * specular * 100).toInt();
      r = (r + highlight).clamp(0, 255);
      g = (g + highlight).clamp(0, 255);
      b = (b + highlight).clamp(0, 255);
    }

    return Color.fromARGB((base.a * 255.0).round() & 0xff, r, g, b);
  }

  @override
  bool shouldRepaint(covariant Tree3DPainter oldDelegate) {
    return oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.zoom != zoom ||
        oldDelegate.mesh != mesh ||
        oldDelegate.isDark != isDark;
  }
}

class _TransformedFace {
  final List<Vector3D> verts;
  final Color baseColor;
  final Vector3D normal;
  final double avgZ;
  final double specular;

  const _TransformedFace({
    required this.verts,
    required this.baseColor,
    required this.normal,
    required this.avgZ,
    required this.specular,
  });
}
