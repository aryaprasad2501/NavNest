import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class NestBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const NestBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = NavThemeColors.of(context);
    final isDark = colors.isDark;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.border,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.35) : AppColors.deepForest.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 7.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Home',
                colors: colors,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.park_rounded,
                label: 'NavBloom',
                colors: colors,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.calendar_month_rounded,
                label: 'Planner',
                colors: colors,
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.menu_book_rounded,
                label: 'Syllabus',
                colors: colors,
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.favorite_rounded,
                label: 'Shared',
                colors: colors,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required NavThemeColors colors,
  }) {
    final isSelected = currentIndex == index;
    final isDark = colors.isDark;
    final selectedIconColor = isDark ? colors.primary : colors.primary;
    final unselectedColor = colors.textMuted;
    final selectedBg = isDark
        ? colors.primaryContainer.withValues(alpha: 0.7)
        : colors.primaryContainer;
    final selectedBorder = isDark
        ? colors.primary.withValues(alpha: 0.35)
        : colors.border;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutBack,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: isSelected ? selectedBg : Colors.transparent,
                    borderRadius: AppRadius.roundedFull,
                    border: Border.all(
                      color: isSelected ? selectedBorder : Colors.transparent,
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 21,
                    color: isSelected ? selectedIconColor : unselectedColor,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? selectedIconColor : unselectedColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 10.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: isSelected ? 4.0 : 0.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: isSelected ? (isDark ? colors.primary : colors.accent) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
