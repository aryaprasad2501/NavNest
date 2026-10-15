import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:navnest/app.dart';
import 'package:navnest/core/database/database_helper.dart';
import 'package:navnest/core/models/chapter_model.dart';
import 'package:navnest/core/models/planner_task_model.dart';
import 'package:navnest/core/models/subject_model.dart';
import 'package:navnest/core/models/subtopic_model.dart';
import 'package:navnest/core/models/topic_status.dart';
import 'package:navnest/core/services/auth_service.dart';
import 'package:navnest/core/services/local_storage_service.dart';
import 'package:navnest/core/services/theme_service.dart';
import 'package:navnest/features/planner/presentation/providers/planner_provider.dart';
import 'package:navnest/features/syllabus/presentation/providers/syllabus_provider.dart';

import 'package:navnest/core/models/forest_tree_model.dart';
import 'package:navnest/core/models/forest_decoration_model.dart';
import 'package:navnest/features/navbloom/presentation/providers/forest_provider.dart';

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:navnest/core/services/cloud_sync_service.dart';
import 'package:navnest/core/services/shared_space_service.dart';
import 'package:navnest/features/shared_space/presentation/providers/shared_space_provider.dart';
import 'package:navnest/core/services/ambience_provider.dart';
import 'package:navnest/features/distraction_control/presentation/providers/app_blocker_provider.dart';
import 'package:navnest/features/distraction_control/services/app_blocker_service.dart';
import 'package:navnest/core/services/demo_mode_service.dart';
import 'package:navnest/features/focus/presentation/providers/focus_session_provider.dart';

class _TestAudioAdapter implements AmbienceAudioAdapter {
  final _ctrl = StreamController<PlayerState>.broadcast();
  @override
  Stream<PlayerState> get onPlayerStateChanged => _ctrl.stream;
  @override
  Future<void> playAsset(String p, {required bool loop, required double volume}) async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> setVolume(double v) async {}
  @override
  void dispose() { _ctrl.close(); }
}

class _TestBlockerBridge implements AppBlockerPlatformBridge {
  @override
  Future<List<Map<String, dynamic>>> getInstalledLauncherApps() async => [];
  @override
  Future<String?> getPendingBlockedIntervention() async => null;
  @override
  Future<bool> isAccessibilityServiceConnected() async => false;
  @override
  Future<bool> isAccessibilityServiceEnabled() async => false;
  @override
  Future<bool> openAccessibilitySettings() async => true;
  @override
  void setAppBlockedHandler(void Function(String packageName, int timestamp) handler) {}
  @override
  Future<bool> updateBlockerConfig({
    required bool isBlockingEnabled,
    required bool isSessionActive,
    required bool isSessionPaused,
    required bool strictMode,
    required List<String> blockedPackages,
  }) async => true;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('NavNestApp initial shell and navigation smoke test matching mockup', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'navnest_is_first_launch': false});
    final localStorage = await LocalStorageService.init();

    final now = DateTime.now();

    final testSubjects = [
      SubjectModel(
        id: 'sub_physics',
        name: 'Physics',
        colorHex: '#E8833A',
        iconName: 'lightbulb',
        orderIndex: 0,
        createdAt: now,
        chapters: [
          ChapterModel(
            id: 'ch_phy_1',
            subjectId: 'sub_physics',
            name: 'Units and Measurements',
            orderIndex: 0,
            createdAt: now,
            updatedAt: now,
            subtopics: [
              SubtopicModel(
                id: 'st_1',
                chapterId: 'ch_phy_1',
                name: 'Physical Quantities',
                status: TopicStatus.completed,
                createdAt: now,
                updatedAt: now,
              ),
              SubtopicModel(
                id: 'st_2',
                chapterId: 'ch_phy_1',
                name: 'Units and Dimensions',
                status: TopicStatus.completed,
                createdAt: now,
                updatedAt: now,
              ),
            ],
          ),
        ],
      ),
      SubjectModel(
        id: 'sub_chem',
        name: 'Chemistry',
        colorHex: '#3B8A6E',
        iconName: 'science',
        orderIndex: 1,
        createdAt: now,
        chapters: [],
      ),
    ];

    final themeService = ThemeService();
    final syllabusProvider = SyllabusProvider();
    syllabusProvider.setSubjectsForTesting(testSubjects);

    final plannerProvider = PlannerProvider();
    final todayKey = DatabaseHelper.formatDbDate(now);
    plannerProvider.setTasksForTesting([
      PlannerTaskModel(
        id: 'test_task_1',
        date: todayKey,
        subjectId: 'sub_physics',
        subjectName: 'Physics',
        title: 'Physics: Kinematics Revision',
        startTime: '09:00 AM',
        endTime: '10:30 AM',
        plannedMinutes: 90,
        createdAt: now,
      ),
    ]);

    final forestProvider = ForestProvider();
    forestProvider.setForestDataForTesting(
      trees: [
        ForestTreeModel(
          id: 'test_tree_1',
          species: TreeSpecies.cherryBlossom,
          stage: 5,
          xRatio: 0.3,
          yRatio: 0.5,
          plantedAt: now,
          subjectName: 'Physics',
          chapterName: 'Units and Measurements',
          focusMinutes: 120,
          xpEarned: 300,
          coinsEarned: 60,
        ),
      ],
      decorations: [
        const ForestDecorationModel(
          id: 'test_dec_1',
          name: 'Stone Lantern',
          description: 'Glows warmly in moonlight.',
          category: DecorationCategory.lighting,
          costCoins: 50,
          isUnlocked: true,
          isEquipped: true,
          xRatio: 0.4,
          yRatio: 0.5,
          iconName: 'light_mode',
        ),
      ],
    );

    final authService = AuthService();
    final ambienceProvider = AmbienceProvider(adapter: _TestAudioAdapter());
    final appBlockerProvider = AppBlockerProvider(bridge: _TestBlockerBridge());

    final sharedSpaceService = SharedSpaceService(
      storage: localStorage,
    );
    final sharedSpaceProvider = SharedSpaceProvider(
      service: sharedSpaceService,
      authService: authService,
      storage: localStorage,
    );
    final cloudSyncService = CloudSyncService();

    final focusSessionProvider = FocusSessionProvider();
    focusSessionProvider.updateDependencies(
      forestProvider: forestProvider,
      plannerProvider: plannerProvider,
      appBlockerProvider: appBlockerProvider,
      cloudSyncService: cloudSyncService,
      sharedSpaceProvider: sharedSpaceProvider,
    );

    // Build NavNestApp wrapped with Providers
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<LocalStorageService>.value(value: localStorage),
          ChangeNotifierProvider<ThemeService>.value(value: themeService),
          ChangeNotifierProvider<AuthService>.value(value: authService),
          ChangeNotifierProvider<AmbienceProvider>.value(value: ambienceProvider),
          ChangeNotifierProvider<AppBlockerProvider>.value(value: appBlockerProvider),
          ChangeNotifierProvider<SyllabusProvider>.value(value: syllabusProvider),
          ChangeNotifierProvider<PlannerProvider>.value(value: plannerProvider),
          ChangeNotifierProvider<ForestProvider>.value(value: forestProvider),
          ChangeNotifierProvider<FocusSessionProvider>.value(value: focusSessionProvider),
          ChangeNotifierProvider<SharedSpaceProvider>.value(value: sharedSpaceProvider),
          ChangeNotifierProvider<CloudSyncService>.value(value: cloudSyncService),
          ChangeNotifierProvider<DemoModeService>.value(value: DemoModeService.instance),
        ],
        child: const NavNestApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Verify Home Dashboard elements
    expect(find.textContaining(RegExp(r'Morning|Sanctuary|Sunlit|Evening|Calm')), findsAtLeastNWidgets(1));
    expect(find.text('Student 🌿'), findsOneWidget);
    expect(find.text('Day Streak'), findsOneWidget);
    expect(find.text("Today's Progress"), findsOneWidget);
    expect(find.text('Upcoming Exams'), findsOneWidget);

    // Verify 5 bottom navigation destinations
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('NavBloom'), findsOneWidget);
    expect(find.text('Planner'), findsOneWidget);
    expect(find.text('Syllabus'), findsOneWidget);
    expect(find.text('Shared'), findsOneWidget);

    // 2. Tap NavBloom tab
    await tester.tap(find.text('NavBloom'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('NavBloom'), findsWidgets);
    expect(find.text('Whispering Meadow'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Plant & Grow Forest Tree'), findsOneWidget);

    // 3. Tap Planner tab (Mockup Screen 7)
    await tester.tap(find.text('Planner'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Daily & Weekly Planner'), findsOneWidget);
    expect(find.text('+ Add Task'), findsOneWidget);
    expect(find.text('Physics: Kinematics Revision'), findsOneWidget);

    // 4. Tap Syllabus tab (Mockup Screen 5)
    await tester.tap(find.text('Syllabus'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('My Syllabus'), findsOneWidget);
    expect(find.text('Physics'), findsWidgets);
    expect(find.text('Chemistry'), findsWidgets);
    expect(find.text('+ Add Subject'), findsOneWidget);

    // 5. Tap Shared tab
    await tester.tap(find.text('Shared'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Private Shared Space'), findsOneWidget);
    expect(find.text('Private 1-to-1 Shared Space'), findsOneWidget);
  });
}
