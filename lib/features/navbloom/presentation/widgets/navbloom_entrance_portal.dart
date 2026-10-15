import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';

/// Cinematic, atmospheric entrance portal for NavBloom.
/// Welcomes the student with drifting fireflies, ethereal forest mist,
/// and a glowing sanctuary gateway before entering the interactive grove.
class NavBloomEntrancePortal extends StatefulWidget {
  final VoidCallback onEnter;
  final bool isMoonlit;

  const NavBloomEntrancePortal({
    super.key,
    required this.onEnter,
    this.isMoonlit = true,
  });

  @override
  State<NavBloomEntrancePortal> createState() => _NavBloomEntrancePortalState();
}

class _NavBloomEntrancePortalState extends State<NavBloomEntrancePortal>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _driftController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _driftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 1. Deep Celestial Forest Backdrop
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: widget.isMoonlit
                      ? const [
                          Color(0xFF061412),
                          Color(0xFF0A1F1B),
                          Color(0xFF0F2E27),
                          Color(0xFF05120F),
                        ]
                      : const [
                          Color(0xFF0D281E),
                          Color(0xFF133E2F),
                          Color(0xFF1A503C),
                          Color(0xFF0E2B20),
                        ],
                  stops: const [0.0, 0.35, 0.75, 1.0],
                ),
              ),
            ),
          ),

          // 2. Animated Floating Fireflies / Spores
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _driftController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _PortalParticlePainter(
                      progress: _driftController.value,
                      isMoonlit: widget.isMoonlit,
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. Central Gateway & Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Whispering Sanctuary Emblem with Pulsing Radiance
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        final glow = _pulseAnimation.value;
                        return Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF4ADE80).withValues(alpha: 0.35 + (glow * 0.25)),
                                const Color(0xFF10B981).withValues(alpha: 0.15 + (glow * 0.15)),
                                Colors.transparent,
                              ],
                              stops: const [0.2, 0.6, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2ECC71).withValues(alpha: 0.25 + (glow * 0.2)),
                                blurRadius: 36 + (glow * 14),
                                spreadRadius: 4 + (glow * 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF09231B),
                                border: Border.all(
                                  color: const Color(0xFF4ADE80).withValues(alpha: 0.8),
                                  width: 2.5,
                                ),
                              ),
                              child: const Center(
                                child: Text('🌸', style: TextStyle(fontSize: 42)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    // Atmospheric Title
                    Text(
                      'NavBloom',
                      style: AppTypography.displayLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: const Color(0xFF2ECC71).withValues(alpha: 0.6),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'The Living Study Grove',
                      style: AppTypography.titleMedium.copyWith(
                        color: const Color(0xFF86EFAC),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Lore Description
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF2ECC71).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Every minute of focused study breathes life into a living tree. '
                        'Plant CBSE topics, shield yourself from distractions, and grow your majestic forest.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Primary "Enter Sanctuary" CTA
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, _) {
                        final scale = 1.0 + (_pulseAnimation.value * 0.03);
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2ECC71).withValues(alpha: 0.45),
                                  blurRadius: 24,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: FilledButton(
                              onPressed: widget.onEnter,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF22C55E),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'Enter Sanctuary',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('🌿', style: TextStyle(fontSize: 18)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Quick Enter / Skip Text
                    TextButton(
                      onPressed: widget.onEnter,
                      child: Text(
                        'Skip directly to Grove',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for atmospheric drifting fireflies & mist particles
class _PortalParticlePainter extends CustomPainter {
  final double progress;
  final bool isMoonlit;

  _PortalParticlePainter({
    required this.progress,
    required this.isMoonlit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final particleCount = 28;
    final rng = math.Random(1337);

    for (int i = 0; i < particleCount; i++) {
      final seedX = rng.nextDouble();
      final seedY = rng.nextDouble();
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final radius = 1.5 + rng.nextDouble() * 2.8;

      // Animate vertical drift and sinusoidal sway
      final t = (progress * speed + seedY) % 1.0;
      final y = size.height * (1.0 - t);
      final sway = math.sin((progress * 2 * math.pi) + (i * 0.8)) * 18;
      final x = (seedX * size.width) + sway;

      final alpha = (math.sin(t * math.pi) * 0.85).clamp(0.0, 1.0);
      final color = isMoonlit
          ? (i % 2 == 0 ? const Color(0xFF6EE7B7) : const Color(0xFFFDE68A))
          : const Color(0xFF86EFAC);

      final paint = Paint()
        ..color = color.withValues(alpha: alpha * 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PortalParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
