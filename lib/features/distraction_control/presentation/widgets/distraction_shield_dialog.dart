import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/nest_button.dart';
import '../../../focus/presentation/providers/focus_session_provider.dart';
import '../providers/app_blocker_provider.dart';

class DistractionShieldDialog extends StatelessWidget {
  final String packageName;
  final VoidCallback onDismiss;

  const DistractionShieldDialog({
    super.key,
    required this.packageName,
    required this.onDismiss,
  });

  static Future<void> show(BuildContext context, String packageName) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DistractionShieldDialog(
        packageName: packageName,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blocker = context.watch<AppBlockerProvider>();
    final focus = context.watch<FocusSessionProvider>();

    final app = blocker.getAppByPackage(packageName);
    final appName = app?.appName ?? packageName.split('.').last.toUpperCase();
    final appEmoji = app?.iconEmoji ?? '📱';

    final subject = focus.subjectName;
    final chapter = focus.chapterName;
    final isStrict = blocker.isStrictMode;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedXL),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Shield & blocked app icon
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.deepForest.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.deepForest,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.cardSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.safeGreen, width: 2),
                    ),
                    child: Text(appEmoji, style: const TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              'Distraction Shield Activated 🛡️',
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              '$appName was minimized because your focus session is active.',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Active study info card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.sageTint,
                borderRadius: AppRadius.roundedL,
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.sageBorder),
              ),
              child: Row(
                children: [
                  Text(focus.treeSpecies.iconEmoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$subject • $chapter',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${focus.elapsedActiveSeconds ~/ 60}m focused • Don\'t let your tree wither! 🌱',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextMuted : AppColors.deepForest,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (isStrict) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.amberHoney.withValues(alpha: 0.15),
                  borderRadius: AppRadius.roundedM,
                  border: Border.all(color: AppColors.amberHoney.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_clock_rounded, color: AppColors.amberHoney, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Strict Mode Active: Restful apps are shielded until your study timer completes.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Actions
            NestButton(
              label: 'Return to Focus',
              icon: Icons.arrow_back_rounded,
              onPressed: () {
                blocker.clearPendingIntervention();
                onDismiss();
              },
              variant: NestButtonVariant.primary,
              isFullWidth: true,
            ),

            if (!isStrict) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  blocker.clearPendingIntervention();
                  focus.pauseSession();
                  onDismiss();
                },
                child: Text(
                  'Pause Session for 5m Break',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
