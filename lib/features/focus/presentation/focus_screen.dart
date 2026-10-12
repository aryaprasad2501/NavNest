import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/forest_tree_model.dart';
import '../../../core/models/study_session_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nest_button.dart';
import '../../../core/widgets/nest_progress_bar.dart';
import '../../distraction_control/presentation/app_blocker_screen.dart';
import '../../navbloom/presentation/providers/forest_provider.dart';
import '../../syllabus/presentation/providers/syllabus_provider.dart';

enum TimerMode { pomodoro, custom, stopwatch }

class FocusScreen extends StatefulWidget {
  final VoidCallback? onSessionComplete;

  const FocusScreen({super.key, this.onSessionComplete});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  TimerMode _mode = TimerMode.pomodoro;
  bool _isRunning = false;
  int _targetSeconds = 25 * 60;
  int _elapsedSeconds = 0;
  Timer? _timer;
  DateTime? _sessionStartTime;

  String _selectedSubject = 'Mathematics';
  String _selectedChapter = 'Real Numbers';
  TreeSpecies _selectedSpecies = TreeSpecies.cherryBlossom;
  bool _whiteNoiseActive = false;

  @override
  void initState() {
    super.initState();
    // Default subject & chapter from SyllabusProvider if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final syllabus = Provider.of<SyllabusProvider>(context, listen: false);
      if (syllabus.subjects.isNotEmpty) {
        setState(() {
          _selectedSubject = syllabus.subjects.first.name;
          if (syllabus.subjects.first.chapters.isNotEmpty) {
            _selectedChapter = syllabus.subjects.first.chapters.first.name;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      _sessionStartTime ??= DateTime.now();
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _elapsedSeconds++;
          if (_mode != TimerMode.stopwatch && _elapsedSeconds >= _targetSeconds) {
            _timer?.cancel();
            _isRunning = false;
            _handleSessionCompletion();
          }
        });
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _elapsedSeconds = 0;
      _sessionStartTime = null;
    });
  }

  Future<void> _handleSessionCompletion() async {
    final focusMins = (_elapsedSeconds / 60).round();
    final now = DateTime.now();
    final startedAt = _sessionStartTime ?? now.subtract(Duration(seconds: _elapsedSeconds));

    if (focusMins < 1 && _elapsedSeconds < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessions under 1 minute are not saved to the forest.')),
      );
      _resetTimer();
      return;
    }

    // Effective minutes for XP/coins calculation (minimum 1)
    final effectiveMins = focusMins < 1 ? 1 : focusMins;

    // 1. Plant tree into NavBloom Sanctuary via ForestProvider
    final forest = context.read<ForestProvider>();
    final newTree = await forest.plantTree(
      species: _selectedSpecies,
      subjectName: _selectedSubject,
      chapterName: _selectedChapter,
      focusMinutes: effectiveMins,
    );

    // 2. Insert into SQLite study_sessions table
    final sessionRecord = StudySessionModel(
      id: 'session_${now.millisecondsSinceEpoch}',
      startedAt: startedAt,
      endedAt: now,
      activeSeconds: _elapsedSeconds,
      subjectName: _selectedSubject,
      chapterName: _selectedChapter,
      treeSpecies: _selectedSpecies.displayName,
      treeStage: newTree.stage,
      rewardXp: newTree.xpEarned,
      rewardCoins: newTree.coinsEarned,
      createdAt: now,
    );
    await DatabaseHelper.instance.insertStudySession(sessionRecord);

    _resetTimer();

    if (mounted) {
      _showCompletionDialog(newTree);
    }
  }

  void _showCompletionDialog(ForestTreeModel tree) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedXL),
        title: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tree.species.themeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(tree.species.iconEmoji, style: const TextStyle(fontSize: 36)),
              ),
              const SizedBox(height: 10),
              Text('Focus Session Complete!', style: AppTypography.titleLarge),
              const SizedBox(height: 2),
              Text(
                '${tree.species.displayName} Bloomed in Sanctuary!',
                style: AppTypography.bodySmall.copyWith(color: AppColors.deepForest),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.amberSoft,
                borderRadius: AppRadius.roundedL,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: AppColors.amberHoney, size: 20),
                      const SizedBox(width: 6),
                      Text('+${tree.xpEarned} XP', style: AppTypography.titleSmall),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on_rounded, color: AppColors.coinGold, size: 20),
                      const SizedBox(width: 6),
                      Text('+${tree.coinsEarned} Coins', style: AppTypography.titleSmall),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${tree.focusMinutes}m verified focus on $_selectedSubject: $_selectedChapter',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          NestButton(
            label: 'Collect & View Sanctuary',
            onPressed: () {
              Navigator.pop(context);
              widget.onSessionComplete?.call();
            },
            variant: NestButtonVariant.primary,
            isFullWidth: true,
          ),
        ],
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

  String _formatTime() {
    int total = _mode == TimerMode.stopwatch
        ? _elapsedSeconds
        : (_targetSeconds - _elapsedSeconds).clamp(0, _targetSeconds);

    final mins = (total ~/ 60).toString().padLeft(2, '0');
    final secs = (total % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  double _getProgress() {
    if (_mode == TimerMode.stopwatch) {
      return (_elapsedSeconds / 3600).clamp(0.0, 1.0);
    }
    return (_elapsedSeconds / _targetSeconds).clamp(0.0, 1.0);
  }

  String _getTreeStageDescription() {
    final mins = (_elapsedSeconds / 60).floor();
    if (mins >= 90) return 'Stage 5: Full Bloom 🌸';
    if (mins >= 60) return 'Stage 4: Young Tree 🌳';
    if (mins >= 40) return 'Stage 3: Sapling 🌿';
    if (mins >= 20) return 'Stage 2: Sprout 🌱';
    return 'Stage 1: Planted Seed ✨';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.ivoryCanvas,
      appBar: AppBar(
        title: Text('Focus Session', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset Timer',
            onPressed: _resetTimer,
          ),
          IconButton(
            icon: Icon(
              _whiteNoiseActive ? Icons.graphic_eq_rounded : Icons.volume_off_rounded,
              color: _whiteNoiseActive ? AppColors.sageGreen : null,
            ),
            tooltip: 'Ambient White Noise',
            onPressed: () {
              setState(() => _whiteNoiseActive = !_whiteNoiseActive);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_whiteNoiseActive ? '🌲 Forest Rain sound active' : 'Sound turned off'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Subject & Chapter Tag Pill (Interactive)
            GestureDetector(
              onTap: _showTopicSelectorSheet,
              child: _buildSubjectTag(isDark),
            ),

            const SizedBox(height: 28),

            // Central Circular Focus Ring with Sprouting Seed & Timer
            _buildTimerRing(isDark),

            const SizedBox(height: 20),

            // Live Tree Stage Progression Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.sageTint,
                borderRadius: AppRadius.roundedFull,
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.sageBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedSpecies.iconEmoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    _getTreeStageDescription(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.deepForest,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Controls: Start/Pause and Finish Early
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 160,
                  child: NestButton(
                    label: _isRunning ? 'Pause' : 'Start Focus',
                    icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    onPressed: _toggleTimer,
                    variant: NestButtonVariant.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                if (_elapsedSeconds >= 60 || _isRunning) ...[
                  const SizedBox(width: 14),
                  FilledButton.tonalIcon(
                    onPressed: _handleSessionCompletion,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Finish'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // Mode Selector Tabs (Pomodoro, Custom, Stopwatch)
            _buildModeTabs(isDark),

            const SizedBox(height: 32),

            // Bottom Action Shortcuts: Block Apps • Forest Sanctuary • Ambient Noise
            _buildBottomShortcuts(isDark),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectTag(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardSurface,
        borderRadius: AppRadius.roundedFull,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
        boxShadow: AppShadows.softCard,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bookmark_rounded, color: AppColors.deepForest, size: 18),
          const SizedBox(width: 8),
          Text(
            '$_selectedSubject • $_selectedChapter',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.sageGreen),
        ],
      ),
    );
  }

  Widget _buildTimerRing(bool isDark) {
    return NestCircularProgress(
      progress: _getProgress(),
      size: 240,
      strokeWidth: 10,
      progressColor: _selectedSpecies.themeColor,
      backgroundColor: isDark ? AppColors.darkBorder : AppColors.warmCream,
      centerWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _selectedSpecies.themeColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(_selectedSpecies.iconEmoji, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 10),
          Text(
            _formatTime(),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _isRunning ? 'Deep Study In Progress' : 'Ready to Grow Tree',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTabs(bool isDark) {
    final modes = [
      {'label': '25m Pomodoro', 'mode': TimerMode.pomodoro, 'sec': 25 * 60},
      {'label': '50m Deep Block', 'mode': TimerMode.custom, 'sec': 50 * 60},
      {'label': 'Stopwatch', 'mode': TimerMode.stopwatch, 'sec': 0},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.warmCream,
        borderRadius: AppRadius.roundedFull,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: modes.map((m) {
          final isSelected = _mode == m['mode'];
          return GestureDetector(
            onTap: () {
              if (!_isRunning) {
                setState(() {
                  _mode = m['mode'] as TimerMode;
                  _targetSeconds = m['sec'] as int;
                  _elapsedSeconds = 0;
                });
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.deepForest : Colors.transparent,
                borderRadius: AppRadius.roundedFull,
              ),
              child: Text(
                m['label'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomShortcuts(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildShortcutItem(
          Icons.block_rounded,
          'Block Apps',
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppBlockerScreen())),
          isDark,
        ),
        _buildShortcutItem(
          Icons.park_rounded,
          'Sanctuary',
          () {
            Navigator.pop(context);
            widget.onSessionComplete?.call();
          },
          isDark,
        ),
        _buildShortcutItem(
          Icons.graphic_eq_rounded,
          _whiteNoiseActive ? 'Sound ON' : 'Rain Sound',
          () {
            setState(() => _whiteNoiseActive = !_whiteNoiseActive);
          },
          isDark,
        ),
      ],
    );
  }

  Widget _buildShortcutItem(IconData icon, String label, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.cardSurface,
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
              boxShadow: AppShadows.softCard,
            ),
            child: Icon(icon, color: AppColors.deepForest, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
