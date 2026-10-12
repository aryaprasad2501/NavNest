import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum NestBadgeVariant {
  sage,
  forest,
  amber,
  urgentRed,
  safeGreen,
  lavender,
  coral,
  neutral,
}

class NestBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final NestBadgeVariant variant;
  final bool isDense;

  const NestBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = NestBadgeVariant.sage,
    this.isDense = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bg;
    Color fg;
    Color border;

    if (isDark) {
      switch (variant) {
        case NestBadgeVariant.forest:
          bg = AppColors.forestEmerald.withValues(alpha: 0.25);
          fg = Colors.white;
          border = AppColors.forestEmerald;
          break;
        case NestBadgeVariant.sage:
          bg = AppColors.sageGreen.withValues(alpha: 0.2);
          fg = AppColors.sageLight;
          border = AppColors.sageGreen.withValues(alpha: 0.4);
          break;
        case NestBadgeVariant.amber:
          bg = AppColors.amberHoney.withValues(alpha: 0.2);
          fg = AppColors.amberWarm;
          border = AppColors.amberHoney.withValues(alpha: 0.4);
          break;
        case NestBadgeVariant.urgentRed:
          bg = AppColors.urgentRed.withValues(alpha: 0.2);
          fg = const Color(0xFFFF7B7B);
          border = AppColors.urgentRed.withValues(alpha: 0.4);
          break;
        case NestBadgeVariant.safeGreen:
          bg = AppColors.safeGreen.withValues(alpha: 0.2);
          fg = const Color(0xFF7BE4A2);
          border = AppColors.safeGreen.withValues(alpha: 0.4);
          break;
        case NestBadgeVariant.lavender:
          bg = AppColors.revisionPurple.withValues(alpha: 0.2);
          fg = const Color(0xFFC0B3E8);
          border = AppColors.revisionPurple.withValues(alpha: 0.4);
          break;
        case NestBadgeVariant.coral:
          bg = AppColors.restudyCoral.withValues(alpha: 0.2);
          fg = const Color(0xFFFFA085);
          border = AppColors.restudyCoral.withValues(alpha: 0.4);
          break;
        case NestBadgeVariant.neutral:
          bg = AppColors.darkElevated;
          fg = AppColors.darkTextSecondary;
          border = AppColors.darkBorder;
          break;
      }
    } else {
      switch (variant) {
        case NestBadgeVariant.forest:
          bg = AppColors.deepForest;
          fg = Colors.white;
          border = AppColors.deepForestDark;
          break;
        case NestBadgeVariant.sage:
          bg = AppColors.sageTint;
          fg = AppColors.deepForest;
          border = AppColors.sageBorder;
          break;
        case NestBadgeVariant.amber:
          bg = AppColors.amberSoft;
          fg = AppColors.amberHoney;
          border = AppColors.amberWarm.withValues(alpha: 0.3);
          break;
        case NestBadgeVariant.urgentRed:
          bg = AppColors.urgentRedLight;
          fg = AppColors.urgentRed;
          border = AppColors.urgentRed.withValues(alpha: 0.3);
          break;
        case NestBadgeVariant.safeGreen:
          bg = AppColors.safeGreenLight;
          fg = AppColors.safeGreen;
          border = AppColors.safeGreen.withValues(alpha: 0.3);
          break;
        case NestBadgeVariant.lavender:
          bg = AppColors.revisionPurpleLight;
          fg = AppColors.revisionPurple;
          border = AppColors.revisionPurple.withValues(alpha: 0.3);
          break;
        case NestBadgeVariant.coral:
          bg = AppColors.restudyCoralLight;
          fg = AppColors.restudyCoral;
          border = AppColors.restudyCoral.withValues(alpha: 0.3);
          break;
        case NestBadgeVariant.neutral:
          bg = AppColors.warmCream;
          fg = AppColors.textSecondary;
          border = AppColors.borderSubtle;
          break;
      }
    }

    final padding = isDense
        ? const EdgeInsets.symmetric(horizontal: 7, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 5);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.roundedS,
        border: Border.all(color: border, width: 0.9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isDense ? 11 : 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: (isDense ? AppTypography.labelSmall : AppTypography.labelMedium)
                .copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
