import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Standard, beautifully styled card for NavNest.
/// Automatically resolves to dark card background and subtle dark borders in dark mode.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? AppColors.darkCard : AppColors.cardSurface;
    final defaultBorderColor = isDark ? AppColors.darkBorder : AppColors.borderSubtle;

    final cardContent = Container(
      width: width,
      height: height,
      padding: padding ?? AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: color ?? defaultBg,
        borderRadius: AppRadius.roundedL,
        border: Border.fromBorderSide(
          border ?? BorderSide(color: defaultBorderColor, width: 1),
        ),
        boxShadow: isDark ? [] : AppShadows.softCard,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.roundedL,
          splashColor: (isDark ? AppColors.forestEmerald : AppColors.sageTint).withValues(alpha: 0.4),
          highlightColor: (isDark ? AppColors.forestEmerald : AppColors.sageTint).withValues(alpha: 0.2),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
