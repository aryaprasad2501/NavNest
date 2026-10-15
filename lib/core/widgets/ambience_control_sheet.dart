import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ambience_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AmbienceControlSheet extends StatelessWidget {
  const AmbienceControlSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AmbienceControlSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ambience = context.watch<AmbienceProvider>();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: AppShadows.elevated,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkElevated : AppColors.sageTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.headphones_rounded,
                  color: isDark ? AppColors.sageLight : AppColors.deepForest,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Study Ambience',
                      style: AppTypography.titleLarge.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      ambience.isPlaying
                          ? 'Now playing: ${ambience.currentTrack.displayName}'
                          : 'Procedural focus sounds (looping)',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (ambience.hasActiveAudio)
                IconButton(
                  icon: Icon(
                    ambience.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                    color: AppColors.sageGreen,
                    size: 36,
                  ),
                  tooltip: ambience.isPlaying ? 'Pause' : 'Resume',
                  onPressed: ambience.togglePlayPause,
                ),
            ],
          ),

          if (ambience.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: AppRadius.roundedM,
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ambience.errorMessage!,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Sound Selection Cards
          Text(
            'Soundscape',
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              _buildSoundCard(
                context: context,
                track: AmbienceTrack.rain,
                label: 'Rain Ambience',
                subtitle: 'Soft gentle rain',
                iconEmoji: '🌧️',
                isSelected: ambience.currentTrack == AmbienceTrack.rain,
                isPlaying: ambience.isPlaying && ambience.currentTrack == AmbienceTrack.rain,
                isLoading: ambience.isLoading && ambience.currentTrack == AmbienceTrack.rain,
                isDark: isDark,
                onTap: () => ambience.playTrack(AmbienceTrack.rain),
              ),
              const SizedBox(width: 12),
              _buildSoundCard(
                context: context,
                track: AmbienceTrack.forest,
                label: 'Forest Ambience',
                subtitle: 'Breeze & birds',
                iconEmoji: '🌲',
                isSelected: ambience.currentTrack == AmbienceTrack.forest,
                isPlaying: ambience.isPlaying && ambience.currentTrack == AmbienceTrack.forest,
                isLoading: ambience.isLoading && ambience.currentTrack == AmbienceTrack.forest,
                isDark: isDark,
                onTap: () => ambience.playTrack(AmbienceTrack.forest),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Stop / Turn Off Button
          if (ambience.currentTrack != AmbienceTrack.none)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: ambience.stop,
                icon: const Icon(Icons.volume_off_rounded, size: 16),
                label: const Text('Turn Off Sound', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Volume Slider
          Row(
            children: [
              Icon(
                ambience.volume == 0 ? Icons.volume_mute_rounded : Icons.volume_down_rounded,
                size: 20,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.sageGreen,
                    inactiveTrackColor: isDark ? AppColors.darkBorder : AppColors.warmCream,
                    thumbColor: AppColors.deepForest,
                    overlayColor: AppColors.sageGreen.withValues(alpha: 0.15),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: ambience.volume,
                    min: 0.0,
                    max: 1.0,
                    onChanged: ambience.setVolume,
                  ),
                ),
              ),
              Icon(
                Icons.volume_up_rounded,
                size: 20,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                '${(ambience.volume * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSoundCard({
    required BuildContext context,
    required AmbienceTrack track,
    required String label,
    required String subtitle,
    required String iconEmoji,
    required bool isSelected,
    required bool isPlaying,
    required bool isLoading,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeColor = AppColors.deepForest;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkElevated : AppColors.sageTint)
                : (isDark ? AppColors.darkCard : AppColors.ivoryCanvas),
            borderRadius: AppRadius.roundedL,
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : (isDark ? AppColors.darkBorder : AppColors.borderSubtle),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected ? AppShadows.softCard : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(iconEmoji, style: const TextStyle(fontSize: 24)),
                  if (isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (isPlaying)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.safeGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PLAYING',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.safeGreen,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
