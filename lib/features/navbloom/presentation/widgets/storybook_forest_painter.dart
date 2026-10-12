import 'package:flutter/material.dart';

/// Highly optimized, beautiful CustomPainter creating the immersive Storybook NavBloom Forest.
/// Supports both vibrant Storybook Day and serene Moonlit Night mode.
/// Zero external bitmap bloat; hardware accelerated on Vivo Y28.
class StorybookForestPainter extends CustomPainter {
  final bool isDark;

  StorybookForestPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // 1. SKY GRADIENT
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [
                Color(0xFF0A181C), // Deep midnight blue-green
                Color(0xFF0F2622),
                Color(0xFF16382E),
              ]
            : const [
                Color(0xFFE4F0F3), // Crisp morning mist sky
                Color(0xFFF9F6ED), // Soft sunlit warmth
                Color(0xFFE5EFE2), // Emerald horizon
              ],
        stops: const [0.0, 0.45, 0.75],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // Moon / Sun in sky
    final celestialPaint = Paint()
      ..color = isDark
          ? const Color(0xFFFFFAD6).withValues(alpha: 0.85)
          : const Color(0xFFFFF2D0).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.78, h * 0.12), isDark ? 22 : 36, celestialPaint);

    if (isDark) {
      // Crescent inner cutout
      final moonShadow = Paint()
        ..color = const Color(0xFF0B191D)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(w * 0.74, h * 0.11), 18, moonShadow);
    }

    // 2. DISTANT MOUNTAIN PEAKS
    final mountainPaint = Paint()
      ..color = isDark ? const Color(0xFF132B25) : const Color(0xFFBFD8C9)
      ..style = PaintingStyle.fill;
    final mountainPath = Path()
      ..moveTo(0, h * 0.28)
      ..lineTo(w * 0.22, h * 0.18)
      ..lineTo(w * 0.45, h * 0.29)
      ..lineTo(w * 0.68, h * 0.20)
      ..lineTo(w * 0.88, h * 0.32)
      ..lineTo(w, h * 0.26)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(mountainPath, mountainPaint);

    // 3. MIDGROUND FOREST CANOPY RIDGE
    final ridgePaint = Paint()
      ..color = isDark ? const Color(0xFF1B3D30) : const Color(0xFFA1C7A8)
      ..style = PaintingStyle.fill;
    final ridgePath = Path()
      ..moveTo(0, h * 0.38)
      ..quadraticBezierTo(w * 0.3, h * 0.30, w * 0.55, h * 0.37)
      ..quadraticBezierTo(w * 0.8, h * 0.42, w, h * 0.34)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(ridgePath, ridgePaint);

    // 4. ROCK CLIFF & WATERFALL CASCADE
    final cliffPaint = Paint()
      ..color = isDark ? const Color(0xFF1F352E) : const Color(0xFF7D9E87)
      ..style = PaintingStyle.fill;
    final cliffPath = Path()
      ..moveTo(w * 0.36, h * 0.34)
      ..lineTo(w * 0.52, h * 0.34)
      ..lineTo(w * 0.54, h * 0.56)
      ..lineTo(w * 0.34, h * 0.56)
      ..close();
    canvas.drawPath(cliffPath, cliffPaint);

    // Waterfall stream
    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [
                Color(0xFF386566),
                Color(0xFF5A9E9C),
                Color(0xFF86D6D2),
              ]
            : const [
                Color(0xFFCEECF0),
                Color(0xFF90D0DE),
                Color(0xFFB5E4EC),
              ],
      ).createShader(Rect.fromLTWH(w * 0.42, h * 0.34, w * 0.08, h * 0.24));
    final waterfall = Path()
      ..moveTo(w * 0.43, h * 0.34)
      ..lineTo(w * 0.47, h * 0.34)
      ..lineTo(w * 0.49, h * 0.55)
      ..lineTo(w * 0.41, h * 0.55)
      ..close();
    canvas.drawPath(waterfall, waterPaint);

    // 5. FOREGROUND LUSH LAWN & ROLLING MEADOW
    final meadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [
                Color(0xFF1A3828),
                Color(0xFF142B20),
                Color(0xFF0F2218),
              ]
            : const [
                Color(0xFFB5D9A9),
                Color(0xFF8EB97F),
                Color(0xFF6F9D60),
              ],
      ).createShader(Rect.fromLTWH(0, h * 0.48, w, h * 0.52));
    final meadowPath = Path()
      ..moveTo(0, h * 0.52)
      ..quadraticBezierTo(w * 0.25, h * 0.46, w * 0.5, h * 0.52)
      ..quadraticBezierTo(w * 0.75, h * 0.58, w, h * 0.49)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(meadowPath, meadowPaint);

    // 6. LILY POND & RIVER BASIN
    final pondPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [
                Color(0xFF24484A),
                Color(0xFF1E393A),
              ]
            : const [
                Color(0xFFA2D3DF),
                Color(0xFF7EBDCF),
              ],
      ).createShader(Rect.fromLTWH(w * 0.28, h * 0.54, w * 0.44, h * 0.22));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.62),
        width: w * 0.55,
        height: h * 0.16,
      ),
      pondPaint,
    );

    // 7. ARCHED STONE BRIDGE OVER RIVER
    final bridgePaint = Paint()
      ..color = isDark ? const Color(0xFF3B4F45) : const Color(0xFFDED8C9)
      ..style = PaintingStyle.fill;
    final bridgePath = Path()
      ..moveTo(w * 0.32, h * 0.62)
      ..quadraticBezierTo(w * 0.5, h * 0.56, w * 0.68, h * 0.62)
      ..lineTo(w * 0.68, h * 0.65)
      ..quadraticBezierTo(w * 0.5, h * 0.60, w * 0.32, h * 0.65)
      ..close();
    canvas.drawPath(bridgePath, bridgePaint);

    // 8. RUSTIC WOODEN STORYBOOK COTTAGE (Right Bank)
    _drawStorybookCottage(canvas, w * 0.76, h * 0.50, isDark);

    // 9. COBBLESTONE PATHWAY WITH GLOWING LANTERNS
    _drawCobblestoneTrail(canvas, size, isDark);
  }

  void _drawStorybookCottage(Canvas canvas, double cx, double cy, bool isDark) {
    // Cottage base
    final wallPaint = Paint()
      ..color = isDark ? const Color(0xFF2C3E32) : const Color(0xFFD8C7A5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 18), width: 54, height: 38),
        const Radius.circular(4),
      ),
      wallPaint,
    );

    // Chimney
    final chimneyPaint = Paint()
      ..color = isDark ? const Color(0xFF212C25) : const Color(0xFF9E8E7D);
    canvas.drawRect(Rect.fromLTWH(cx + 12, cy - 14, 10, 20), chimneyPaint);

    // Timber Roof
    final roofPaint = Paint()
      ..color = isDark ? const Color(0xFF5A3828) : const Color(0xFFB5654A);
    final roofPath = Path()
      ..moveTo(cx - 34, cy + 2)
      ..lineTo(cx, cy - 18)
      ..lineTo(cx + 34, cy + 2)
      ..close();
    canvas.drawPath(roofPath, roofPaint);

    // Glowing warm window
    final windowPaint = Paint()
      ..color = isDark
          ? const Color(0xFFFFD166) // Warm glowing lantern light
          : const Color(0xFFFFF2B2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 10, cy + 16), width: 14, height: 16),
        const Radius.circular(3),
      ),
      windowPaint,
    );

    // Wooden door
    final doorPaint = Paint()
      ..color = isDark ? const Color(0xFF1E2822) : const Color(0xFF7A543A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 12, cy + 24), width: 12, height: 22),
        const Radius.circular(3),
      ),
      doorPaint,
    );
  }

  void _drawCobblestoneTrail(Canvas canvas, Size size, bool isDark) {
    final stonePaint = Paint()
      ..color = isDark ? const Color(0xFF283D33) : const Color(0xFFE4DFCE);

    final stones = [
      Offset(size.width * 0.44, size.height * 0.70),
      Offset(size.width * 0.48, size.height * 0.74),
      Offset(size.width * 0.42, size.height * 0.79),
      Offset(size.width * 0.46, size.height * 0.84),
      Offset(size.width * 0.40, size.height * 0.88),
    ];

    for (var i = 0; i < stones.length; i++) {
      final s = stones[i];
      final rx = 14.0 + (i * 2.0);
      final ry = 8.0 + (i * 1.5);
      canvas.drawOval(Rect.fromCenter(center: s, width: rx, height: ry), stonePaint);
    }

    // Glowing stone lanterns on sides
    _drawLantern(canvas, size.width * 0.32, size.height * 0.73, isDark);
    _drawLantern(canvas, size.width * 0.60, size.height * 0.78, isDark);
  }

  void _drawLantern(Canvas canvas, double x, double y, bool isDark) {
    // Post
    final postPaint = Paint()..color = isDark ? const Color(0xFF1A2620) : const Color(0xFF6B6255);
    canvas.drawRect(Rect.fromLTWH(x - 2, y, 4, 18), postPaint);

    // Lamp glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD166).withValues(alpha: isDark ? 0.9 : 0.6);
    canvas.drawCircle(Offset(x, y - 2), 7, glowPaint);

    // Outer roof
    final lampRoof = Paint()..color = isDark ? const Color(0xFF3A4E42) : const Color(0xFF8A7E6C);
    final roof = Path()
      ..moveTo(x - 8, y - 4)
      ..lineTo(x, y - 10)
      ..lineTo(x + 8, y - 4)
      ..close();
    canvas.drawPath(roof, lampRoof);
  }

  @override
  bool shouldRepaint(covariant StorybookForestPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
