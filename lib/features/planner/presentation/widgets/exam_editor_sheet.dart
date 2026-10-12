import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/nest_badge.dart';
import '../../../../core/widgets/nest_button.dart';
import '../../../../core/widgets/nest_card.dart';
import '../providers/planner_provider.dart';

class ExamEditorSheet extends StatefulWidget {
  const ExamEditorSheet({super.key});

  @override
  State<ExamEditorSheet> createState() => _ExamEditorSheetState();
}

class _ExamEditorSheetState extends State<ExamEditorSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _targetScoreController = TextEditingController(text: '95');
  DateTime _selectedExamDate = DateTime.now().add(const Duration(days: 30));
  String _selectedColor = '#E8833A';
  bool _isAdding = false;

  final _palette = [
    '#E8833A', // Orange
    '#4A7C59', // Green
    '#3B8A6E', // Forest
    '#D49B3E', // Amber
    '#4B88B4', // Blue
    '#DE5D83', // Pink
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _targetScoreController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedExamDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() => _selectedExamDate = picked);
    }
  }

  void _saveExam(PlannerProvider provider) {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final target = int.tryParse(_targetScoreController.text.trim());

    provider.addExam(
      title: title,
      examDate: _selectedExamDate,
      targetScore: target,
      colorHex: _selectedColor,
    );

    _titleController.clear();
    setState(() => _isAdding = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<PlannerProvider>(context);
    final exams = provider.exams;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.cardSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Upcoming Exams & Targets', style: AppTypography.titleLarge),
                  IconButton(
                    icon: Icon(_isAdding ? Icons.close_rounded : Icons.add_rounded),
                    onPressed: () => setState(() => _isAdding = !_isAdding),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_isAdding) ...[
                NestCard(
                  color: isDark ? AppColors.darkCard : AppColors.ivoryCanvas,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add Target Exam', style: AppTypography.titleSmall),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Exam Title',
                          hintText: 'e.g. CBSE Physics Board Exam',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.event_rounded, size: 18),
                              label: Text(
                                '${_selectedExamDate.day}/${_selectedExamDate.month}/${_selectedExamDate.year}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              onPressed: _pickDate,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: _targetScoreController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Target %',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: _palette.map((hex) {
                          final isChosen = _selectedColor == hex;
                          final c = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = hex),
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isChosen ? Colors.black87 : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: NestButton(
                          label: 'Save Exam Target',
                          onPressed: () => _saveExam(provider),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (exams.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No upcoming exams scheduled yet.'),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: exams.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final exam = exams[i];
                    final color = exam.colorHex != null
                        ? Color(int.parse('FF${exam.colorHex!.replaceAll('#', '')}', radix: 16))
                        : AppColors.sageGreen;

                    return NestCard(
                      color: isDark ? AppColors.darkCard : AppColors.cardSurface,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: AppRadius.roundedFull,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exam.title,
                                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Target: ${exam.targetScore ?? 90}% • ${exam.examDate.day}/${exam.examDate.month}/${exam.examDate.year}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          NestBadge(
                            label: '${exam.daysRemaining} days left',
                            variant: exam.daysRemaining <= 14 ? NestBadgeVariant.amber : NestBadgeVariant.sage,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => provider.deleteExam(exam.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
