import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Crisp vector Google 'G' logo drawn using Canvas
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.22;
    final innerRadius = radius - (strokeWidth / 2);

    final rect = Rect.fromCircle(center: center, radius: innerRadius);

    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Draw the 4 arcs of Google G
    // Red: Top to top-left (~190 deg to 315 deg)
    canvas.drawArc(rect, -math.pi * 0.75, math.pi * 0.55, false, paintRed);

    // Yellow: Bottom-left
    canvas.drawArc(rect, -math.pi * 0.20, -math.pi * 0.55, false, paintYellow);

    // Green: Bottom
    canvas.drawArc(rect, math.pi * 0.15, math.pi * 0.55, false, paintGreen);

    // Blue: Right arc
    canvas.drawArc(rect, math.pi * 0.70, math.pi * 0.40, false, paintBlue);

    // Blue horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final barRect = Rect.fromLTWH(
      center.dx,
      center.dy - (strokeWidth / 2),
      innerRadius,
      strokeWidth,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
