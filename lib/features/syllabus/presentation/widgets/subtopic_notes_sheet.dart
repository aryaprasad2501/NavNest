import 'package:flutter/material.dart';
import '../../../../core/models/subtopic_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/nest_button.dart';

class SubtopicNotesSheet extends StatefulWidget {
  final SubtopicModel subtopic;
  final Function(String? notes, int estimatedMinutes) onSave;

  const SubtopicNotesSheet({
    super.key,
    required this.subtopic,
    required this.onSave,
  });

  @override
  State<SubtopicNotesSheet> createState() => _SubtopicNotesSheetState();
}

class _SubtopicNotesSheetState extends State<SubtopicNotesSheet> {
  late TextEditingController _notesController;
  late int _estimatedMinutes;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.subtopic.notes ?? '');
    _estimatedMinutes = widget.subtopic.estimatedMinutes;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
            Text('Topic Notes & Duration', style: AppTypography.titleLarge),
            const SizedBox(height: 4),
            Text(
              widget.subtopic.name,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            // Duration selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estimated Study Time',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      onPressed: () {
                        if (_estimatedMinutes > 15) {
                          setState(() => _estimatedMinutes -= 15);
                        }
                      },
                    ),
                    Text(
                      '$_estimatedMinutes mins',
                      style: AppTypography.labelLarge.copyWith(color: AppColors.deepForest),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      onPressed: () {
                        if (_estimatedMinutes < 240) {
                          setState(() => _estimatedMinutes += 15);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Add revision notes, formulas to memorize, or key exam questions...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
                filled: true,
                fillColor: isDark ? AppColors.darkCard : AppColors.warmCream,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.roundedM,
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.roundedM,
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            NestButton(
              label: 'Save Topic Details',
              isFullWidth: true,
              onPressed: () {
                widget.onSave(
                  _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                  _estimatedMinutes,
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
