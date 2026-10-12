import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/planner_task_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/nest_button.dart';
import '../../../syllabus/presentation/providers/syllabus_provider.dart';
import '../providers/planner_provider.dart';

class TaskEditorSheet extends StatefulWidget {
  final PlannerTaskModel? existingTask;
  final DateTime defaultDate;

  const TaskEditorSheet({
    super.key,
    this.existingTask,
    required this.defaultDate,
  });

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  String? _selectedSubjectId;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int _plannedMinutes = 45;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _notesController = TextEditingController(text: task?.notes ?? '');
    _selectedDate = task != null ? (DateTime.tryParse(task.date) ?? widget.defaultDate) : widget.defaultDate;
    _selectedSubjectId = task?.subjectId;
    _plannedMinutes = task?.plannedMinutes ?? 45;

    if (task?.startTime != null) {
      _startTime = _parseTimeOfDay(task!.startTime!);
    } else {
      _startTime = const TimeOfDay(hour: 9, minute: 0);
    }

    if (task?.endTime != null) {
      _endTime = _parseTimeOfDay(task!.endTime!);
    } else {
      _endTime = const TimeOfDay(hour: 10, minute: 30);
    }
  }

  TimeOfDay? _parseTimeOfDay(String timeStr) {
    try {
      final parts = timeStr.replaceAll(RegExp(r'\s+[AP]M', caseSensitive: false), '').split(':');
      var hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      if (timeStr.toUpperCase().contains('PM') && hour < 12) hour += 12;
      if (timeStr.toUpperCase().contains('AM') && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _recalculateDuration() {
    if (_startTime != null && _endTime != null) {
      final startMins = _startTime!.hour * 60 + _startTime!.minute;
      final endMins = _endTime!.hour * 60 + _endTime!.minute;
      var diff = endMins - startMins;
      if (diff <= 0) diff += 24 * 60; // Rollover midnight
      if (diff > 0 && diff <= 360) {
        setState(() {
          _plannedMinutes = diff;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)), // 1 year past
      lastDate: DateTime.now().add(const Duration(days: 365)),     // 1 year future
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        _recalculateDuration();
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
        _recalculateDuration();
      });
    }
  }

  void _saveTask(PlannerProvider plannerProvider) {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    final startStr = _startTime != null ? _formatTimeOfDay(_startTime!) : null;
    final endStr = _endTime != null ? _formatTimeOfDay(_endTime!) : null;

    if (widget.existingTask != null) {
      // Update
      final updated = widget.existingTask!.copyWith(
        title: title,
        date: '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
        subjectId: _selectedSubjectId,
        startTime: startStr,
        endTime: endStr,
        plannedMinutes: _plannedMinutes,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      plannerProvider.updateTask(updated);
    } else {
      // Create new
      plannerProvider.addTask(
        title: title,
        date: _selectedDate,
        subjectId: _selectedSubjectId,
        startTime: startStr,
        endTime: endStr,
        plannedMinutes: _plannedMinutes,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final syllabusProvider = Provider.of<SyllabusProvider>(context, listen: false);
    final plannerProvider = Provider.of<PlannerProvider>(context, listen: false);
    final subjects = syllabusProvider.subjects;

    final isEdit = widget.existingTask != null;

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
              // Pill handle
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

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit Planned Task' : 'Plan New Study Session',
                    style: AppTypography.titleLarge,
                  ),
                  if (isEdit)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.urgentRed),
                      tooltip: 'Delete Task',
                      onPressed: () {
                        plannerProvider.deleteTask(widget.existingTask!.id);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Title input
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Task Title or Chapter Topic',
                  hintText: 'e.g. Physics: Kinematics NCERT exercises',
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : AppColors.ivoryCanvas,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.roundedM,
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Subject selector
              Text('Linked Subject', style: AppTypography.labelLarge),
              const SizedBox(height: 8),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: subjects.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      final isSelected = _selectedSubjectId == null;
                      return ChoiceChip(
                        label: const Text('General / Other'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedSubjectId = null);
                        },
                      );
                    }
                    final sub = subjects[i - 1];
                    final isSelected = _selectedSubjectId == sub.id;
                    return ChoiceChip(
                      avatar: CircleAvatar(
                        backgroundColor: sub.color,
                        radius: 6,
                      ),
                      label: Text(sub.name),
                      selected: isSelected,
                      selectedColor: sub.color.withValues(alpha: 0.25),
                      onSelected: (selected) {
                        setState(() => _selectedSubjectId = selected ? sub.id : null);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Date Picker
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event_rounded, size: 18),
                      label: Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: _pickDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Time Range Pickers
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time_rounded, size: 18),
                      label: Text(
                        _startTime != null ? _formatTimeOfDay(_startTime!) : 'Start Time',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: _pickStartTime,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('→', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time_filled_rounded, size: 18),
                      label: Text(
                        _endTime != null ? _formatTimeOfDay(_endTime!) : 'End Time',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: _pickEndTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Planned Minutes Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Planned Duration', style: AppTypography.labelLarge),
                  Text('$_plannedMinutes mins', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.sageGreen)),
                ],
              ),
              Slider(
                value: _plannedMinutes.toDouble(),
                min: 15,
                max: 180,
                divisions: 11,
                label: '$_plannedMinutes mins',
                activeColor: AppColors.sageGreen,
                onChanged: (val) => setState(() => _plannedMinutes = val.toInt()),
              ),

              // Notes input
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Session Goal & Notes (Optional)',
                  hintText: 'e.g. Solve 10 PYQs, review formula sheet',
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : AppColors.ivoryCanvas,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.roundedM,
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                child: NestButton(
                  label: isEdit ? 'Update Task' : 'Save Planned Task',
                  icon: isEdit ? Icons.check_rounded : Icons.add_task_rounded,
                  onPressed: () => _saveTask(plannerProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
