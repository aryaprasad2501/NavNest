import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/subject_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nest_badge.dart';
import '../../../core/widgets/nest_button.dart';
import '../../../core/widgets/nest_card.dart';
import '../../../core/widgets/nest_progress_bar.dart';
import 'chapter_subtopics_screen.dart';
import '../../planner/presentation/providers/planner_provider.dart';
import 'providers/syllabus_provider.dart';

class SyllabusScreen extends StatefulWidget {
  const SyllabusScreen({super.key});

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  int _selectedTabIndex = 0; // 0: Subjects, 1: Exams
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSubject(BuildContext context, SubjectModel sub) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChapterSubtopicsScreen(
          subjectId: sub.id,
        ),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context, SyllabusProvider provider) {
    final nameController = TextEditingController();
    String selectedColor = '#4A7C59';

    final colors = [
      {'name': 'Green', 'hex': '#4A7C59'},
      {'name': 'Emerald', 'hex': '#3B8A6E'},
      {'name': 'Rust', 'hex': '#C2783B'},
      {'name': 'Slate', 'hex': '#5C7C8A'},
      {'name': 'Rose', 'hex': '#B86B77'},
      {'name': 'Indigo', 'hex': '#4B6584'},
      {'name': 'Orange', 'hex': '#E8833A'},
      {'name': 'Amber', 'hex': '#D49B3E'},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add New Subject'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Subject Name',
                    hintText: 'e.g. Sanskrit, French, Artificial Intelligence',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Choose Color Tag', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: colors.map((c) {
                    final isChosen = selectedColor == c['hex'];
                    final colorVal = Color(int.parse('FF${c['hex']!.replaceAll('#', '')}', radix: 16));
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = c['hex']!),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: colorVal,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isChosen
                                ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              NestButton(
                label: 'Create Subject',
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    provider.addSubject(
                      name: nameController.text.trim(),
                      colorHex: selectedColor,
                    );
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditSubjectDialog(BuildContext context, SubjectModel sub, SyllabusProvider provider) {
    final nameController = TextEditingController(text: sub.name);
    String selectedColor = sub.colorHex;

    final colors = [
      {'name': 'Green', 'hex': '#4A7C59'},
      {'name': 'Emerald', 'hex': '#3B8A6E'},
      {'name': 'Rust', 'hex': '#C2783B'},
      {'name': 'Slate', 'hex': '#5C7C8A'},
      {'name': 'Rose', 'hex': '#B86B77'},
      {'name': 'Indigo', 'hex': '#4B6584'},
      {'name': 'Orange', 'hex': '#E8833A'},
      {'name': 'Amber', 'hex': '#D49B3E'},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Subject'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Subject Name',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Choose Color Tag', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: colors.map((c) {
                    final isChosen = selectedColor.toUpperCase() == c['hex']!.toUpperCase();
                    final colorVal = Color(int.parse('FF${c['hex']!.replaceAll('#', '')}', radix: 16));
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = c['hex']!),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: colorVal,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isChosen
                                ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              NestButton(
                label: 'Save Changes',
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    final updated = sub.copyWith(
                      name: nameController.text.trim(),
                      colorHex: selectedColor,
                    );
                    provider.updateSubject(updated);
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteSubjectDialog(BuildContext context, SubjectModel sub, SyllabusProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${sub.name}"?'),
        content: Text(
          'Are you sure you want to delete ${sub.name}? All ${sub.totalChapters} chapters and ${sub.totalSubtopics} topics inside will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteSubject(sub.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Subject "${sub.name}" deleted.')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.urgentRed),
            child: const Text('Delete Subject'),
          ),
        ],
      ),
    );
  }

  void _showReloadClass10Dialog(BuildContext context, SyllabusProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load CBSE Class 10 Syllabus?'),
        content: const Text(
          'This will load or restore the complete official CBSE Class 10 Board Exam 2027 curriculum across all 6 subjects (Mathematics, Science, Social Science, English, Hindi, and IT 402) with all official chapters and subtopics.\n\nContinue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          NestButton(
            label: 'Load Syllabus (2027)',
            onPressed: () async {
              Navigator.pop(context);
              await provider.reloadOfficialClass10Syllabus();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Official CBSE Class 10 (2027) Syllabus loaded!'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<SyllabusProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.ivoryCanvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Syllabus', style: AppTypography.titleLarge),
            Text(
              'CBSE Class 10 Board 2027 • ${(provider.overallProgress * 100).toInt()}% Total Progress',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Load / Reset CBSE Class 10 (2027) Syllabus',
            onPressed: () => _showReloadClass10Dialog(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Subject',
            onPressed: () => _showAddSubjectDialog(context, provider),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Segmented Tabs: [Subjects] [Exams]
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.warmCream,
                borderRadius: AppRadius.roundedFull,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
                ),
              ),
              child: Row(
                children: [
                  _buildTab('Subjects (${provider.subjects.length})', 0, isDark),
                  _buildTab('Exams (${context.watch<PlannerProvider>().exams.length})', 1, isDark),
                ],
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.cardSurface,
                borderRadius: AppRadius.roundedM,
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
                boxShadow: AppShadows.softCard,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: provider.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search subjects, chapters, subtopics...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            provider.setSearchQuery('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ),

          // Status Filter Chips
          _buildFilterChips(provider, isDark),

          // Revision & Restudy Queue Indicators
          if (provider.revisionQueue.isNotEmpty || provider.restudyQueue.isNotEmpty)
            _buildQueuePills(provider, isDark),

          // Subjects List
          Expanded(
            child: provider.subjects.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.school_outlined, size: 56, color: AppColors.sageGreen),
                          const SizedBox(height: 16),
                          Text('No Subjects Found', style: AppTypography.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                            'Tap below to load the complete official CBSE Class 10 Board Exam 2027 Syllabus with all 6 subjects.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 20),
                          NestButton(
                            label: 'Load CBSE Class 10 Syllabus',
                            icon: Icons.sync_rounded,
                            onPressed: () => _showReloadClass10Dialog(context, provider),
                          ),
                        ],
                      ),
                    ),
                  )
                : provider.filteredSubjects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'No topics match your current filter.',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: provider.filteredSubjects.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final sub = provider.filteredSubjects[index];
                          return _buildSubjectCard(context, sub, isDark, provider);
                        },
                      ),
          ),

          // Bottom "+ Add Subject" Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
            child: NestButton(
              label: '+ Add Subject',
              icon: Icons.add_rounded,
              onPressed: () => _showAddSubjectDialog(context, provider),
              variant: NestButtonVariant.primary,
              isFullWidth: true,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index, bool isDark) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.forestEmerald : AppColors.deepForest)
                : Colors.transparent,
            borderRadius: AppRadius.roundedFull,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(SyllabusProvider provider, bool isDark) {
    final filters = ['All', 'In Progress', 'Revision Needed', 'Restudy Needed', 'Completed'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = provider.selectedFilter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(f),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) provider.setFilter(f);
                },
                selectedColor: isDark ? AppColors.darkElevated : AppColors.sageTint,
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.deepForest
                      : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.deepForest
                      : (isDark ? AppColors.darkBorder : AppColors.borderSubtle),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildQueuePills(SyllabusProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      child: Row(
        children: [
          if (provider.revisionQueue.isNotEmpty) ...[
            GestureDetector(
              onTap: () => provider.setFilter('Revision Needed'),
              child: NestBadge(
                label: '${provider.revisionQueue.length} In Revision Queue',
                variant: NestBadgeVariant.lavender,
                icon: Icons.history_rounded,
                isDense: true,
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (provider.restudyQueue.isNotEmpty) ...[
            GestureDetector(
              onTap: () => provider.setFilter('Restudy Needed'),
              child: NestBadge(
                label: '${provider.restudyQueue.length} In Restudy Queue',
                variant: NestBadgeVariant.coral,
                icon: Icons.refresh_rounded,
                isDense: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, SubjectModel sub, bool isDark, SyllabusProvider provider) {
    return GestureDetector(
      onTap: () => _openSubject(context, sub),
      child: NestCard(
        color: isDark ? AppColors.darkCard : AppColors.cardSurface,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 48,
              decoration: BoxDecoration(
                color: sub.color,
                borderRadius: AppRadius.roundedFull,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.name,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${sub.completedChapters}/${sub.totalChapters} chapters • ${sub.completedSubtopics}/${sub.totalSubtopics} topics',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Circular progress gauge
            NestCircularProgress(
              progress: sub.progress,
              size: 44,
              strokeWidth: 4,
              progressColor: sub.color,
              backgroundColor: isDark ? AppColors.darkBorder : AppColors.warmCream,
              centerWidget: Text(
                '${(sub.progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textMuted),
              padding: EdgeInsets.zero,
              onSelected: (action) {
                if (action == 'edit') {
                  _showEditSubjectDialog(context, sub, provider);
                } else if (action == 'delete') {
                  _showDeleteSubjectDialog(context, sub, provider);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit Subject'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.urgentRed),
                      const SizedBox(width: 8),
                      Text('Delete Subject', style: TextStyle(color: AppColors.urgentRed)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
