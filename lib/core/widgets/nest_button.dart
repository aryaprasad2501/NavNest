import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum NestButtonVariant { primary, secondary, subtle, danger }

class NestButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final NestButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;

  const NestButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = NestButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bg;
    Color fg;
    BorderSide? border;

    switch (variant) {
      case NestButtonVariant.primary:
        bg = isDark ? AppColors.forestEmerald : AppColors.deepForest;
        fg = Colors.white;
        border = null;
        break;
      case NestButtonVariant.secondary:
        bg = isDark ? AppColors.darkElevated : AppColors.sageTint;
        fg = isDark ? AppColors.darkTextPrimary : AppColors.deepForestDark;
        border = BorderSide(color: isDark ? AppColors.darkBorder : AppColors.sageBorder, width: 1);
        break;
      case NestButtonVariant.subtle:
        bg = Colors.transparent;
        fg = isDark ? AppColors.sageLight : AppColors.deepForest;
        border = BorderSide(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle, width: 1);
        break;
      case NestButtonVariant.danger:
        bg = isDark ? AppColors.urgentRed.withValues(alpha: 0.2) : AppColors.urgentRedLight;
        fg = isDark ? const Color(0xFFFF7B7B) : AppColors.urgentRed;
        border = BorderSide(color: AppColors.urgentRed.withValues(alpha: 0.3), width: 1);
        break;
    }

    final effectivePadding = padding ??
        const EdgeInsets.symmetric(horizontal: 18, vertical: 13);

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: AppTypography.labelLarge.copyWith(color: fg),
        ),
      ],
    );

    return Material(
      color: onPressed == null ? bg.withValues(alpha: 0.5) : bg,
      borderRadius: AppRadius.roundedM,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: AppRadius.roundedM,
        splashColor: fg.withValues(alpha: 0.12),
        highlightColor: fg.withValues(alpha: 0.06),
        child: Container(
          padding: effectivePadding,
          decoration: BoxDecoration(
            borderRadius: AppRadius.roundedM,
            border: border != null ? Border.fromBorderSide(border) : null,
          ),
          child: content,
        ),
      ),
    );
  }
}
