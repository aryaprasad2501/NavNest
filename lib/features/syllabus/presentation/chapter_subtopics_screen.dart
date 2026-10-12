import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/chapter_model.dart';
import '../../../../core/models/subject_model.dart';
import '../../../../core/models/subtopic_model.dart';
import '../../../../core/models/topic_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/nest_badge.dart';
import '../../../../core/widgets/nest_button.dart';
import '../../../../core/widgets/nest_card.dart';
import '../../../../core/widgets/nest_progress_bar.dart';
import 'providers/syllabus_provider.dart';
import 'widgets/subtopic_notes_sheet.dart';
import 'widgets/topic_status_sheet.dart';

class ChapterSubtopicsScreen extends StatelessWidget {
  final String subjectId;

  const ChapterSubtopicsScreen({
    super.key,
    required this.subjectId,
  });

  void _openStatusSheet(
    BuildContext context,
    SubtopicModel subtopic,
    SyllabusProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TopicStatusSheet(
        subtopicName: subtopic.name,
        currentStatus: subtopic.status,
        onStatusSelected: (newStatus) {
          provider.updateSubtopicStatus(subtopic.id, newStatus);
        },
      ),
    );
  }

  void _openNotesSheet(
    BuildContext context,
    SubtopicModel subtopic,
    SyllabusProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SubtopicNotesSheet(
        subtopic: subtopic,
        onSave: (notes, duration) {
          provider.updateSubtopicNotes(subtopic.id, notes);
          provider.updateSubtopicDuration(subtopic.id, duration);
        },
      ),
    );
  }

  void _showAddChapterDialog(BuildContext context, SyllabusProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Chapter'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Chapter title (e.g. Light: Reflection & Refraction)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          NestButton(
            label: 'Add',
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.addChapter(
                  subjectId: subjectId,
                  name: controller.text.trim(),
                );
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showEditChapterDialog(BuildContext context, ChapterModel chapter, SyllabusProvider provider) {
    final controller = TextEditingController(text: chapter.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Chapter'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Chapter Title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          NestButton(
            label: 'Save',
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final updated = chapter.copyWith(
                  name: controller.text.trim(),
                  updatedAt: DateTime.now(),
                );
                provider.updateChapter(updated);
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteChapterDialog(BuildContext context, ChapterModel chapter, SyllabusProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${chapter.name}"?'),
        content: Text(
          'Are you sure you want to delete chapter "${chapter.name}"? All ${chapter.subtopics.length} subtopics inside will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteChapter(chapter.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Chapter "${chapter.name}" deleted.')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.urgentRed),
            child: const Text('Delete Chapter'),
          ),
        ],
      ),
    );
  }

  void _showAddSubtopicDialog(BuildContext context, String chapterId, SyllabusProvider provider) {
    final nameController = TextEditingController();
    final durationController = TextEditingController(text: '35');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Subtopic'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Subtopic Title',
                hintText: 'e.g. Lens Formula & Power Calculations',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Estimated Minutes',
                suffixText: 'mins',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          NestButton(
            label: 'Add',
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final duration = int.tryParse(durationController.text.trim()) ?? 35;
                provider.addSubtopic(
                  chapterId: chapterId,
                  name: nameController.text.trim(),
                  estimatedMinutes: duration,
                );
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showEditSubtopicDialog(BuildContext context, SubtopicModel subtopic, SyllabusProvider provider) {
    final nameController = TextEditingController(text: subtopic.name);
    final durationController = TextEditingController(text: subtopic.estimatedMinutes.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Subtopic'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Subtopic Name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Estimated Minutes',
                suffixText: 'mins',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          NestButton(
            label: 'Save',
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final duration = int.tryParse(durationController.text.trim()) ?? subtopic.estimatedMinutes;
                provider.updateSubtopicDetails(
                  subtopicId: subtopic.id,
                  name: nameController.text.trim(),
                  estimatedMinutes: duration,
                );
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteSubtopicDialog(BuildContext context, SubtopicModel subtopic, SyllabusProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${subtopic.name}"?'),
        content: const Text('Are you sure you want to delete this subtopic?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteSubtopic(subtopic.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Subtopic "${subtopic.name}" deleted.')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.urgentRed),
            child: const Text('Delete Subtopic'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<SyllabusProvider>(context);

    final subject = provider.subjects.firstWhere(
      (s) => s.id == subjectId,
      orElse: () => SubjectModel(
        id: subjectId,
        name: 'Subject',
        colorHex: '#6B8E70',
        iconName: 'menu_book',
        createdAt: DateTime.now(),
      ),
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.ivoryCanvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subject.name, style: AppTypography.titleLarge),
            Text(
              '${subject.completedChapters}/${subject.totalChapters} completed • ${(subject.progress * 100).toInt()}%',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add Chapter',
            onPressed: () => _showAddChapterDialog(context, provider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        children: [
          // Subject Progress Summary Card
          NestCard(
            color: isDark ? AppColors.darkCard : AppColors.cardSurface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subject Syllabus Progress', style: AppTypography.titleSmall),
                    NestBadge(
                      label: '${(subject.progress * 100).toInt()}% Done',
                      variant: subject.progress > 0.7 ? NestBadgeVariant.safeGreen : NestBadgeVariant.sage,
                      isDense: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                NestProgressBar(
                  progress: subject.progress,
                  height: 8,
                  progressColor: subject.color,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat('Chapters', '${subject.completedChapters} of ${subject.totalChapters}', isDark),
                    _buildStat('Subtopics', '${subject.completedSubtopics} of ${subject.totalSubtopics}', isDark),
                    _buildStat('Est. Hours', '${(subject.totalEstimatedMinutes / 60).toStringAsFixed(1)}h', isDark),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.l),

          // Chapters & Subtopics Accordions
          if (subject.chapters.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Center(
                child: Text(
                  'No chapters added yet. Tap + to create the first chapter.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ] else ...[
            ...subject.chapters.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final chapter = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildChapterAccordion(
                  context,
                  index,
                  chapter,
                  provider,
                  isDark,
                ),
              );
            }),
          ],

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildChapterAccordion(
    BuildContext context,
    int index,
    ChapterModel chapter,
    SyllabusProvider provider,
    bool isDark,
  ) {
    return NestCard(
      color: isDark ? AppColors.darkCard : AppColors.cardSurface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$index. ${chapter.name}',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NestBadge(
                    label: '${chapter.completedSubtopics}/${chapter.totalSubtopics}',
                    variant: chapter.isCompleted ? NestBadgeVariant.safeGreen : NestBadgeVariant.neutral,
                    isDense: true,
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textMuted),
                    padding: EdgeInsets.zero,
                    onSelected: (action) {
                      if (action == 'edit') {
                        _showEditChapterDialog(context, chapter, provider);
                      } else if (action == 'delete') {
                        _showDeleteChapterDialog(context, chapter, provider);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Rename Chapter'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.urgentRed),
                            const SizedBox(width: 8),
                            Text('Delete Chapter', style: TextStyle(color: AppColors.urgentRed)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          NestProgressBar(progress: chapter.progress, height: 6, progressColor: AppColors.sageGreen),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 6),

          // Subtopics Rows
          ...chapter.subtopics.map((sub) => _buildSubtopicRow(context, sub, provider, isDark)),

          const SizedBox(height: 6),
          // Quick add subtopic action
          InkWell(
            onTap: () => _showAddSubtopicDialog(context, chapter.id, provider),
            borderRadius: AppRadius.roundedS,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                children: [
                  const Icon(Icons.add_rounded, size: 18, color: AppColors.deepForest),
                  const SizedBox(width: 6),
                  Text(
                    'Add subtopic...',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.sageLight : AppColors.deepForest,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtopicRow(
    BuildContext context,
    SubtopicModel sub,
    SyllabusProvider provider,
    bool isDark,
  ) {
    final isDone = sub.status == TopicStatus.completed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          // Quick Toggle Circle Checkmark
          GestureDetector(
            onTap: () {
              final nextStatus = isDone ? TopicStatus.notStarted : TopicStatus.completed;
              provider.updateSubtopicStatus(sub.id, nextStatus);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isDone ? AppColors.safeGreen : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone ? AppColors.safeGreen : (isDark ? AppColors.darkBorder : AppColors.borderStrong),
                  width: 1.5,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // Subtopic Name
          Expanded(
            child: GestureDetector(
              onTap: () => _openNotesSheet(context, sub, provider),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDone
                          ? (isDark ? AppColors.darkTextMuted : AppColors.textMuted)
                          : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (sub.notes != null && sub.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_note_rounded, size: 14, color: AppColors.sageGreen),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              sub.notes!,
                              style: TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Duration badge
          Text(
            '${sub.estimatedMinutes}m',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          // Tappable Status Badge (opens Status Selector Sheet)
          GestureDetector(
            onTap: () => _openStatusSheet(context, sub, provider),
            child: NestBadge(
              label: sub.status.displayName,
              variant: sub.status.badgeVariant,
              isDense: true,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 16, color: AppColors.textMuted),
            padding: EdgeInsets.zero,
            onSelected: (action) {
              if (action == 'edit') {
                _showEditSubtopicDialog(context, sub, provider);
              } else if (action == 'notes') {
                _openNotesSheet(context, sub, provider);
              } else if (action == 'status') {
                _openStatusSheet(context, sub, provider);
              } else if (action == 'delete') {
                _showDeleteSubtopicDialog(context, sub, provider);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Title & Time'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'notes',
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Notes & Target'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'status',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Change Status'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.urgentRed),
                    const SizedBox(width: 8),
                    Text('Delete Subtopic', style: TextStyle(color: AppColors.urgentRed)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
