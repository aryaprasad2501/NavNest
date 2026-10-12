import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Standard, beautifully styled card for NavNest.
class NestCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BorderSide? border;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const NestCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.border,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      width: width,
      height: height,
      padding: padding ?? AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: color ?? AppColors.cardSurface,
        borderRadius: AppRadius.roundedL,
        border: Border.fromBorderSide(
          border ?? const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        boxShadow: AppShadows.softCard,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.roundedL,
          splashColor: AppColors.sageTint.withValues(alpha: 0.5),
          highlightColor: AppColors.sageTint.withValues(alpha: 0.2),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
