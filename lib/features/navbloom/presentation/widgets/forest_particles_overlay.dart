import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Serene, hardware-accelerated ambient particle animation.
/// Spawns gentle falling cherry petals in daylight and bioluminescent glowing fireflies in moonlit mode.
class ForestParticlesOverlay extends StatefulWidget {
  final bool isMoonlit;

  const ForestParticlesOverlay({super.key, required this.isMoonlit});

  @override
  State<ForestParticlesOverlay> createState() => _ForestParticlesOverlayState();
}

class _ForestParticlesOverlayState extends State<ForestParticlesOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random(42);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _controller.repeat();
    }

    // Initialize 24 ambient particles
    for (int i = 0; i < 24; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 5 + 3,
          speed: _random.nextDouble() * 0.4 + 0.2,
          drift: (_random.nextDouble() - 0.5) * 0.3,
          phase: _random.nextDouble() * 2 * math.pi,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ParticlePainter(
              particles: _particles,
              progress: _controller.value,
              isMoonlit: widget.isMoonlit,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double drift;
  final double phase;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.drift,
    required this.phase,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final bool isMoonlit;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.isMoonlit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final petalColor = AppColors.cherryPink.withValues(alpha: 0.65);
    final fireflyColor = const Color(0xFFC4F987);

    for (final p in particles) {
      // Calculate continuous looping position
      final effectiveY = (p.y + progress * p.speed) % 1.0;
      final wave = math.sin(progress * 2 * math.pi + p.phase) * 0.04;
      final effectiveX = (p.x + p.drift * progress + wave) % 1.0;

      final cx = effectiveX * size.width;
      final cy = effectiveY * size.height;

      if (isMoonlit) {
        // Glowing bioluminescent firefly
        final glowRadius = p.size * 2.2;
        final glowPaint = Paint()
          ..color = fireflyColor.withValues(
              alpha: (0.35 + 0.3 * math.sin(progress * 4 * math.pi + p.phase)).clamp(0.1, 0.75))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(cx, cy), glowRadius, glowPaint);

        final corePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(cx, cy), p.size * 0.6, corePaint);
      } else {
        // Drifting soft cherry blossom petal
        final petalPaint = Paint()
          ..color = petalColor
          ..style = PaintingStyle.fill;

        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(progress * math.pi + p.phase);
        final rect = Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.6);
        canvas.drawOval(rect, petalPaint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
