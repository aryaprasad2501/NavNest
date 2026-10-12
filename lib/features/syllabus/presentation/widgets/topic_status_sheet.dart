import 'package:flutter/material.dart';
import '../../../../core/models/topic_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/nest_badge.dart';

class TopicStatusSheet extends StatelessWidget {
  final String subtopicName;
  final TopicStatus currentStatus;
  final ValueChanged<TopicStatus> onStatusSelected;

  const TopicStatusSheet({
    super.key,
    required this.subtopicName,
    required this.currentStatus,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.borderStrong,
                borderRadius: AppRadius.roundedFull,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Update Topic Status', style: AppTypography.titleLarge),
          const SizedBox(height: 4),
          Text(
            subtopicName,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          ...TopicStatus.values.map((status) {
            final isSelected = status == currentStatus;
            return _buildStatusOption(status, isSelected, isDark, context);
          }),
        ],
      ),
    );
  }

  Widget _buildStatusOption(
    TopicStatus status,
    bool isSelected,
    bool isDark,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? AppColors.darkElevated : AppColors.sageTint.withValues(alpha: 0.7))
            : Colors.transparent,
        borderRadius: AppRadius.roundedM,
        border: Border.all(
          color: isSelected
              ? AppColors.deepForest
              : (isDark ? AppColors.darkBorder : AppColors.borderSubtle),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        dense: true,
        onTap: () {
          onStatusSelected(status);
          Navigator.pop(context);
        },
        leading: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: status.color,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          status.displayName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        trailing: NestBadge(
          label: isSelected ? 'Active' : status.code.replaceAll('_', ' '),
          variant: status.badgeVariant,
          isDense: true,
        ),
      ),
    );
  }
}
