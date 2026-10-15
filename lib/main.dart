import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/database/database_helper.dart';
import 'core/services/ambience_provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/cloud_sync_service.dart';
import 'core/services/demo_mode_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/shared_space_service.dart';
import 'core/services/theme_service.dart';
import 'features/distraction_control/presentation/providers/app_blocker_provider.dart';
import 'features/focus/presentation/providers/focus_session_provider.dart';
import 'features/navbloom/presentation/providers/forest_provider.dart';
import 'features/planner/presentation/providers/planner_provider.dart';
import 'features/shared_space/presentation/providers/shared_space_provider.dart';
import 'features/syllabus/presentation/providers/syllabus_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform configuration
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase.initializeApp warning/error: $e');
  }

  final localStorage = await LocalStorageService.init();

  // Initialize offline database, auth service, theme service, syllabus, planner, and forest
  final dbHelper = DatabaseHelper.instance;
  await dbHelper.seedInitialSyllabus();
  await dbHelper.seedInitialPlannerData();
  await dbHelper.seedInitialForestData();

  // Ensure clean slate flag is established without destroying real user records
  if (!localStorage.isCleanSlatePurged) {
    await localStorage.setCleanSlatePurged();
  }

  final authService = AuthService(dbHelper: dbHelper);
  await authService.initialize();

  final themeService = ThemeService();
  await themeService.initialize();

  final ambienceProvider = AmbienceProvider();
  final appBlockerProvider = AppBlockerProvider();

  final syllabusProvider = SyllabusProvider(dbHelper: dbHelper);
  await syllabusProvider.loadSyllabus();

  final plannerProvider = PlannerProvider(dbHelper: dbHelper);
  await plannerProvider.loadInitialData();

  final forestProvider = ForestProvider(dbHelper: dbHelper);
  await forestProvider.loadForestData();

  final sharedSpaceService = SharedSpaceService(
    storage: localStorage,
    dbHelper: dbHelper,
  );

  final sharedSpaceProvider = SharedSpaceProvider(
    service: sharedSpaceService,
    authService: authService,
    dbHelper: dbHelper,
    storage: localStorage,
  );
  await sharedSpaceProvider.initialize();

  final cloudSyncService = CloudSyncService(dbHelper: dbHelper);
  await cloudSyncService.initialize();

  final focusSessionProvider = FocusSessionProvider(dbHelper: dbHelper);
  focusSessionProvider.updateDependencies(
    forestProvider: forestProvider,
    plannerProvider: plannerProvider,
    appBlockerProvider: appBlockerProvider,
    cloudSyncService: cloudSyncService,
    sharedSpaceProvider: sharedSpaceProvider,
  );
  await focusSessionProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<LocalStorageService>.value(value: localStorage),
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<ThemeService>.value(value: themeService),
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
}
