import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'nest_button.dart';

class NestEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;
  final IconData? buttonIcon;

  const NestEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.buttonLabel,
    this.onButtonPressed,
    this.buttonIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.sageTint,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.sageBorder, width: 1.5),
              ),
              child: Icon(
                icon,
                size: 34,
                color: AppColors.sageGreen,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              description,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null && onButtonPressed != null) ...[
              const SizedBox(height: AppSpacing.xl),
              NestButton(
                label: buttonLabel!,
                icon: buttonIcon,
                onPressed: onButtonPressed,
                variant: NestButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
