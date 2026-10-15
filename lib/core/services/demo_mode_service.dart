import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import 'auth_service.dart';
import '../../features/navbloom/presentation/providers/forest_provider.dart';
import '../../features/planner/presentation/providers/planner_provider.dart';
import '../../features/syllabus/presentation/providers/syllabus_provider.dart';
import '../../features/shared_space/presentation/providers/shared_space_provider.dart';
import '../../features/distraction_control/presentation/providers/app_blocker_provider.dart';

class DemoModeService extends ChangeNotifier {
  static final DemoModeService instance = DemoModeService._internal();

  DemoModeService._internal();

  bool get isDemoMode => DatabaseHelper.instance.isDemoMode;

  /// Toggles and activates global demo mode across all providers
  Future<void> enterDemoMode(BuildContext context) async {
    if (isDemoMode) return;

    final auth = context.read<AuthService>();
    final forest = context.read<ForestProvider>();
    final syllabus = context.read<SyllabusProvider>();
    final planner = context.read<PlannerProvider>();
    final sharedSpace = context.read<SharedSpaceProvider>();
    final blocker = context.read<AppBlockerProvider>();

    // 1. Switch SQLite file to navnest_demo.db and seed full demo dataset
    await DatabaseHelper.instance.switchToDemoDatabase();

    // 2. Reload captured providers
    await auth.reloadProfile();
    await forest.loadForestData();
    await syllabus.loadSyllabus();
    await planner.loadInitialData();
    await sharedSpace.initialize();
    blocker.enableDemoMode();

    notifyListeners();
  }

  /// Exits demo mode and cleanly restores genuine user records
  Future<void> exitDemoMode(BuildContext context) async {
    if (!isDemoMode) return;

    final auth = context.read<AuthService>();
    final forest = context.read<ForestProvider>();
    final syllabus = context.read<SyllabusProvider>();
    final planner = context.read<PlannerProvider>();
    final sharedSpace = context.read<SharedSpaceProvider>();
    final blocker = context.read<AppBlockerProvider>();

    // 1. Switch SQLite file back to navnest.db
    await DatabaseHelper.instance.switchToProductionDatabase();

    // 2. Reload captured providers to restore user's real records
    await auth.reloadProfile();
    await forest.loadForestData();
    await syllabus.loadSyllabus();
    await planner.loadInitialData();
    await sharedSpace.initialize();
    await blocker.disableDemoMode();

    notifyListeners();
  }

  /// Explicit destructive reset of production user data
  Future<void> resetProductionData(BuildContext context) async {
    final auth = context.read<AuthService>();
    final forest = context.read<ForestProvider>();
    final syllabus = context.read<SyllabusProvider>();
    final planner = context.read<PlannerProvider>();
    final sharedSpace = context.read<SharedSpaceProvider>();

    await DatabaseHelper.instance.resetProductionUserData();

    await auth.reloadProfile();
    await forest.loadForestData();
    await syllabus.loadSyllabus();
    await planner.loadInitialData();
    await sharedSpace.initialize();

    notifyListeners();
  }
}
