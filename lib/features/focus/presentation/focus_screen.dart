import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/forest_tree_model.dart';
import '../../../core/services/ambience_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/ambience_control_sheet.dart';
import '../../../core/widgets/nest_button.dart';
import '../../../core/widgets/nest_progress_bar.dart';
import '../../distraction_control/presentation/app_blocker_screen.dart';
import '../../distraction_control/presentation/providers/app_blocker_provider.dart';
import '../../distraction_control/presentation/widgets/distraction_shield_dialog.dart';
import '../../syllabus/presentation/providers/syllabus_provider.dart';
import '../models/active_session_model.dart';
import '../../navbloom/presentation/providers/forest_provider.dart';
import 'providers/focus_session_provider.dart';

class FocusScreen extends StatefulWidget {
  final VoidCallback? onSessionComplete;
  final String? initialSubject;
  final String? initialChapter;
  final String? initialSubtopic;
  final String? linkedTaskId;

  const FocusScreen({
    super.key,
    this.onSessionComplete,
    this.initialSubject,
    this.initialChapter,
    this.initialSubtopic,
    this.linkedTaskId,
  });

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  FocusTimerMode _selectedMode = FocusTimerMode.pomodoro;
  int _configuredTargetSeconds = 25 * 60;

  String _selectedSubject = 'Mathematics';
  String _selectedChapter = 'Real Numbers';
  String? _selectedSubtopic;
  TreeSpecies _selectedSpecies = TreeSpecies.cherryBlossom;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focusProvider = Provider.of<FocusSessionProvider>(context, listen: false);
      if (focusProvider.hasActiveSession) {
        setState(() {
          _selectedSubject = focusProvider.subjectName;
          _selectedChapter = focusProvider.chapterName;
          _selectedSubtopic = focusProvider.subtopicName;
          _selectedSpecies = focusProvider.treeSpecies;
          _selectedMode = focusProvider.mode;
        });
      } else if (widget.initialSubject != null) {
        setState(() {
          _selectedSubject = widget.initialSubject!;
          _selectedChapter = widget.initialChapter ?? 'General';
          _selectedSubtopic = widget.initialSubtopic;
        });
      } else {
        final syllabus = Provider.of<SyllabusProvider>(context, listen: false);
        if (syllabus.subjects.isNotEmpty && widget.initialSubject == null) {
          setState(() {
            _selectedSubject = syllabus.subjects.first.name;
            if (syllabus.subjects.first.chapters.isNotEmpty) {
              _selectedChapter = syllabus.subjects.first.chapters.first.name;
            }
          });
        }
      }
    });
  }

  void _toggleTimer(FocusSessionProvider provider) async {
    if (provider.isRunning) {
      await provider.pauseSession();
    } else if (provider.isPaused) {
      await provider.resumeSession();
    } else if (!provider.hasActiveSession) {
      await _startPlantingFlow(provider);
    }
  }

  Future<void> _startPlantingFlow(FocusSessionProvider provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSurface
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _selectedSpecies.themeColor.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _selectedSpecies.themeColor.withValues(alpha: 0.3),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_selectedSpecies.iconEmoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'Planting Seed... 🌱',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _selectedSpecies.themeColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Growing ${_selectedSpecies.displayName} in Whispering Meadow',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextMuted
                      : AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 140,
                child: LinearProgressIndicator(
                  color: _selectedSpecies.themeColor,
                  backgroundColor: _selectedSpecies.themeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      await provider.startSession(
        mode: _selectedMode,
        targetSeconds: _selectedMode == FocusTimerMode.stopwatch ? 0 : _configuredTargetSeconds,
        subjectName: _selectedSubject,
        chapterName: _selectedChapter,
        subtopicName: _selectedSubtopic,
        linkedTaskId: widget.linkedTaskId,
        treeSpecies: _selectedSpecies,
      );
    }
  }

  void _resetTimer(FocusSessionProvider provider) async {
    await provider.stopSession(cancelled: true);
  }

  void _handleSessionCompletion(FocusSessionProvider provider) async {
    await provider.completeSession();
    if (mounted) {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _selectedSpecies.themeColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _selectedSpecies.themeColor.withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _selectedSpecies.themeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _selectedSpecies.themeColor.withValues(alpha: 0.4), width: 2),
                ),
                child: Center(
                  child: Text(_selectedSpecies.iconEmoji, style: const TextStyle(fontSize: 44)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Great Focus!',
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Your tree has grown! 🌟',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _selectedSpecies.themeColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_selectedSpecies.displayName} planted in Whispering Meadow',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.sageTint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.sageBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: AppColors.amberHoney, size: 24),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Reward', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text('+80 XP', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    Container(width: 1, height: 32, color: Colors.grey.withValues(alpha: 0.2)),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded, color: AppColors.coinGold, size: 24),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Coins', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text('+25 Coins', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCanvas : AppColors.ivoryCanvas,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book_rounded, size: 16, color: isDark ? AppColors.forestEmerald : AppColors.deepForest),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '$_selectedSubject: $_selectedChapter',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              NestButton(
                label: 'Collect & View Sanctuary',
                onPressed: () {
                  Navigator.pop(dialogContext);
                  widget.onSessionComplete?.call();
                },
                variant: NestButtonVariant.primary,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTopicSelectorSheet() {
    final syllabus = Provider.of<SyllabusProvider>(context, listen: false);
    final subjects = syllabus.subjects;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final currSub = subjects.firstWhere(
              (s) => s.name == _selectedSubject,
              orElse: () => subjects.isNotEmpty ? subjects.first : subjects.first,
            );
            final chapters = currSub.chapters.map((c) => c.name).toList();

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.cardSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
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
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Select Study Topic', style: AppTypography.titleLarge),
                    const SizedBox(height: 16),

                    Text('CBSE Class 10 Subject', style: AppTypography.titleSmall),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.ivoryCanvas,
                        borderRadius: AppRadius.roundedM,
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSubject,
                          isExpanded: true,
                          items: subjects.map((s) {
                            return DropdownMenuItem(value: s.name, child: Text(s.name));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                _selectedSubject = val;
                                final newSub = subjects.firstWhere((s) => s.name == val);
                                _selectedChapter = newSub.chapters.isNotEmpty
                                    ? newSub.chapters.first.name
                                    : 'General';
                              });
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (chapters.isNotEmpty) ...[
                      Text('Chapter', style: AppTypography.titleSmall),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.ivoryCanvas,
                          borderRadius: AppRadius.roundedM,
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: chapters.contains(_selectedChapter) ? _selectedChapter : chapters.first,
                            isExpanded: true,
                            items: chapters.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => _selectedChapter = val);
                                setState(() => _selectedChapter = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Text('Tree Species Growing', style: AppTypography.titleSmall),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: TreeSpecies.values.map((sp) {
                          final isSel = _selectedSpecies == sp;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() => _selectedSpecies = sp);
                              setState(() => _selectedSpecies = sp);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel ? sp.themeColor.withValues(alpha: 0.2) : (isDark ? AppColors.darkCard : AppColors.warmCream),
                                borderRadius: AppRadius.roundedM,
                                border: Border.all(color: isSel ? sp.themeColor : Colors.transparent, width: 2),
                              ),
                              child: Row(
                                children: [
                                  Text(sp.iconEmoji, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 4),
                                  Text(sp.displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),
                    NestButton(
                      label: 'Confirm Topic & Tree',
                      onPressed: () => Navigator.pop(ctx),
                      isFullWidth: true,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDisplayTime(FocusSessionProvider provider) {
    final isStopwatch = provider.hasActiveSession
        ? provider.mode == FocusTimerMode.stopwatch
        : _selectedMode == FocusTimerMode.stopwatch;

    int totalSeconds;
    if (isStopwatch) {
      totalSeconds = provider.hasActiveSession ? provider.elapsedActiveSeconds : 0;
    } else {
      totalSeconds = provider.hasActiveSession ? provider.remainingSeconds : _configuredTargetSeconds;
    }

    final hours = totalSeconds ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;
    final secs = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _getTreeStageDescription(FocusSessionProvider provider) {
    final mins = provider.hasActiveSession ? (provider.elapsedActiveSeconds ~/ 60) : 0;
    if (mins >= 90) return 'Stage 5: Full Bloom 🌸';
    if (mins >= 60) return 'Stage 4: Young Tree 🌳';
    if (mins >= 40) return 'Stage 3: Sapling 🌿';
    if (mins >= 20) return 'Stage 2: Sprout 🌱';
    return 'Stage 1: Planted Seed ✨';
  }

  String _getMotivationalQuote(int elapsedSeconds) {
    const quotes = [
      'Don\'t look at me! Keep studying! 📚',
      'Put down your phone and focus! ✨',
      'Stay focused on your CBSE syllabus! 🌿',
      'Every minute of study grows your mind 🌱',
      'Don\'t let this seedling wither! 🌸',
      'One chapter at a time. You\'ve got this! 🎯',
      'Deep work leads to extraordinary mastery 💡',
      'Plant your tree and achieve greatness! 🌳',
    ];
    final index = (elapsedSeconds ~/ 15) % quotes.length;
    return quotes[index];
  }

  void _confirmGiveUp(FocusSessionProvider focusProvider, ForestProvider forestProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: const [
            Text('🥀', style: TextStyle(fontSize: 26)),
            SizedBox(width: 8),
            Text('Give Up Focus?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'If you give up now, your lovely ${_selectedSpecies.displayName} will wither and die!',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.urgentRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.urgentRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: AppColors.urgentRed, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A withered, leafless tree will be planted in your forest as a reminder.',
                      style: TextStyle(fontSize: 11, color: AppColors.urgentRed, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Focusing 🌱', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.urgentRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final elapsedMins = focusProvider.elapsedActiveSeconds ~/ 60;
              await forestProvider.plantWitheredTree(
                species: _selectedSpecies,
                subjectName: _selectedSubject,
                chapterName: _selectedChapter,
                focusMinutes: elapsedMins,
                sessionId: focusProvider.session?.id,
              );
              await focusProvider.stopSession(cancelled: true);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Your tree withered in the sanctuary 🥀. Stay strong next time!'),
                    backgroundColor: AppColors.urgentRed,
                  ),
                );
              }
            },
            child: const Text('Give Up'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = NavThemeColors.of(context);
    final isDark = colors.isDark;
    final focusProvider = context.watch<FocusSessionProvider>();
    final forest = context.watch<ForestProvider>();
    final ambience = context.watch<AmbienceProvider>();
    final blocker = context.watch<AppBlockerProvider>();

    if (blocker.pendingInterventionPackage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final pkg = blocker.pendingInterventionPackage;
        if (pkg != null && mounted) {
          DistractionShieldDialog.show(context, pkg);
        }
      });
    }

    final isRunning = focusProvider.isRunning;
    final isPaused = focusProvider.isPaused;
    final hasSession = focusProvider.hasActiveSession;
    final isCompleted = focusProvider.isCompleted && !hasSession;

    final subject = hasSession ? focusProvider.subjectName : _selectedSubject;
    final chapter = hasSession ? focusProvider.chapterName : _selectedChapter;
    final species = hasSession ? focusProvider.treeSpecies : _selectedSpecies;

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        title: Text('Focus Session', style: AppTypography.titleLarge.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: colors.primary),
        actions: [
          if (hasSession)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reset Timer',
              onPressed: () => _resetTimer(focusProvider),
            ),
          IconButton(
            icon: Icon(
              ambience.hasActiveAudio ? Icons.headphones_rounded : Icons.headphones_outlined,
              color: ambience.hasActiveAudio ? colors.primary : colors.primary,
            ),
            tooltip: 'Study Ambience',
            onPressed: () => AmbienceControlSheet.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Reboot Recovery Notice if device rebooted while timer was active
            if (focusProvider.isInterrupted) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.amberHoney.withValues(alpha: isDark ? 0.2 : 0.15),
                  borderRadius: AppRadius.roundedM,
                  border: Border.all(color: AppColors.amberHoney),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.power_settings_new_rounded, color: AppColors.amberHoney, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Phone Reboot Recovered',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.amberHoney),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${focusProvider.elapsedActiveSeconds ~/ 60}m focus preserved prior to reboot without drift.',
                            style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.amberHoney,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () => _handleSessionCompletion(focusProvider),
                      child: const Text('Save Harvest', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ],

            // Completed Session Celebration Banner
            if (isCompleted) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.safeGreen.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: AppRadius.roundedL,
                  border: Border.all(color: AppColors.safeGreen, width: 1.4),
                  boxShadow: AppShadows.softCard,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.safeGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Session Completed! 🌸',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.safeGreen,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tree planted in Sanctuary • Genuine study recorded',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () => focusProvider.clearCompletedSession(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.safeGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Start New', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],

            // Subject & Chapter Tag Pill (Interactive)
            GestureDetector(
              onTap: hasSession ? null : _showTopicSelectorSheet,
              child: _buildSubjectTag(subject, chapter, colors, hasSession),
            ),

            const SizedBox(height: 18),

            // Tree Selection Carousel (When not in active session)
            if (!hasSession) ...[
              _buildTreeSelectionCarousel(colors, isDark),
              const SizedBox(height: 16),
              _buildDurationPresets(colors, isDark),
              const SizedBox(height: 20),
            ],

            // Motivational Study Quote (Forest trademark)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors.borderSubtle,
                ),
              ),
              child: Text(
                _getMotivationalQuote(focusProvider.elapsedActiveSeconds),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: colors.textPrimary,
                ),
              ),
            ),

            // Central Circular Focus Ring with Sprouting Seed & Monotonic Timer
            _buildTimerRing(focusProvider, species, colors, isDark),

            const SizedBox(height: 16),

            // Ambience Quick-Selector Pills Bar
            _buildAmbienceQuickBar(colors, isDark, ambience),

            const SizedBox(height: 14),

            // Live Tree Stage Progression Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: AppRadius.roundedFull,
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(species.iconEmoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    _getTreeStageDescription(focusProvider),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // Controls: Start/Pause/Resume, Finish Early, and Give Up (Wither Tree)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: hasSession ? 120 : 160,
                  child: NestButton(
                    label: isRunning ? 'Pause' : (isPaused ? 'Resume' : 'Start Focus'),
                    icon: isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    onPressed: () => _toggleTimer(focusProvider),
                    variant: NestButtonVariant.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                if (hasSession && (focusProvider.elapsedActiveSeconds >= 60 || isRunning)) ...[
                  const SizedBox(width: 10),
                  FilledButton.tonalIcon(
                    onPressed: () => _handleSessionCompletion(focusProvider),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: const Text('Finish', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
                if (hasSession) ...[
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => _confirmGiveUp(focusProvider, forest),
                    icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.urgentRed),
                    label: const Text('Give Up', style: TextStyle(color: AppColors.urgentRed, fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.urgentRed.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 28),

            // Bottom Action Shortcuts: Block Apps • Forest Sanctuary • Ambient Noise
            _buildBottomShortcuts(colors, isDark, ambience, blocker),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectTag(String subject, String chapter, NavThemeColors colors, bool isLocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadius.roundedFull,
        border: Border.all(color: colors.borderSubtle),
        boxShadow: AppShadows.softCard,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark_rounded, color: colors.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            '$subject • $chapter',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          if (!isLocked) ...[
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: colors.primary),
          ],
        ],
      ),
    );
  }

  Widget _buildTimerRing(FocusSessionProvider provider, TreeSpecies species, NavThemeColors colors, bool isDark) {
    final progress = provider.hasActiveSession ? provider.progressRatio : 0.0;
    final isRunning = provider.isRunning;
    final isPaused = provider.isPaused;

    String subtitle;
    if (isRunning) {
      if (provider.mode == FocusTimerMode.pomodoro) {
        subtitle = 'Pomodoro: ${provider.pomodoroPhase.name.toUpperCase()} (Cycle ${provider.pomodoroCycle})';
      } else if (provider.mode == FocusTimerMode.stopwatch) {
        subtitle = 'Stopwatch • Counting Up • Monotonic';
      } else {
        subtitle = 'Deep Work • Monotonic Protected';
      }
    } else if (isPaused) {
      subtitle = 'Paused ⏸️ • Screen-Off Safe';
    } else if (provider.isCompleted) {
      subtitle = 'Session Completed 🌸';
    } else if (_selectedMode == FocusTimerMode.stopwatch) {
      subtitle = 'Stopwatch Mode • Counts Up';
    } else {
      subtitle = 'Ready to Grow Tree';
    }

    return NestCircularProgress(
      progress: progress,
      size: 240,
      strokeWidth: 10,
      progressColor: species.themeColor,
      backgroundColor: colors.surfaceCard,
      centerWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: species.themeColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(species.iconEmoji, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 10),
          Text(
            _formatDisplayTime(provider),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeSelectionCarousel(NavThemeColors colors, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CHOOSE A TREE TO GROW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: colors.textMuted,
                ),
              ),
              Text(
                _selectedSpecies.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _selectedSpecies.themeColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: TreeSpecies.values.length,
            itemBuilder: (context, index) {
              final sp = TreeSpecies.values[index];
              final isSelected = sp == _selectedSpecies;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSpecies = sp;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 82,
                  margin: EdgeInsets.only(right: index == TreeSpecies.values.length - 1 ? 0 : 10),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? sp.themeColor.withValues(alpha: isDark ? 0.25 : 0.15)
                        : colors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? sp.themeColor : colors.borderSubtle,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: sp.themeColor.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(sp.iconEmoji, style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 6),
                      Text(
                        sp.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? (isDark ? Colors.white : sp.themeColor)
                              : colors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDurationPresets(NavThemeColors colors, bool isDark) {
    final presets = [
      {'label': '25m', 'sub': 'Pomodoro', 'mode': FocusTimerMode.pomodoro, 'sec': 25 * 60},
      {'label': '50m', 'sub': 'Deep Work', 'mode': FocusTimerMode.custom, 'sec': 50 * 60},
      {'label': '75m', 'sub': 'Exam Prep', 'mode': FocusTimerMode.custom, 'sec': 75 * 60},
      {'label': '120m', 'sub': 'Mastery', 'mode': FocusTimerMode.custom, 'sec': 120 * 60},
      {'label': 'Stopwatch', 'sub': 'Free Count', 'mode': FocusTimerMode.stopwatch, 'sec': 0},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: presets.map((p) {
          final isSelected = _selectedMode == p['mode'] &&
              (_selectedMode == FocusTimerMode.stopwatch || _configuredTargetSeconds == p['sec']);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMode = p['mode'] as FocusTimerMode;
                _configuredTargetSeconds = p['sec'] as int;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary
                    : colors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? colors.primary
                      : colors.borderSubtle,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    p['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : colors.textPrimary,
                    ),
                  ),
                  Text(
                    p['sub'] as String,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white.withValues(alpha: 0.8) : colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAmbienceQuickBar(NavThemeColors colors, bool isDark, AmbienceProvider ambience) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: AmbienceTrack.values.map((track) {
          final isSelected = ambience.currentTrack == track && (track == AmbienceTrack.none || ambience.isPlaying);
          return GestureDetector(
            onTap: () async {
              if (isSelected && track != AmbienceTrack.none) {
                await ambience.pause();
              } else {
                await ambience.selectTrack(track);
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary.withValues(alpha: isDark ? 0.25 : 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? colors.primary : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Text(track.iconEmoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    track.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? colors.primary
                          : colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomShortcuts(NavThemeColors colors, bool isDark, AmbienceProvider ambience, AppBlockerProvider blocker) {
    final hasAudio = ambience.hasActiveAudio;
    final soundLabel = hasAudio ? '${ambience.currentTrack.displayName} ON' : 'Study Ambience';
    final isShieldActive = blocker.isShieldActiveNow;
    final shieldLabel = isShieldActive ? 'Shield ON 🛡️' : (blocker.isAccessibilityEnabled ? 'Shield Ready' : 'Block Apps');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildShortcutItem(
          isShieldActive ? Icons.shield_rounded : Icons.block_rounded,
          shieldLabel,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppBlockerScreen())),
          colors,
          isDark,
          isActive: isShieldActive,
        ),
        _buildShortcutItem(
          Icons.park_rounded,
          'Sanctuary',
          () {
            Navigator.pop(context);
            widget.onSessionComplete?.call();
          },
          colors,
          isDark,
          isActive: false,
        ),
        _buildShortcutItem(
          hasAudio ? Icons.headphones_rounded : Icons.headphones_outlined,
          soundLabel,
          () => AmbienceControlSheet.show(context),
          colors,
          isDark,
          isActive: hasAudio,
        ),
      ],
    );
  }

  Widget _buildShortcutItem(
    IconData icon,
    String label,
    VoidCallback onTap,
    NavThemeColors colors,
    bool isDark, {
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive
                  ? colors.primary.withValues(alpha: isDark ? 0.25 : 0.15)
                  : colors.surfaceCard,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? colors.primary
                    : colors.borderSubtle,
                width: isActive ? 1.6 : 1.0,
              ),
              boxShadow: AppShadows.softCard,
            ),
            child: Icon(
              icon,
              color: isActive ? colors.primary : colors.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
              color: isActive
                  ? colors.primary
                  : colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
