import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:navnest/core/database/database_helper.dart';
import 'package:navnest/core/models/user_profile.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('DatabaseHelper initializes tables and inserts default user', () async {
    final inMemoryDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    final dbHelper = DatabaseHelper.instance;
    dbHelper.setDatabaseForTesting(inMemoryDb);

    // Call onCreate manually on the in-memory db
    await inMemoryDb.execute('''
      CREATE TABLE user_profiles (
        id TEXT PRIMARY KEY,
        displayName TEXT NOT NULL,
        email TEXT,
        photoUrl TEXT,
        streakDays INTEGER NOT NULL DEFAULT 0,
        bestStreak INTEGER NOT NULL DEFAULT 0,
        lastStudyDate TEXT,
        totalXp INTEGER NOT NULL DEFAULT 0,
        coins INTEGER NOT NULL DEFAULT 0,
        dailyTargetMinutes INTEGER NOT NULL DEFAULT 120,
        activeSharedSpaceId TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await inMemoryDb.execute('''
      CREATE TABLE shared_spaces (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        inviteCode TEXT NOT NULL,
        createdByUserId TEXT NOT NULL,
        memberIds TEXT NOT NULL,
        totalForestTrees INTEGER NOT NULL DEFAULT 0,
        combinedFocusMinutes INTEGER NOT NULL DEFAULT 0,
        sharedExamName TEXT,
        sharedExamDate TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Test inserting and retrieving user profile
    final profile = UserProfile.defaultProfile(id: 'test_student_1');
    await dbHelper.saveUserProfile(profile);

    final retrieved = await dbHelper.getUserProfile('test_student_1');
    expect(retrieved, isNotNull);
    expect(retrieved!.displayName, equals('Student'));
    expect(retrieved.streakDays, equals(1));
    expect(retrieved.totalXp, equals(150));
    expect(retrieved.coins, equals(40));

    // Test updating profile
    final updated = retrieved.copyWith(totalXp: 300, coins: 80, streakDays: 2);
    await dbHelper.saveUserProfile(updated);

    final afterUpdate = await dbHelper.getUserProfile('test_student_1');
    expect(afterUpdate!.totalXp, equals(300));
    expect(afterUpdate.coins, equals(80));
    expect(afterUpdate.streakDays, equals(2));

    await dbHelper.close();
  });
}
