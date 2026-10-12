import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/exam_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/nest_badge.dart';
import '../../../../core/widgets/nest_button.dart';
import '../../../../core/widgets/nest_card.dart';
import '../providers/planner_provider.dart';

class ExamEditorSheet extends StatefulWidget {
  final ExamModel? initialExamToEdit;

  const ExamEditorSheet({super.key, this.initialExamToEdit});

  @override
  State<ExamEditorSheet> createState() => _ExamEditorSheetState();
}

class _ExamEditorSheetState extends State<ExamEditorSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _targetScoreController = TextEditingController(text: '95');
  DateTime _selectedExamDate = DateTime.now().add(const Duration(days: 30));
  String _selectedColor = '#E8833A';
  bool _isAdding = false;
  String? _editingExamId;

  final _palette = [
    '#E8833A', // Orange
    '#4A7C59', // Green
    '#3B8A6E', // Forest
    '#D49B3E', // Amber
    '#4B88B4', // Blue
    '#DE5D83', // Pink
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialExamToEdit != null) {
      _startEditing(widget.initialExamToEdit!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetScoreController.dispose();
    super.dispose();
  }

  void _startEditing(ExamModel exam) {
    setState(() {
      _isAdding = true;
      _editingExamId = exam.id;
      _titleController.text = exam.title;
      _targetScoreController.text = (exam.targetScore ?? 95).toString();
      _selectedExamDate = exam.examDate;
      _selectedColor = exam.colorHex ?? '#E8833A';
    });
  }

  void _resetForm() {
    _titleController.clear();
    _targetScoreController.text = '95';
    setState(() {
      _isAdding = false;
      _editingExamId = null;
      _selectedExamDate = DateTime.now().add(const Duration(days: 30));
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedExamDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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

    if (_editingExamId != null) {
      final existing = provider.exams.firstWhere(
        (e) => e.id == _editingExamId,
        orElse: () => ExamModel(
          id: _editingExamId!,
          title: title,
          examDate: _selectedExamDate,
          createdAt: DateTime.now(),
        ),
      );
      final updated = existing.copyWith(
        title: title,
        examDate: _selectedExamDate,
        targetScore: target,
        colorHex: _selectedColor,
      );
      provider.updateExam(updated);
    } else {
      provider.addExam(
        title: title,
        examDate: _selectedExamDate,
        targetScore: target,
        colorHex: _selectedColor,
      );
    }

    _resetForm();
  }

  void _confirmDelete(BuildContext context, PlannerProvider provider, ExamModel exam) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exam?'),
        content: Text('Are you sure you want to remove "${exam.title}" from your targets?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.urgentRed),
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteExam(exam.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<PlannerProvider>(context);
    final exams = provider.exams;

    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
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
                  Text(
                    'Upcoming Exams & Targets',
                    style: AppTypography.titleLarge.copyWith(color: textPrimary),
                  ),
                  IconButton(
                    icon: Icon(_isAdding ? Icons.close_rounded : Icons.add_rounded, color: textPrimary),
                    onPressed: () {
                      if (_isAdding) {
                        _resetForm();
                      } else {
                        setState(() => _isAdding = true);
                      }
                    },
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _editingExamId != null ? 'Edit Target Exam' : 'Add Target Exam',
                            style: AppTypography.titleSmall.copyWith(color: textPrimary, fontWeight: FontWeight.bold),
                          ),
                          if (_editingExamId != null)
                            TextButton(
                              onPressed: _resetForm,
                              child: const Text('Cancel Edit', style: TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _titleController,
                        style: TextStyle(color: textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Exam Title',
                          hintText: 'e.g. CBSE Mathematics Board Exam 2027',
                          labelStyle: TextStyle(color: textMuted),
                          hintStyle: TextStyle(color: textMuted),
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
                            width: 110,
                            child: TextField(
                              controller: _targetScoreController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Target %',
                                labelStyle: TextStyle(color: textMuted),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: _palette.map((hex) {
                          final isChosen = _selectedColor == hex;
                          final c = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = hex),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isChosen ? (isDark ? Colors.white : Colors.black87) : Colors.transparent,
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
                          label: _editingExamId != null ? 'Update Exam' : 'Save Exam Target',
                          icon: _editingExamId != null ? Icons.check_circle_outline : Icons.add_rounded,
                          onPressed: () => _saveExam(provider),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (exams.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No upcoming exams scheduled yet.\nTap "+" above to add your CBSE board exams.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textMuted, height: 1.4),
                    ),
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

                    final isBeingEdited = _editingExamId == exam.id;

                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.cardSurface,
                        borderRadius: AppRadius.roundedL,
                        border: Border.all(
                          color: isBeingEdited
                              ? AppColors.deepForest
                              : (isDark ? AppColors.darkBorder : AppColors.borderSubtle),
                          width: isBeingEdited ? 1.5 : 1,
                        ),
                        boxShadow: AppShadows.softCard,
                      ),
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
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Target: ${exam.targetScore ?? 90}% • ${exam.examDate.day}/${exam.examDate.month}/${exam.examDate.year}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: textMuted,
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
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            color: isDark ? AppColors.darkTextSecondary : AppColors.deepForest,
                            tooltip: 'Edit Exam',
                            onPressed: () => _startEditing(exam),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            color: AppColors.urgentRed,
                            tooltip: 'Delete Exam',
                            onPressed: () => _confirmDelete(context, provider, exam),
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
