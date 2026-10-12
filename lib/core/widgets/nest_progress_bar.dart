import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class NestProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color? progressColor;
  final Color? backgroundColor;
  final bool animate;

  const NestProgressBar({
    super.key,
    required this.progress,
    this.height = 8.0,
    this.progressColor,
    this.backgroundColor,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final fg = progressColor ?? AppColors.sageGreen;
    final bg = backgroundColor ?? AppColors.warmCream;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.roundedFull,
      ),
      clipBehavior: Clip.antiAlias,
      child: animate
          ? TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: clamped),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: fg,
                      borderRadius: AppRadius.roundedFull,
                    ),
                  ),
                );
              },
            )
          : FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clamped,
              child: Container(
                decoration: BoxDecoration(
                  color: fg,
                  borderRadius: AppRadius.roundedFull,
                ),
              ),
            ),
    );
  }
}

class NestCircularProgress extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Color? backgroundColor;
  final Widget? centerWidget;

  const NestCircularProgress({
    super.key,
    required this.progress,
    this.size = 80.0,
    this.strokeWidth = 7.0,
    this.progressColor,
    this.backgroundColor,
    this.centerWidget,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final fg = progressColor ?? AppColors.sageGreen;
    final bg = backgroundColor ?? AppColors.warmCream;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: clamped,
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
              backgroundColor: bg,
            ),
          ),
          if (centerWidget != null) centerWidget!,
        ],
      ),
    );
  }
}
