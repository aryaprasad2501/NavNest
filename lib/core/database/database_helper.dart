import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/achievement_model.dart';
import '../models/chapter_model.dart';
import '../models/exam_model.dart';
import '../models/forest_decoration_model.dart';
import '../models/forest_journal_entry.dart';
import '../models/forest_tree_model.dart';
import '../models/planner_task_model.dart';
import '../models/shared_space_model.dart';
import '../models/study_session_model.dart';
import '../models/subject_model.dart';
import '../models/subtopic_model.dart';
import '../models/topic_status.dart';
import '../models/user_profile.dart';

class DatabaseHelper {
  static const String _dbName = 'navnest.db';
  static const int _dbVersion = 1;

  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  /// Allows injecting a custom Database instance (e.g. ffi in-memory database for unit testing).
  void setDatabaseForTesting(Database? testDb) {
    _database = testDb;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. User Profiles
    await db.execute('''
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

    // 2. Shared Spaces
    await db.execute('''
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

    // 3. Subjects
    await db.execute('''
      CREATE TABLE subjects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        colorHex TEXT NOT NULL,
        iconName TEXT NOT NULL,
        orderIndex INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    // 4. Chapters
    await db.execute('''
      CREATE TABLE chapters (
        id TEXT PRIMARY KEY,
        subjectId TEXT NOT NULL,
        name TEXT NOT NULL,
        orderIndex INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (subjectId) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    // 5. Subtopics
    await db.execute('''
      CREATE TABLE subtopics (
        id TEXT PRIMARY KEY,
        chapterId TEXT NOT NULL,
        name TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'NOT_STARTED',
        estimatedMinutes INTEGER NOT NULL DEFAULT 30,
        notes TEXT,
        orderIndex INTEGER NOT NULL DEFAULT 0,
        completedAt TEXT,
        revisionCount INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (chapterId) REFERENCES chapters (id) ON DELETE CASCADE
      )
    ''');

    // 6. Exams
    await db.execute('''
      CREATE TABLE exams (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        examDate TEXT NOT NULL,
        targetScore INTEGER,
        colorHex TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // 7. Planner Tasks
    await db.execute('''
      CREATE TABLE planner_tasks (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        subjectId TEXT,
        chapterId TEXT,
        subtopicId TEXT,
        title TEXT NOT NULL,
        startTime TEXT,
        endTime TEXT,
        plannedMinutes INTEGER NOT NULL DEFAULT 45,
        actualMinutes INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'UPCOMING',
        outcome TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // 8. Study Sessions
    await db.execute('''
      CREATE TABLE study_sessions (
        id TEXT PRIMARY KEY,
        startedAt TEXT NOT NULL,
        endedAt TEXT NOT NULL,
        activeSeconds INTEGER NOT NULL DEFAULT 0,
        pausedSeconds INTEGER NOT NULL DEFAULT 0,
        subjectId TEXT,
        chapterId TEXT,
        subtopicId TEXT,
        status TEXT NOT NULL DEFAULT 'COMPLETED',
        rewardXp INTEGER NOT NULL DEFAULT 0,
        rewardCoins INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    // 9. NavBloom Forest Trees
    await db.execute('''
      CREATE TABLE IF NOT EXISTS forest_trees (
        id TEXT PRIMARY KEY,
        sessionId TEXT,
        treeType TEXT NOT NULL DEFAULT 'Mountain Pine',
        stage INTEGER NOT NULL DEFAULT 1,
        gridX INTEGER NOT NULL DEFAULT 0,
        gridY INTEGER NOT NULL DEFAULT 0,
        xRatio REAL NOT NULL DEFAULT 0.5,
        yRatio REAL NOT NULL DEFAULT 0.5,
        plantedAt TEXT NOT NULL,
        maturedAt TEXT,
        subjectName TEXT,
        chapterName TEXT,
        focusMinutes INTEGER NOT NULL DEFAULT 25,
        xpEarned INTEGER NOT NULL DEFAULT 100,
        coinsEarned INTEGER NOT NULL DEFAULT 25,
        status TEXT NOT NULL DEFAULT 'HEALTHY',
        isShared INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 10. NavBloom Decorations
    await db.execute('''
      CREATE TABLE IF NOT EXISTS forest_decorations (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        costCoins INTEGER NOT NULL,
        isUnlocked INTEGER NOT NULL DEFAULT 0,
        isEquipped INTEGER NOT NULL DEFAULT 0,
        xRatio REAL NOT NULL DEFAULT 0.5,
        yRatio REAL NOT NULL DEFAULT 0.5,
        iconName TEXT NOT NULL
      )
    ''');

    // 11. NavBloom Forest Journal
    await db.execute('''
      CREATE TABLE IF NOT EXISTS forest_journal (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        subjectName TEXT,
        focusMinutes INTEGER NOT NULL DEFAULT 0,
        xpEarned INTEGER NOT NULL DEFAULT 0,
        coinsEarned INTEGER NOT NULL DEFAULT 0,
        notes TEXT
      )
    ''');

    // 12. NavBloom Achievements
    await db.execute('''
      CREATE TABLE IF NOT EXISTS achievements (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        iconName TEXT NOT NULL,
        progress INTEGER NOT NULL DEFAULT 0,
        target INTEGER NOT NULL DEFAULT 1,
        isUnlocked INTEGER NOT NULL DEFAULT 0,
        unlockedAt TEXT,
        xpReward INTEGER NOT NULL DEFAULT 100,
        coinsReward INTEGER NOT NULL DEFAULT 50
      )
    ''');

    // 13. Reward Transactions (Idempotency Ledger)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reward_transactions (
        transactionId TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        xpAmount INTEGER NOT NULL DEFAULT 0,
        coinsAmount INTEGER NOT NULL DEFAULT 0,
        reason TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Seed default user profile
    final defaultUser = UserProfile.defaultProfile();
    await db.insert('user_profiles', defaultUser.toMap());

    // Seed initial syllabus
    await seedInitialSyllabus(db);

    // Seed initial planner tasks & exams
    await seedInitialPlannerData(db);

    // Seed initial forest trees, decorations, journal & achievements
    await seedInitialForestData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Column additions if upgrading
    try {
      await db.execute('ALTER TABLE planner_tasks ADD COLUMN startTime TEXT');
      await db.execute('ALTER TABLE planner_tasks ADD COLUMN endTime TEXT');
    } catch (_) {}
    try {
      await ensureForestTablesExist(db);
    } catch (_) {}
  }

  // --- Initial Syllabus Seed (CBSE Class 10 Board Exam 2027) ---
  Future<void> seedInitialSyllabus([Database? targetDb]) async {
    final db = targetDb ?? await database;

    // Auto-migrate from older schema/Class 12 data if present
    final hasOldData = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM subjects WHERE id = 'sub_physics'"),
    );
    if (hasOldData != null && hasOldData > 0) {
      await db.delete('subtopics');
      await db.delete('chapters');
      await db.delete('subjects');
      await db.delete('planner_tasks');
      await db.delete('exams');
    }

    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM subjects'),
    );
    if (count != null && count > 0) return;

    final now = DateTime.now();

    final subjectsData = [
      // 1. MATHEMATICS
      {
        'id': 'sub_maths',
        'name': 'Mathematics',
        'colorHex': '#4A7C59',
        'iconName': 'calculate',
        'orderIndex': 0,
        'chapters': [
          {
            'id': 'ch_math_1',
            'name': 'Real Numbers',
            'orderIndex': 0,
            'subtopics': [
              {'name': 'Fundamental Theorem of Arithmetic', 'status': 'COMPLETED', 'mins': 35},
              {'name': 'Revisiting Irrational Numbers (Proofs of √2, √3)', 'status': 'COMPLETED', 'mins': 40},
              {'name': 'HCF and LCM Applications', 'status': 'NEEDS_REVISION', 'mins': 30},
            ],
          },
          {
            'id': 'ch_math_2',
            'name': 'Polynomials',
            'orderIndex': 1,
            'subtopics': [
              {'name': 'Geometrical Meaning of Zeroes', 'status': 'COMPLETED', 'mins': 30},
              {'name': 'Relationship between Zeroes and Coefficients', 'status': 'IN_PROGRESS', 'mins': 45},
              {'name': 'Quadratic Polynomial Formation', 'status': 'NOT_STARTED', 'mins': 30},
            ],
          },
          {
            'id': 'ch_math_3',
            'name': 'Pair of Linear Equations in Two Variables',
            'orderIndex': 2,
            'subtopics': [
              {'name': 'Graphical Method of Solution', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Substitution Method', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Elimination Method', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Word Problems on Speed, Time & Age', 'status': 'NOT_STARTED', 'mins': 50},
            ],
          },
          {
            'id': 'ch_math_4',
            'name': 'Quadratic Equations',
            'orderIndex': 3,
            'subtopics': [
              {'name': 'Standard Form of Quadratic Equation', 'status': 'NOT_STARTED', 'mins': 25},
              {'name': 'Solution by Factorisation', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Quadratic Formula & Discriminant', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Nature of Roots & Real-Life Problems', 'status': 'NOT_STARTED', 'mins': 45},
            ],
          },
          {
            'id': 'ch_math_5',
            'name': 'Arithmetic Progressions',
            'orderIndex': 4,
            'subtopics': [
              {'name': 'Introduction to AP & Common Difference', 'status': 'NOT_STARTED', 'mins': 30},
              {'name': 'nth Term of an AP Formula', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Sum of First n Terms of an AP', 'status': 'NOT_STARTED', 'mins': 50},
              {'name': 'Application in Solving Daily Life Problems', 'status': 'NOT_STARTED', 'mins': 40},
            ],
          },
          {
            'id': 'ch_math_6',
            'name': 'Coordinate Geometry',
            'orderIndex': 5,
            'subtopics': [
              {'name': 'Distance Formula and Derivations', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Section Formula (Internal Division)', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Mid-point Formula Applications', 'status': 'NOT_STARTED', 'mins': 30},
            ],
          },
          {
            'id': 'ch_math_7',
            'name': 'Triangles',
            'orderIndex': 6,
            'subtopics': [
              {'name': 'Basic Proportionality Theorem (Thales)', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Converse of Thales Theorem', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Criteria for Similarity (AAA, SSS, SAS)', 'status': 'NOT_STARTED', 'mins': 50},
              {'name': 'Similarity Proof Problems', 'status': 'NOT_STARTED', 'mins': 45},
            ],
          },
          {
            'id': 'ch_math_8',
            'name': 'Circles',
            'orderIndex': 7,
            'subtopics': [
              {'name': 'Tangent to a Circle & Point of Contact', 'status': 'NOT_STARTED', 'mins': 30},
              {'name': 'Theorem: Tangent Perpendicular to Radius', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Theorem: Lengths of Tangents from External Point', 'status': 'NOT_STARTED', 'mins': 40},
            ],
          },
          {
            'id': 'ch_math_9',
            'name': 'Introduction to Trigonometry',
            'orderIndex': 8,
            'subtopics': [
              {'name': 'Trigonometric Ratios of an Acute Angle', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Trigonometric Ratios of 0°, 30°, 45°, 60°, 90°', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Trigonometric Identity: sin²θ + cos²θ = 1', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': '1 + tan²θ = sec²θ & 1 + cot²θ = cosec²θ', 'status': 'NOT_STARTED', 'mins': 40},
            ],
          },
          {
            'id': 'ch_math_10',
            'name': 'Some Applications of Trigonometry',
            'orderIndex': 9,
            'subtopics': [
              {'name': 'Angle of Elevation and Depression', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Heights and Distances Problems (Single Right Triangle)', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Two Triangles Heights & Distances Problems', 'status': 'NOT_STARTED', 'mins': 50},
            ],
          },
          {
            'id': 'ch_math_11',
            'name': 'Areas Related to Circles',
            'orderIndex': 10,
            'subtopics': [
              {'name': 'Perimeter and Area of a Circle Review', 'status': 'NOT_STARTED', 'mins': 25},
              {'name': 'Area of Sector of a Circle', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Area of Segment of a Circle', 'status': 'NOT_STARTED', 'mins': 45},
            ],
          },
          {
            'id': 'ch_math_12',
            'name': 'Surface Areas and Volumes',
            'orderIndex': 11,
            'subtopics': [
              {'name': 'Surface Area of Combination of Solids', 'status': 'NOT_STARTED', 'mins': 50},
              {'name': 'Volume of Combination of Solids', 'status': 'NOT_STARTED', 'mins': 50},
              {'name': 'Conversion of Solid from One Shape to Another', 'status': 'NOT_STARTED', 'mins': 45},
            ],
          },
          {
            'id': 'ch_math_13',
            'name': 'Statistics',
            'orderIndex': 12,
            'subtopics': [
              {'name': 'Mean of Grouped Data (Direct & Assumed Mean)', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Mode of Grouped Data', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Median of Grouped Data', 'status': 'NOT_STARTED', 'mins': 45},
            ],
          },
          {
            'id': 'ch_math_14',
            'name': 'Probability',
            'orderIndex': 13,
            'subtopics': [
              {'name': 'Classical Definition of Probability', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Simple Problems on Finding the Probability of an Event', 'status': 'NOT_STARTED', 'mins': 40},
            ],
          },
        ],
      },

      // 2. SCIENCE (CHEMISTRY, PHYSICS, BIOLOGY)
      {
        'id': 'sub_science',
        'name': 'Science',
        'colorHex': '#3B8A6E',
        'iconName': 'science',
        'orderIndex': 1,
        'chapters': [
          {
            'id': 'ch_sci_1',
            'name': 'Chemical Reactions and Equations',
            'orderIndex': 0,
            'subtopics': [
              {'name': 'Chemical Equations & Balancing', 'status': 'COMPLETED', 'mins': 40},
              {'name': 'Combination, Decomposition & Displacement', 'status': 'COMPLETED', 'mins': 45},
              {'name': 'Double Displacement, Oxidation & Reduction', 'status': 'COMPLETED', 'mins': 45},
              {'name': 'Corrosion and Rancidity', 'status': 'COMPLETED', 'mins': 25},
            ],
          },
          {
            'id': 'ch_sci_2',
            'name': 'Acids, Bases and Salts',
            'orderIndex': 1,
            'subtopics': [
              {'name': 'Chemical Properties of Acids and Bases', 'status': 'COMPLETED', 'mins': 40},
              {'name': 'pH Scale and Importance in Everyday Life', 'status': 'NEEDS_REVISION', 'mins': 35},
              {'name': 'Common Salt, Bleaching Powder & Baking Soda', 'status': 'IN_PROGRESS', 'mins': 45},
              {'name': 'Washing Soda and Plaster of Paris', 'status': 'NOT_STARTED', 'mins': 35},
            ],
          },
          {
            'id': 'ch_sci_3',
            'name': 'Metals and Non-metals',
            'orderIndex': 2,
            'subtopics': [
              {'name': 'Physical & Chemical Properties of Metals & Non-metals', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Reactivity Series of Metals', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Formation and Properties of Ionic Compounds', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Basic Metallurgical Processes & Corrosion', 'status': 'NOT_STARTED', 'mins': 45},
            ],
          },
          {
            'id': 'ch_sci_4',
            'name': 'Carbon and Its Compounds',
            'orderIndex': 3,
            'subtopics': [
              {'name': 'Covalent Bonding in Carbon Compounds', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Versatile Nature of Carbon & Tetravalency', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Homologous Series & Nomenclature', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Chemical Properties: Combustion, Oxidation, Addition', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Ethanol, Ethanoic Acid, Soaps and Detergents', 'status': 'NOT_STARTED', 'mins': 45},
            ],
          },
          {
            'id': 'ch_sci_5',
            'name': 'Life Processes',
            'orderIndex': 4,
            'subtopics': [
              {'name': 'Autotrophic & Heterotrophic Nutrition', 'status': 'IN_PROGRESS', 'mins': 45},
              {'name': 'Respiration: Aerobic and Anaerobic', 'status': 'IN_PROGRESS', 'mins': 40},
              {'name': 'Transportation in Human Beings & Plants', 'status': 'NOT_STARTED', 'mins': 50},
              {'name': 'Excretion in Human Beings and Plants', 'status': 'NOT_STARTED', 'mins': 40},
            ],
          },
          {
            'id': 'ch_sci_6',
            'name': 'Control and Coordination',
            'orderIndex': 5,
            'subtopics': [
              {'name': 'Tropic Movements in Plants & Plant Hormones', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Nervous System & Reflex Arc in Animals', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Structure of Human Brain', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Hormones in Animals & Endocrine Glands', 'status': 'NOT_STARTED', 'mins': 35},
            ],
          },
          {
            'id': 'ch_sci_7',
            'name': 'How Do Organisms Reproduce?',
            'orderIndex': 6,
            'subtopics': [
              {'name': 'Asexual Modes: Fission, Fragmentation, Regeneration', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Sexual Reproduction in Flowering Plants', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Human Male & Female Reproductive Systems', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Reproductive Health and Birth Control Methods', 'status': 'NOT_STARTED', 'mins': 35},
            ],
          },
          {
            'id': 'ch_sci_8',
            'name': 'Heredity',
            'orderIndex': 7,
            'subtopics': [
              {'name': 'Heredity & Mendel\'s Contribution', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Monohybrid and Dihybrid Cross', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Sex Determination in Human Beings', 'status': 'NOT_STARTED', 'mins': 35},
            ],
          },
          {
            'id': 'ch_sci_9',
            'name': 'Light: Reflection and Refraction',
            'orderIndex': 8,
            'subtopics': [
              {'name': 'Reflection by Spherical Mirrors & Ray Diagrams', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Mirror Formula and Magnification', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Refraction of Light and Snell\'s Law', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Spherical Lenses, Lens Formula & Power of a Lens', 'status': 'NOT_STARTED', 'mins': 50},
            ],
          },
          {
            'id': 'ch_sci_10',
            'name': 'The Human Eye and the Colourful World',
            'orderIndex': 9,
            'subtopics': [
              {'name': 'Structure of Human Eye & Power of Accommodation', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Defects of Vision: Myopia, Hypermetropia & Correction', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Refraction through a Glass Prism & Dispersion', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Atmospheric Refraction & Scattering (Tyndall Effect)', 'status': 'NOT_STARTED', 'mins': 40},
            ],
          },
          {
            'id': 'ch_sci_11',
            'name': 'Electricity',
            'orderIndex': 10,
            'subtopics': [
              {'name': 'Electric Current, Potential Difference & Voltmeter', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Ohm\'s Law and Resistance', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Factors on which Resistance Depends & Resistivity', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Resistors in Series and Parallel', 'status': 'NOT_STARTED', 'mins': 50},
              {'name': 'Joule\'s Heating Effect & Electric Power', 'status': 'NOT_STARTED', 'mins': 45},
            ],
          },
          {
            'id': 'ch_sci_12',
            'name': 'Magnetic Effects of Electric Current',
            'orderIndex': 11,
            'subtopics': [
              {'name': 'Magnetic Field and Field Lines', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Right Hand Thumb Rule & Solenoid', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Force on Current-Carrying Conductor & Fleming\'s Left Hand Rule', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Domestic Electric Circuits, Earthing & Short Circuit', 'status': 'NOT_STARTED', 'mins': 40},
            ],
          },
          {
            'id': 'ch_sci_13',
            'name': 'Our Environment',
            'orderIndex': 12,
            'subtopics': [
              {'name': 'Eco-system and Food Chains', 'status': 'NOT_STARTED', 'mins': 30},
              {'name': 'Trophic Levels and 10% Energy Flow Law', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Ozone Layer Depletion & Waste Management', 'status': 'NOT_STARTED', 'mins': 30},
            ],
          },
        ],
      },

      // 3. SOCIAL SCIENCE (HISTORY, GEOGRAPHY, CIVICS, ECONOMICS)
      {
        'id': 'sub_sst',
        'name': 'Social Science',
        'colorHex': '#C2783B',
        'iconName': 'public',
        'orderIndex': 2,
        'chapters': [
          // History
          {
            'id': 'ch_sst_1',
            'name': 'The Rise of Nationalism in Europe',
            'orderIndex': 0,
            'subtopics': [
              {'name': 'French Revolution and Idea of Nation', 'status': 'COMPLETED', 'mins': 40},
              {'name': 'The Making of Nationalism in Europe', 'status': 'COMPLETED', 'mins': 45},
              {'name': 'The Age of Revolutions (1830-1848)', 'status': 'IN_PROGRESS', 'mins': 40},
              {'name': 'Unification of Germany and Italy', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Visualising the Nation and Imperialism', 'status': 'NOT_STARTED', 'mins': 35},
            ],
          },
          {
            'id': 'ch_sst_2',
            'name': 'Nationalism in India',
            'orderIndex': 1,
            'subtopics': [
              {'name': 'First World War, Khilafat and Non-Cooperation', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Differing Strands within the Movement', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Towards Civil Disobedience & Salt March', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Sense of Collective Belonging', 'status': 'NOT_STARTED', 'mins': 35},
            ],
          },
          {
            'id': 'ch_sst_3',
            'name': 'The Making of a Global World',
            'orderIndex': 2,
            'subtopics': [
              {'name': 'The Pre-modern World and Silk Routes', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Conquest, Disease and Trade', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'The 19th Century (1815-1914) World Economy', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'The Inter-war Economy & Great Depression', 'status': 'NOT_STARTED', 'mins': 40},
            ],
          },
          {
            'id': 'ch_sst_4',
            'name': 'The Age of Industrialisation',
            'orderIndex': 3,
            'subtopics': [
              {'name': 'Before the Industrial Revolution & Proto-industrialisation', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Hand Labour and Steam Power', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Industrialisation in the Colonies', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Factories Come Up & Market for Goods', 'status': 'NOT_STARTED', 'mins': 35},
            ],
          },
          {
            'id': 'ch_sst_5',
            'name': 'Print Culture and the Modern World',
            'orderIndex': 4,
            'subtopics': [
              {'name': 'The First Printed Books in China & Japan', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Print Comes to Europe & Gutenberg Press', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'The Print Revolution and its Impact', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'The Reading Mania & 19th Century Readers', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'India and the World of Print & Religious Reform', 'status': 'NOT_STARTED', 'mins': 40},
            ],
          },
          // Geography
          {
            'id': 'ch_sst_6',
            'name': 'Resources and Development',
            'orderIndex': 5,
            'subtopics': [
              {'name': 'Classification and Development of Resources', 'status': 'COMPLETED', 'mins': 35},
              {'name': 'Resource Planning in India & Conservation', 'status': 'COMPLETED', 'mins': 35},
              {'name': 'Land Resources and Land Use Pattern', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Land Degradation and Conservation Measures', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Soil as a Resource & Soil Erosion/Conservation', 'status': 'NOT_STARTED', 'mins': 40},
            ],
          },
          {
            'id': 'ch_sst_7',
            'name': 'Forest and Wildlife Resources',
            'orderIndex': 6,
            'subtopics': [
              {'name': 'Flora and Fauna in India & IUCN Classification', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Conservation of Forest and Wildlife in India', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Types and Distribution of Forest and Wildlife Resources', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Community and Conservation (Chipko, Beej Bachao)', 'status': 'NOT_STARTED', 'mins': 30},
            ],
          },
          {
            'id': 'ch_sst_8',
            'name': 'Water Resources',
            'orderIndex': 7,
            'subtopics': [
              {'name': 'Water Scarcity and the Need for Water Conservation', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Multi-purpose River Projects and Water Management', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Rainwater Harvesting Techniques', 'status': 'NOT_STARTED', 'mins': 35},
            ],
          },
          {
            'id': 'ch_sst_9',
            'name': 'Agriculture',
            'orderIndex': 8,
            'subtopics': [
              {'name': 'Types of Farming: Primitive, Intensive & Commercial', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Cropping Pattern: Rabi, Kharif and Zaid', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Major Food Crops (Rice, Wheat, Millets, Pulses)', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Non-food Crops & Cash Crops (Cotton, Jute)', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Technological and Institutional Reforms', 'status': 'NOT_STARTED', 'mins': 35},
            ],
          },
          {
            'id': 'ch_sst_10',
            'name': 'Minerals and Energy Resources',
            'orderIndex': 9,
            'subtopics': [
              {'name': 'Mode of Occurrence of Minerals', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Ferrous and Non-Ferrous Minerals', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Conventional Energy Sources (Coal, Petroleum)', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Non-Conventional Energy Sources & Conservation', 'status': 'NOT_STARTED', 'mins': 40},
            ],
          },
          {
            'id': 'ch_sst_11',
            'name': 'Manufacturing Industries',
            'orderIndex': 10,
            'subtopics': [
              {'name': 'Importance of Manufacturing & Economic Development', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Industrial Location and Classification of Industries', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Agro-based Industries (Textiles, Sugar)', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Mineral-based Industries (Iron & Steel, Aluminium)', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Industrial Pollution and Environmental Degradation', 'status': 'NOT_STARTED', 'mins': 35},
            ],
          },
          {
            'id': 'ch_sst_12',
            'name': 'Lifelines of National Economy',
            'orderIndex': 11,
            'subtopics': [
              {'name': 'Roadways, Golden Quadrilateral & National Highways', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Railways, Pipelines and Waterways', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Major Sea Ports and Airways', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Communication & International Trade', 'status': 'NOT_STARTED', 'mins': 35},
            ],
          },
          // Civics
          {
            'id': 'ch_sst_13',
            'name': 'Power Sharing',
            'orderIndex': 12,
            'subtopics': [
              {'name': 'Case Studies of Belgium and Sri Lanka', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Majoritarianism vs Accommodation', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Why Power Sharing is Desirable', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Forms of Power Sharing', 'status': 'NOT_STARTED', 'mins': 40},
            ],
          },
          {
            'id': 'ch_sst_14',
            'name': 'Federalism',
            'orderIndex': 13,
            'subtopics': [
              {'name': 'What is Federalism & Key Features', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'What Makes India a Federal Country', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'How is Federalism Practised: Language Policy', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Decentralisation in India & Panchayati Raj', 'status': 'NOT_STARTED', 'mins': 45},
            ],
          },
          {
            'id': 'ch_sst_15',
            'name': 'Gender, Religion and Caste',
            'orderIndex': 14,
            'subtopics': [
              {'name': 'Gender and Politics: Women\'s Representation', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Religion, Communalism and Politics', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Secular State Concept', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Caste and Politics: Inequalities & Votes', 'status': 'NOT_STARTED', 'mins': 40},
            ],
          },
          {
            'id': 'ch_sst_16',
            'name': 'Political Parties',
            'orderIndex': 15,
            'subtopics': [
              {'name': 'Why Do We Need Political Parties & Functions', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Party Systems: One, Two, and Multi-party', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'National Parties & State Parties of India', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Challenges to Political Parties & Reforms', 'status': 'NOT_STARTED', 'mins': 40},
            ],
          },
          {
            'id': 'ch_sst_17',
            'name': 'Outcomes of Democracy',
            'orderIndex': 16,
            'subtopics': [
              {'name': 'How Do We Assess Democracy\'s Outcomes?', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Accountable, Responsive and Legitimate Government', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Economic Growth and Reduction of Poverty', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Accommodation of Social Diversity & Dignity', 'status': 'NOT_STARTED', 'mins': 35},
            ],
          },
          // Economics
          {
            'id': 'ch_sst_18',
            'name': 'Development',
            'orderIndex': 17,
            'subtopics': [
              {'name': 'What Development Promises - Different Goals', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Income and Other Goals', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'National Development & Comparing Countries (PCI/HDI)', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Public Facilities & Sustainability of Development', 'status': 'NOT_STARTED', 'mins': 35},
            ],
          },
          {
            'id': 'ch_sst_19',
            'name': 'Sectors of the Indian Economy',
            'orderIndex': 18,
            'subtopics': [
              {'name': 'Primary, Secondary, and Tertiary Sectors', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Rising Importance of the Tertiary Sector', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Where are Most People Employed? Disguised Unemployment', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Organised vs Unorganised & Public vs Private Sectors', 'status': 'NOT_STARTED', 'mins': 45},
            ],
          },
          {
            'id': 'ch_sst_20',
            'name': 'Money and Credit',
            'orderIndex': 19,
            'subtopics': [
              {'name': 'Money as a Medium of Exchange & Double Coincidence', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Modern Forms of Money & Bank Deposits', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Loan Activities of Banks & Terms of Credit', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Formal vs Informal Credit Sectors in India & SHGs', 'status': 'NOT_STARTED', 'mins': 40},
            ],
          },
          {
            'id': 'ch_sst_21',
            'name': 'Globalisation and the Indian Economy',
            'orderIndex': 20,
            'subtopics': [
              {'name': 'Production Across Countries & Multinational Companies', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Foreign Trade and Integration of Markets', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'What is Globalisation & Enabling Factors (Technology/Policy)', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'World Trade Organisation (WTO) & Impact on India', 'status': 'NOT_STARTED', 'mins': 40},
            ],
          },
          {
            'id': 'ch_sst_22',
            'name': 'Consumer Rights',
            'orderIndex': 21,
            'subtopics': [
              {'name': 'The Consumer in the Marketplace & Consumer Movement', 'status': 'NOT_STARTED', 'mins': 30},
              {'name': 'Consumer Rights (COPRA 1986): Safety, Information, Redressal', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Consumer Duties and Awareness Movement', 'status': 'NOT_STARTED', 'mins': 30},
            ],
          },
        ],
      },

      // 4. ENGLISH LANGUAGE AND LITERATURE
      {
        'id': 'sub_english',
        'name': 'English',
        'colorHex': '#5C7C8A',
        'iconName': 'menu_book',
        'orderIndex': 3,
        'chapters': [
          {
            'id': 'ch_eng_1',
            'name': 'Reading Comprehension',
            'orderIndex': 0,
            'subtopics': [
              {'name': 'Discursive Passage Analysis & Inference', 'status': 'COMPLETED', 'mins': 40},
              {'name': 'Case-based Factual Passage with Visuals', 'status': 'NOT_STARTED', 'mins': 40},
            ],
          },
          {
            'id': 'ch_eng_2',
            'name': 'Grammar and Writing Skills',
            'orderIndex': 1,
            'subtopics': [
              {'name': 'Tenses, Modals & Subject-Verb Concord', 'status': 'COMPLETED', 'mins': 40},
              {'name': 'Reported Speech (Commands, Requests, Statements)', 'status': 'NEEDS_REVISION', 'mins': 40},
              {'name': 'Formal Letter Writing (Complaint / Enquiry / Order)', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Analytical Paragraph Writing', 'status': 'NOT_STARTED', 'mins': 45},
            ],
          },
          {
            'id': 'ch_eng_3',
            'name': 'First Flight: Prose',
            'orderIndex': 2,
            'subtopics': [
              {'name': 'A Letter to God (Lencho)', 'status': 'COMPLETED', 'mins': 35},
              {'name': 'Nelson Mandela: Long Walk to Freedom', 'status': 'COMPLETED', 'mins': 40},
              {'name': 'Two Stories about Flying (Seagull & Black Aeroplane)', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'From the Diary of Anne Frank', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Glimpses of India (Baker, Coorg, Tea)', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Mijbil the Otter', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Madam Rides the Bus (Valli)', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'The Sermon at Benares (Gautama Buddha)', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'The Proposal (Anton Chekhov)', 'status': 'NOT_STARTED', 'mins': 45},
            ],
          },
          {
            'id': 'ch_eng_4',
            'name': 'First Flight: Poetry',
            'orderIndex': 3,
            'subtopics': [
              {'name': 'Dust of Snow & Fire and Ice', 'status': 'COMPLETED', 'mins': 30},
              {'name': 'A Tiger in the Zoo', 'status': 'NOT_STARTED', 'mins': 30},
              {'name': 'How to Tell Wild Animals & The Ball Poem', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Amanda! & The Trees', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Fog & The Tale of Custard the Dragon', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'For Anne Gregory', 'status': 'NOT_STARTED', 'mins': 30},
            ],
          },
          {
            'id': 'ch_eng_5',
            'name': 'Footprints Without Feet: Supplementary',
            'orderIndex': 4,
            'subtopics': [
              {'name': 'A Triumph of Surgery (Tricki & Dr. Herriot)', 'status': 'COMPLETED', 'mins': 35},
              {'name': 'The Thief\'s Story (Hari Singh & Anil)', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'The Midnight Visitor (Ausable & Max)', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'A Question of Trust (Horace Danby)', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Footprints Without Feet (Griffin)', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'The Making of a Scientist (Richard Ebright)', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'The Necklace (Matilda Loisel)', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Bholi (Sulekha)', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'The Book That Saved the Earth', 'status': 'NOT_STARTED', 'mins': 35},
            ],
          },
        ],
      },

      // 5. HINDI (COURSE A & COURSE B)
      {
        'id': 'sub_hindi',
        'name': 'Hindi',
        'colorHex': '#B86B77',
        'iconName': 'auto_stories',
        'orderIndex': 4,
        'chapters': [
          {
            'id': 'ch_hin_1',
            'name': 'क्षितिज भाग 2 (Course A)',
            'orderIndex': 0,
            'subtopics': [
              {'name': 'सूरदास के पद', 'status': 'COMPLETED', 'mins': 35},
              {'name': 'तुलसीदास: राम-लक्ष्मण-परशुराम संवाद', 'status': 'IN_PROGRESS', 'mins': 40},
              {'name': 'जयशंकर प्रसाद: आत्मकथ्य / उत्साह और अट नहीं रही', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'स्वयं प्रकाश: नेताजी का चश्मा', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'रामवृक्ष बेनीपुरी: बालगोबिन भगत', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'यशपाल: लखनवी अंदाज़', 'status': 'NOT_STARTED', 'mins': 35},
            ],
          },
          {
            'id': 'ch_hin_2',
            'name': 'कृतिका भाग 2 (Course A)',
            'orderIndex': 1,
            'subtopics': [
              {'name': 'शिवपूजन सहाय: माता का आँचल', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'मधु कांकरिया: साना-साना हाथ जोड़ि', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'अज्ञेय: मैं क्यों लिखता हूँ?', 'status': 'NOT_STARTED', 'mins': 30},
            ],
          },
          {
            'id': 'ch_hin_3',
            'name': 'स्पर्श भाग 2 (Course B)',
            'orderIndex': 2,
            'subtopics': [
              {'name': 'कबीर: साखी व मीरा: पद', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'प्रेमचंद: बड़े भाई साहब', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'सीताराम सेकसरिया: डायरी का एक पन्ना', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'लीलाधर मंडलोई: ततॉरा-वामीरो कथा', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'सुमित्रानंदन पंत: पर्वत प्रदेश में पावस', 'status': 'NOT_STARTED', 'mins': 35},
            ],
          },
          {
            'id': 'ch_hin_4',
            'name': 'संचयन भाग 2 (Course B)',
            'orderIndex': 3,
            'subtopics': [
              {'name': 'मिथिलेश्वर: हरिहर काका', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'गुरदयाल सिंह: सपनों के-से दिन', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'राही मासूम रज़ा: टोपी शुक्ला', 'status': 'NOT_STARTED', 'mins': 35},
            ],
          },
          {
            'id': 'ch_hin_5',
            'name': 'व्याकरण एवं रचनात्मक लेखन',
            'orderIndex': 4,
            'subtopics': [
              {'name': 'पदबंध एवं रचना के आधार पर वाक्य रूपांतरण', 'status': 'COMPLETED', 'mins': 40},
              {'name': 'समास एवं मुहावरे', 'status': 'NEEDS_REVISION', 'mins': 35},
              {'name': 'अनुच्छेद लेखन समसामयिक विषय', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'औपचारिक एवं अनौपचारिक पत्र लेखन', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'सूचना, विज्ञापन एवं ई-मेल लेखन', 'status': 'NOT_STARTED', 'mins': 35},
            ],
          },
        ],
      },

      // 6. INFORMATION TECHNOLOGY (IT - CODE 402)
      {
        'id': 'sub_it402',
        'name': 'Information Tech (402)',
        'colorHex': '#4B6584',
        'iconName': 'devices',
        'orderIndex': 5,
        'chapters': [
          {
            'id': 'ch_it_1',
            'name': 'Part A: Employability Skills',
            'orderIndex': 0,
            'subtopics': [
              {'name': 'Unit 1: Communication Skills-II', 'status': 'COMPLETED', 'mins': 30},
              {'name': 'Unit 2: Self-Management Skills-II', 'status': 'COMPLETED', 'mins': 30},
              {'name': 'Unit 3: Basic ICT Skills-II', 'status': 'IN_PROGRESS', 'mins': 35},
              {'name': 'Unit 4: Entrepreneurial Skills-II', 'status': 'NOT_STARTED', 'mins': 30},
              {'name': 'Unit 5: Green Skills-II', 'status': 'NOT_STARTED', 'mins': 30},
            ],
          },
          {
            'id': 'ch_it_2',
            'name': 'Part B: Digital Documentation (Advanced)',
            'orderIndex': 1,
            'subtopics': [
              {'name': 'Apply Styles in the Document', 'status': 'COMPLETED', 'mins': 35},
              {'name': 'Insert and Use Images in Document', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Create and Use Template', 'status': 'NOT_STARTED', 'mins': 30},
              {'name': 'Create and Customise Table of Contents', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Implement Mail Merge', 'status': 'NOT_STARTED', 'mins': 40},
            ],
          },
          {
            'id': 'ch_it_3',
            'name': 'Part B: Electronic Spreadsheet (Advanced)',
            'orderIndex': 2,
            'subtopics': [
              {'name': 'Analyse Data Using Scenarios and Goal Seek', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Link Data and Spreadsheets', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Share and Review a Spreadsheet', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Create and Use Macros in Spreadsheet', 'status': 'NOT_STARTED', 'mins': 40},
            ],
          },
          {
            'id': 'ch_it_4',
            'name': 'Part B: Database Management System (DBMS)',
            'orderIndex': 3,
            'subtopics': [
              {'name': 'Concepts of DBMS & RDBMS Principles', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Create and Edit Tables using SQL / Wizard', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Perform Operations on Tables (Primary Key, Data Types)', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Retrieve Data using Queries (SELECT, WHERE)', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Create Forms and Reports using Wizard', 'status': 'NOT_STARTED', 'mins': 40},
            ],
          },
          {
            'id': 'ch_it_5',
            'name': 'Part B: Web Applications and Security',
            'orderIndex': 4,
            'subtopics': [
              {'name': 'Working with Accessibility Options', 'status': 'NOT_STARTED', 'mins': 30},
              {'name': 'Networking Fundamentals & Client-Server Architecture', 'status': 'NOT_STARTED', 'mins': 35},
              {'name': 'Web Services, Instant Messaging & Blogs', 'status': 'NOT_STARTED', 'mins': 30},
              {'name': 'Cyber Security: Passwords, Firewalls & Phishing', 'status': 'NOT_STARTED', 'mins': 40},
              {'name': 'Workplace Safety, Accidents and Health Hazards', 'status': 'NOT_STARTED', 'mins': 30},
            ],
          },
          {
            'id': 'ch_it_6',
            'name': 'Practical and Project Work',
            'orderIndex': 5,
            'subtopics': [
              {'name': 'Hands-on Practical on LibreOffice Writer & Calc', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'RDBMS SQL Queries & Base Table Creation', 'status': 'NOT_STARTED', 'mins': 45},
              {'name': 'Viva Voce Preparation & Project Documentation', 'status': 'NOT_STARTED', 'mins': 40},
            ],
          },
        ],
      },
    ];

    for (final s in subjectsData) {
      await db.insert('subjects', {
        'id': s['id'],
        'name': s['name'],
        'colorHex': s['colorHex'],
        'iconName': s['iconName'],
        'orderIndex': s['orderIndex'],
        'createdAt': now.toIso8601String(),
      });

      final chapters = s['chapters'] as List;
      for (final ch in chapters) {
        await db.insert('chapters', {
          'id': ch['id'],
          'subjectId': s['id'],
          'name': ch['name'],
          'orderIndex': ch['orderIndex'],
          'createdAt': now.toIso8601String(),
        });

        final subtopics = ch['subtopics'] as List;
        for (var i = 0; i < subtopics.length; i++) {
          final sub = subtopics[i];
          await db.insert('subtopics', {
            'id': 'subtopic_${ch['id']}_$i',
            'chapterId': ch['id'],
            'name': sub['name'],
            'status': sub['status'],
            'estimatedMinutes': sub['mins'],
            'notes': null,
            'orderIndex': i,
            'completedAt': sub['status'] == 'COMPLETED' ? now.toIso8601String() : null,
            'revisionCount': sub['status'] == 'NEEDS_REVISION' ? 1 : 0,
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          });
        }
      }
    }
  }

  /// Force-reload CBSE Class 10 Board Exam 2027 Syllabus
  Future<void> reloadClass10Syllabus() async {
    final db = await database;
    await db.delete('subtopics');
    await db.delete('chapters');
    await db.delete('subjects');
    await seedInitialSyllabus(db);
  }

  // --- Profile Operations ---
  Future<UserProfile?> getUserProfile(String id) async {
    final db = await database;
    final maps = await db.query(
      'user_profiles',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return UserProfile.fromMap(maps.first);
    }
    return null;
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final db = await database;
    await db.insert(
      'user_profiles',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==========================================
  // SYLLABUS OPERATIONS (Phase 2)
  // ==========================================

  /// Fetches all subjects with their full chapter and subtopic hierarchy.
  Future<List<SubjectModel>> getSubjectsWithHierarchy() async {
    final db = await database;

    // 1. Fetch subjects
    final subjectMaps = await db.query('subjects', orderBy: 'orderIndex ASC');
    final List<SubjectModel> subjects = [];

    for (final sMap in subjectMaps) {
      final subjectId = sMap['id'] as String;

      // 2. Fetch chapters for this subject
      final chapterMaps = await db.query(
        'chapters',
        where: 'subjectId = ?',
        whereArgs: [subjectId],
        orderBy: 'orderIndex ASC',
      );

      final List<ChapterModel> chapters = [];

      for (final cMap in chapterMaps) {
        final chapterId = cMap['id'] as String;

        // 3. Fetch subtopics for this chapter
        final subtopicMaps = await db.query(
          'subtopics',
          where: 'chapterId = ?',
          whereArgs: [chapterId],
          orderBy: 'orderIndex ASC',
        );

        final subtopics = subtopicMaps.map((subMap) => SubtopicModel.fromMap(subMap)).toList();
        chapters.add(ChapterModel.fromMap(cMap, subtopics: subtopics));
      }

      subjects.add(SubjectModel.fromMap(sMap, chapters: chapters));
    }

    return subjects;
  }

  /// Subject CRUD
  Future<void> insertSubject(SubjectModel subject) async {
    final db = await database;
    await db.insert(
      'subjects',
      subject.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSubject(SubjectModel subject) async {
    final db = await database;
    await db.update(
      'subjects',
      subject.toMap(),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
  }

  Future<void> deleteSubject(String subjectId) async {
    final db = await database;
    // SQLite foreign keys / cascade or explicit cleanup
    final chapters = await db.query('chapters', where: 'subjectId = ?', whereArgs: [subjectId]);
    for (final ch in chapters) {
      await db.delete('subtopics', where: 'chapterId = ?', whereArgs: [ch['id']]);
    }
    await db.delete('chapters', where: 'subjectId = ?', whereArgs: [subjectId]);
    await db.delete('subjects', where: 'id = ?', whereArgs: [subjectId]);
  }

  Future<void> reorderSubjects(List<String> subjectIds) async {
    final db = await database;
    final batch = db.batch();
    for (var i = 0; i < subjectIds.length; i++) {
      batch.update(
        'subjects',
        {'orderIndex': i},
        where: 'id = ?',
        whereArgs: [subjectIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Chapter CRUD
  Future<void> insertChapter(ChapterModel chapter) async {
    final db = await database;
    await db.insert(
      'chapters',
      chapter.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateChapter(ChapterModel chapter) async {
    final db = await database;
    await db.update(
      'chapters',
      chapter.toMap(),
      where: 'id = ?',
      whereArgs: [chapter.id],
    );
  }

  Future<void> deleteChapter(String chapterId) async {
    final db = await database;
    await db.delete('subtopics', where: 'chapterId = ?', whereArgs: [chapterId]);
    await db.delete('chapters', where: 'id = ?', whereArgs: [chapterId]);
  }

  Future<void> reorderChapters(List<String> chapterIds) async {
    final db = await database;
    final batch = db.batch();
    for (var i = 0; i < chapterIds.length; i++) {
      batch.update(
        'chapters',
        {'orderIndex': i},
        where: 'id = ?',
        whereArgs: [chapterIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Subtopic CRUD & Status Transitions
  Future<void> insertSubtopic(SubtopicModel subtopic) async {
    final db = await database;
    await db.insert(
      'subtopics',
      subtopic.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSubtopic(SubtopicModel subtopic) async {
    final db = await database;
    await db.update(
      'subtopics',
      subtopic.toMap(),
      where: 'id = ?',
      whereArgs: [subtopic.id],
    );
  }

  Future<void> updateSubtopicStatus(String subtopicId, TopicStatus status) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final updateData = <String, dynamic>{
      'status': status.code,
      'updatedAt': now,
    };

    if (status == TopicStatus.completed) {
      updateData['completedAt'] = now;
    } else if (status == TopicStatus.needsRevision) {
      // Increment revision count
      await db.rawUpdate('''
        UPDATE subtopics 
        SET revisionCount = revisionCount + 1, status = ?, updatedAt = ? 
        WHERE id = ?
      ''', [status.code, now, subtopicId]);
      return;
    }

    await db.update(
      'subtopics',
      updateData,
      where: 'id = ?',
      whereArgs: [subtopicId],
    );
  }

  Future<void> updateSubtopicNotes(String subtopicId, String? notes) async {
    final db = await database;
    await db.update(
      'subtopics',
      {
        'notes': notes,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [subtopicId],
    );
  }

  Future<void> updateSubtopicDuration(String subtopicId, int minutes) async {
    final db = await database;
    await db.update(
      'subtopics',
      {
        'estimatedMinutes': minutes,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [subtopicId],
    );
  }

  Future<void> deleteSubtopic(String subtopicId) async {
    final db = await database;
    await db.delete('subtopics', where: 'id = ?', whereArgs: [subtopicId]);
  }

  Future<void> reorderSubtopics(List<String> subtopicIds) async {
    final db = await database;
    final batch = db.batch();
    for (var i = 0; i < subtopicIds.length; i++) {
      batch.update(
        'subtopics',
        {'orderIndex': i},
        where: 'id = ?',
        whereArgs: [subtopicIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Revision & Restudy Queues
  Future<List<SubtopicModel>> getRevisionQueue() async {
    final db = await database;
    final maps = await db.query(
      'subtopics',
      where: 'status = ?',
      whereArgs: ['NEEDS_REVISION'],
      orderBy: 'updatedAt DESC',
    );
    return maps.map((m) => SubtopicModel.fromMap(m)).toList();
  }

  Future<List<SubtopicModel>> getRestudyQueue() async {
    final db = await database;
    final maps = await db.query(
      'subtopics',
      where: 'status = ?',
      whereArgs: ['NEEDS_RESTUDY'],
      orderBy: 'updatedAt DESC',
    );
    return maps.map((m) => SubtopicModel.fromMap(m)).toList();
  }

  /// Search across subjects, chapters, and subtopics
  Future<List<Map<String, dynamic>>> searchSyllabus(String query) async {
    final db = await database;
    final pattern = '%$query%';

    final results = await db.rawQuery('''
      SELECT 
        s.id AS subjectId, s.name AS subjectName, s.colorHex,
        c.id AS chapterId, c.name AS chapterName,
        sub.id AS subtopicId, sub.name AS subtopicName, sub.status, sub.estimatedMinutes
      FROM subtopics sub
      JOIN chapters c ON sub.chapterId = c.id
      JOIN subjects s ON c.subjectId = s.id
      WHERE sub.name LIKE ? OR c.name LIKE ? OR s.name LIKE ?
      ORDER BY s.orderIndex, c.orderIndex, sub.orderIndex
    ''', [pattern, pattern, pattern]);

    return results;
  }

  // ==========================================
  // PLANNER & EXAM OPERATIONS (Phase 3)
  // ==========================================

  static String formatDbDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// Initial seed for upcoming exams
  Future<void> seedInitialPlannerData([Database? targetDb]) async {
    final db = targetDb ?? await database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Seed initial exams
    final examCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM exams'),
    );
    if (examCount == null || examCount == 0) {
      final sampleExams = [
        {
          'id': 'exam_pb_maths',
          'title': 'Pre-Board 1: Mathematics',
          'examDate': today.add(const Duration(days: 18)).toIso8601String(),
          'targetScore': 95,
          'colorHex': '#4A7C59',
          'createdAt': now.toIso8601String(),
        },
        {
          'id': 'exam_pb_science',
          'title': 'Pre-Board 1: Science',
          'examDate': today.add(const Duration(days: 25)).toIso8601String(),
          'targetScore': 95,
          'colorHex': '#3B8A6E',
          'createdAt': now.toIso8601String(),
        },
        {
          'id': 'exam_board_maths_2027',
          'title': 'CBSE Class 10 Board Exam 2027: Mathematics',
          'examDate': DateTime(2027, 3, 11, 10, 30).toIso8601String(),
          'targetScore': 100,
          'colorHex': '#4A7C59',
          'createdAt': now.toIso8601String(),
        },
        {
          'id': 'exam_board_science_2027',
          'title': 'CBSE Class 10 Board Exam 2027: Science',
          'examDate': DateTime(2027, 3, 2, 10, 30).toIso8601String(),
          'targetScore': 100,
          'colorHex': '#3B8A6E',
          'createdAt': now.toIso8601String(),
        },
      ];

      for (final e in sampleExams) {
        await db.insert('exams', e);
      }
    }
  }

  /// Get tasks for a specific date (YYYY-MM-DD), with joined subject details
  Future<List<PlannerTaskModel>> getTasksForDate(String dateStr) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT pt.*, s.name AS subjectName, s.colorHex AS subjectColorHex
      FROM planner_tasks pt
      LEFT JOIN subjects s ON pt.subjectId = s.id
      WHERE pt.date = ?
      ORDER BY pt.startTime ASC, pt.createdAt ASC
    ''', [dateStr]);

    return results.map((m) => PlannerTaskModel.fromMap(m)).toList();
  }

  /// Get tasks across a date range (for weekly / monthly summaries)
  Future<List<PlannerTaskModel>> getTasksForDateRange(String startDate, String endDate) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT pt.*, s.name AS subjectName, s.colorHex AS subjectColorHex
      FROM planner_tasks pt
      LEFT JOIN subjects s ON pt.subjectId = s.id
      WHERE pt.date >= ? AND pt.date <= ?
      ORDER BY pt.date ASC, pt.startTime ASC, pt.createdAt ASC
    ''', [startDate, endDate]);

    return results.map((m) => PlannerTaskModel.fromMap(m)).toList();
  }

  /// Get all missed tasks before a given date (for adaptive rescheduling)
  Future<List<PlannerTaskModel>> getMissedTasksBefore(String dateStr) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT pt.*, s.name AS subjectName, s.colorHex AS subjectColorHex
      FROM planner_tasks pt
      LEFT JOIN subjects s ON pt.subjectId = s.id
      WHERE (pt.date < ? AND pt.status = 'MISSED')
         OR (pt.date < ? AND pt.status = 'UPCOMING')
      ORDER BY pt.date DESC, pt.createdAt ASC
    ''', [dateStr, dateStr]);

    return results.map((m) => PlannerTaskModel.fromMap(m)).toList();
  }

  /// Insert a newly scheduled task
  Future<void> insertPlannerTask(PlannerTaskModel task) async {
    final db = await database;
    await db.insert(
      'planner_tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing task
  Future<void> updatePlannerTask(PlannerTaskModel task) async {
    final db = await database;
    await db.update(
      'planner_tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  /// Delete a task
  Future<void> deletePlannerTask(String taskId) async {
    final db = await database;
    await db.delete('planner_tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  /// Fetch all exams
  Future<List<ExamModel>> getExams() async {
    final db = await database;
    final results = await db.query('exams', orderBy: 'examDate ASC');
    return results.map((m) => ExamModel.fromMap(m)).toList();
  }

  /// Insert an exam
  Future<void> insertExam(ExamModel exam) async {
    final db = await database;
    await db.insert('exams', exam.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Delete an exam
  Future<void> deleteExam(String examId) async {
    final db = await database;
    await db.delete('exams', where: 'id = ?', whereArgs: [examId]);
  }

  /// Update an existing exam
  Future<int> updateExam(ExamModel exam) async {
    final db = await database;
    return await db.update('exams', exam.toMap(), where: 'id = ?', whereArgs: [exam.id]);
  }

  /// Purge all dummy mock data so the student starts completely fresh
  Future<void> purgeDummyDataAndStartFresh([Database? targetDb]) async {
    final db = targetDb ?? await database;
    await ensureForestTablesExist(db);
    // Remove dummy trees
    await db.delete('forest_trees');
    // Remove dummy planner tasks
    await db.delete('planner_tasks');
    // Remove dummy study sessions
    await db.delete('study_sessions');
    // Remove dummy journal entries
    await db.delete('forest_journal');
    // Clear shared spaces
    try {
      await db.delete('shared_spaces');
    } catch (_) {}
    // Reset all subtopics to clean NOT_STARTED
    try {
      await db.update('subtopics', {
        'status': 'NOT_STARTED',
        'completedAt': null,
        'revisionCount': 0,
      });
    } catch (_) {}
    // Reset achievements progress
    await db.update('achievements', {'progress': 0, 'isUnlocked': 0, 'unlockedAt': null});
    // Reset decorations to locked and unequipped
    await db.update('forest_decorations', {'isUnlocked': 0, 'isEquipped': 0});
    // Reset user profile stats to clean slate (0 XP, 0 coins, 0 streak)
    try {
      await db.update('user_profiles', {
        'streakDays': 0,
        'bestStreak': 0,
        'totalXp': 0,
        'coins': 0,
        'activeSharedSpaceId': null,
      });
    } catch (_) {}
  }

  // ==========================================
  // NAVBLOOM FOREST & GAMIFICATION OPERATIONS (Phase 4)
  // ==========================================

  Future<void> ensureForestTablesExist([Database? targetDb]) async {
    final db = targetDb ?? await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS forest_trees (
        id TEXT PRIMARY KEY,
        sessionId TEXT,
        treeType TEXT NOT NULL DEFAULT 'Mountain Pine',
        stage INTEGER NOT NULL DEFAULT 1,
        gridX INTEGER NOT NULL DEFAULT 0,
        gridY INTEGER NOT NULL DEFAULT 0,
        xRatio REAL NOT NULL DEFAULT 0.5,
        yRatio REAL NOT NULL DEFAULT 0.5,
        plantedAt TEXT NOT NULL,
        maturedAt TEXT,
        subjectName TEXT,
        chapterName TEXT,
        focusMinutes INTEGER NOT NULL DEFAULT 25,
        xpEarned INTEGER NOT NULL DEFAULT 100,
        coinsEarned INTEGER NOT NULL DEFAULT 25,
        status TEXT NOT NULL DEFAULT 'HEALTHY',
        isShared INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Add any missing columns to existing forest_trees table if needed
    try { await db.execute('ALTER TABLE forest_trees ADD COLUMN xRatio REAL NOT NULL DEFAULT 0.5'); } catch (_) {}
    try { await db.execute('ALTER TABLE forest_trees ADD COLUMN yRatio REAL NOT NULL DEFAULT 0.5'); } catch (_) {}
    try { await db.execute('ALTER TABLE forest_trees ADD COLUMN chapterName TEXT'); } catch (_) {}
    try { await db.execute('ALTER TABLE forest_trees ADD COLUMN focusMinutes INTEGER NOT NULL DEFAULT 25'); } catch (_) {}
    try { await db.execute('ALTER TABLE forest_trees ADD COLUMN xpEarned INTEGER NOT NULL DEFAULT 100'); } catch (_) {}
    try { await db.execute('ALTER TABLE forest_trees ADD COLUMN coinsEarned INTEGER NOT NULL DEFAULT 25'); } catch (_) {}
    try { await db.execute('ALTER TABLE forest_trees ADD COLUMN status TEXT NOT NULL DEFAULT "HEALTHY"'); } catch (_) {}

    await db.execute('''
      CREATE TABLE IF NOT EXISTS forest_decorations (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        costCoins INTEGER NOT NULL,
        isUnlocked INTEGER NOT NULL DEFAULT 0,
        isEquipped INTEGER NOT NULL DEFAULT 0,
        xRatio REAL NOT NULL DEFAULT 0.5,
        yRatio REAL NOT NULL DEFAULT 0.5,
        iconName TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS forest_journal (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        subjectName TEXT,
        focusMinutes INTEGER NOT NULL DEFAULT 0,
        xpEarned INTEGER NOT NULL DEFAULT 0,
        coinsEarned INTEGER NOT NULL DEFAULT 0,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS achievements (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        iconName TEXT NOT NULL,
        progress INTEGER NOT NULL DEFAULT 0,
        target INTEGER NOT NULL DEFAULT 1,
        isUnlocked INTEGER NOT NULL DEFAULT 0,
        unlockedAt TEXT,
        xpReward INTEGER NOT NULL DEFAULT 100,
        coinsReward INTEGER NOT NULL DEFAULT 50
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS reward_transactions (
        transactionId TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        xpAmount INTEGER NOT NULL DEFAULT 0,
        coinsAmount INTEGER NOT NULL DEFAULT 0,
        reason TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  /// Initial seed for Forest decorations and achievements catalogue
  Future<void> seedInitialForestData([Database? targetDb]) async {
    final db = targetDb ?? await database;
    await ensureForestTablesExist(db);

    // 1. Seed Decorations Catalogue if empty (all initially locked)
    final decCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM forest_decorations'),
    );
    if (decCount == null || decCount == 0) {
      final sampleDecs = [
        const ForestDecorationModel(
          id: 'dec_lantern_1',
          name: 'Stone Lantern',
          description: 'Glows warmly in the moonlit forest during night study sessions.',
          category: DecorationCategory.lighting,
          costCoins: 60,
          isUnlocked: false,
          isEquipped: false,
          xRatio: 0.38,
          yRatio: 0.48,
          iconName: 'light_mode',
        ),
        const ForestDecorationModel(
          id: 'dec_wildflowers_1',
          name: 'Wildflower Bed',
          description: 'Fragrant pink and blue alpine blossoms that brighten the meadow.',
          category: DecorationCategory.flora,
          costCoins: 40,
          isUnlocked: false,
          isEquipped: false,
          xRatio: 0.62,
          yRatio: 0.54,
          iconName: 'local_florist',
        ),
        const ForestDecorationModel(
          id: 'dec_stones_1',
          name: 'Stepping Stones',
          description: 'Smooth river stones leading towards the whispering waterfall.',
          category: DecorationCategory.pathway,
          costCoins: 80,
          isUnlocked: false,
          isEquipped: false,
          xRatio: 0.50,
          yRatio: 0.68,
          iconName: 'route',
        ),
        const ForestDecorationModel(
          id: 'dec_bench_1',
          name: 'Cedar Reading Bench',
          description: 'A quiet carved wooden bench near the mountain pine.',
          category: DecorationCategory.furniture,
          costCoins: 120,
          isUnlocked: false,
          isEquipped: false,
          xRatio: 0.68,
          yRatio: 0.64,
          iconName: 'chair',
        ),
        const ForestDecorationModel(
          id: 'dec_pond_1',
          name: 'Koi Birdbath Basin',
          description: 'Clear crystal spring water reflecting morning skies.',
          category: DecorationCategory.furniture,
          costCoins: 180,
          isUnlocked: false,
          isEquipped: false,
          xRatio: 0.20,
          yRatio: 0.62,
          iconName: 'water_drop',
        ),
        const ForestDecorationModel(
          id: 'dec_fire_1',
          name: 'Cozy Hearth Campfire',
          description: 'Crackling campfire embers for warm evening revision.',
          category: DecorationCategory.lighting,
          costCoins: 250,
          isUnlocked: false,
          isEquipped: false,
          xRatio: 0.55,
          yRatio: 0.78,
          iconName: 'fireplace',
        ),
      ];

      for (final d in sampleDecs) {
        await db.insert('forest_decorations', d.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    // 2. Seed Achievements Catalogue if empty (all initially locked with 0 progress)
    final achCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM achievements'),
    );
    if (achCount == null || achCount == 0) {
      final sampleAchievements = [
        const AchievementModel(
          id: 'ach_first_seed',
          title: 'First Seed',
          description: 'Complete your first 25-minute valid focus session.',
          iconName: 'spa',
          progress: 0,
          target: 1,
          isUnlocked: false,
          xpReward: 100,
          coinsReward: 50,
        ),
        const AchievementModel(
          id: 'ach_green_thumb',
          title: 'Green Thumb',
          description: 'Grow 5 trees to Stage 5 Full Bloom in your forest.',
          iconName: 'park',
          progress: 0,
          target: 5,
          isUnlocked: false,
          xpReward: 250,
          coinsReward: 100,
        ),
        const AchievementModel(
          id: 'ach_deep_roots',
          title: 'Deep Roots',
          description: 'Accumulate 10 total focus hours in NavNest.',
          iconName: 'alarm_on',
          progress: 0,
          target: 10,
          isUnlocked: false,
          xpReward: 300,
          coinsReward: 150,
        ),
        const AchievementModel(
          id: 'ach_night_owl',
          title: 'Moonlit Sanctuary',
          description: 'Complete 3 focus sessions in Moonlit Night mode.',
          iconName: 'dark_mode',
          progress: 0,
          target: 3,
          isUnlocked: false,
          xpReward: 150,
          coinsReward: 75,
        ),
        const AchievementModel(
          id: 'ach_cbse_scholar',
          title: 'CBSE 10 Scholar',
          description: 'Cover 25 syllabus subtopics across any subjects.',
          iconName: 'auto_stories',
          progress: 0,
          target: 25,
          isUnlocked: false,
          xpReward: 400,
          coinsReward: 200,
        ),
      ];

      for (final a in sampleAchievements) {
        await db.insert('achievements', a.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }

  // --- Forest Trees DB Methods ---
  Future<List<ForestTreeModel>> getForestTrees() async {
    final db = await database;
    await ensureForestTablesExist(db);
    final results = await db.query('forest_trees', orderBy: 'plantedAt DESC');
    return results.map((m) => ForestTreeModel.fromMap(m)).toList();
  }

  Future<void> insertForestTree(ForestTreeModel tree) async {
    final db = await database;
    await ensureForestTablesExist(db);
    await db.insert('forest_trees', tree.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateForestTree(ForestTreeModel tree) async {
    final db = await database;
    await ensureForestTablesExist(db);
    await db.update('forest_trees', tree.toMap(), where: 'id = ?', whereArgs: [tree.id]);
  }

  Future<void> deleteForestTree(String treeId) async {
    final db = await database;
    await ensureForestTablesExist(db);
    await db.delete('forest_trees', where: 'id = ?', whereArgs: [treeId]);
  }

  // --- Forest Decorations DB Methods ---
  Future<List<ForestDecorationModel>> getDecorations() async {
    final db = await database;
    await ensureForestTablesExist(db);
    final results = await db.query('forest_decorations');
    return results.map((m) => ForestDecorationModel.fromMap(m)).toList();
  }

  Future<void> unlockDecoration(String id, int costCoins) async {
    final db = await database;
    await ensureForestTablesExist(db);
    await db.update('forest_decorations', {'isUnlocked': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleEquipDecoration(String id, bool equip) async {
    final db = await database;
    await ensureForestTablesExist(db);
    await db.update('forest_decorations', {'isEquipped': equip ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateDecorationPosition(String id, double xRatio, double yRatio) async {
    final db = await database;
    await ensureForestTablesExist(db);
    await db.update('forest_decorations', {'xRatio': xRatio, 'yRatio': yRatio}, where: 'id = ?', whereArgs: [id]);
  }

  // --- Forest Journal DB Methods ---
  Future<List<ForestJournalEntry>> getJournalEntries() async {
    final db = await database;
    await ensureForestTablesExist(db);
    final results = await db.query('forest_journal', orderBy: 'date DESC');
    return results.map((m) => ForestJournalEntry.fromMap(m)).toList();
  }

  Future<void> insertJournalEntry(ForestJournalEntry entry) async {
    final db = await database;
    await ensureForestTablesExist(db);
    await db.insert('forest_journal', entry.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Achievements DB Methods ---
  Future<List<AchievementModel>> getAchievements() async {
    final db = await database;
    await ensureForestTablesExist(db);
    final results = await db.query('achievements');
    return results.map((m) => AchievementModel.fromMap(m)).toList();
  }

  Future<void> updateAchievementProgress(String id, int newProgress) async {
    final db = await database;
    await ensureForestTablesExist(db);
    final map = await db.query('achievements', where: 'id = ?', whereArgs: [id], limit: 1);
    if (map.isNotEmpty) {
      final target = (map.first['target'] as num).toInt();
      final isUnlocked = newProgress >= target ? 1 : 0;
      final unlockedAt = isUnlocked == 1 ? DateTime.now().toIso8601String() : null;
      await db.update(
        'achievements',
        {
          'progress': newProgress,
          'isUnlocked': isUnlocked,
          if (unlockedAt != null) 'unlockedAt': unlockedAt,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // --- Study Sessions DB Methods ---
  Future<void> insertStudySession(StudySessionModel session) async {
    final db = await database;
    await db.insert('study_sessions', session.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<StudySessionModel>> getStudySessions({int limit = 50}) async {
    final db = await database;
    final results = await db.query(
      'study_sessions',
      orderBy: 'startedAt DESC',
      limit: limit,
    );
    return results.map((m) => StudySessionModel.fromMap(m)).toList();
  }

  Future<int> getTodayFocusMinutes() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
    final results = await db.rawQuery(
      'SELECT SUM(activeSeconds) as totalSeconds FROM study_sessions WHERE startedAt >= ?',
      [startOfDay],
    );
    final totalSec = (results.first['totalSeconds'] as num?)?.toInt() ?? 0;
    return (totalSec / 60).round();
  }

  // --- Shared Space DB Methods ---
  Future<void> saveSharedSpace(SharedSpaceModel space) async {
    final db = await database;
    await db.insert('shared_spaces', space.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<SharedSpaceModel?> getSharedSpace(String spaceId) async {
    final db = await database;
    final results = await db.query('shared_spaces', where: 'id = ?', whereArgs: [spaceId], limit: 1);
    if (results.isEmpty) return null;
    return SharedSpaceModel.fromMap(results.first);
  }

  Future<SharedSpaceModel?> getSharedSpaceByCode(String inviteCode) async {
    final db = await database;
    final results = await db.query(
      'shared_spaces',
      where: 'UPPER(inviteCode) = ?',
      whereArgs: [inviteCode.trim().toUpperCase()],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return SharedSpaceModel.fromMap(results.first);
  }

  Future<void> clearSharedSpace() async {
    final db = await database;
    await db.delete('shared_spaces');
  }

  // --- Close DB ---
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
