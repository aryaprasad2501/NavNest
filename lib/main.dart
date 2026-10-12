import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/database/database_helper.dart';
import 'core/services/auth_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/theme_service.dart';
import 'features/navbloom/presentation/providers/forest_provider.dart';
import 'features/planner/presentation/providers/planner_provider.dart';
import 'features/syllabus/presentation/providers/syllabus_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localStorage = await LocalStorageService.init();

  // Initialize offline database, auth service, theme service, syllabus, planner, and forest
  final dbHelper = DatabaseHelper.instance;
  await dbHelper.seedInitialSyllabus();
  await dbHelper.seedInitialPlannerData();
  await dbHelper.seedInitialForestData();

  // If clean slate hasn't been applied yet, purge all dummy records so student starts fresh
  if (!localStorage.isCleanSlatePurged || localStorage.isFirstLaunch) {
    await dbHelper.purgeDummyDataAndStartFresh();
    await localStorage.clearSharedSpaceData();
    await localStorage.setCleanSlatePurged();
  }

  final authService = AuthService(dbHelper: dbHelper);
  await authService.initialize();

  final themeService = ThemeService();
  await themeService.initialize();

  final syllabusProvider = SyllabusProvider(dbHelper: dbHelper);
  await syllabusProvider.loadSyllabus();

  final plannerProvider = PlannerProvider(dbHelper: dbHelper);
  await plannerProvider.loadInitialData();

  final forestProvider = ForestProvider(dbHelper: dbHelper);
  await forestProvider.loadForestData();

  runApp(
    MultiProvider(
      providers: [
        Provider<LocalStorageService>.value(value: localStorage),
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<ThemeService>.value(value: themeService),
        ChangeNotifierProvider<SyllabusProvider>.value(value: syllabusProvider),
        ChangeNotifierProvider<PlannerProvider>.value(value: plannerProvider),
        ChangeNotifierProvider<ForestProvider>.value(value: forestProvider),
      ],
      child: const NavNestApp(),
    ),
  );
}
