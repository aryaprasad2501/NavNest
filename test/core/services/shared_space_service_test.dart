import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:navnest/core/database/database_helper.dart';
import 'package:navnest/core/models/shared_cheer_model.dart';
import 'package:navnest/core/models/shared_space_invite_model.dart';
import 'package:navnest/core/models/shared_space_model.dart';
import 'package:navnest/core/services/local_storage_service.dart';
import 'package:navnest/core/services/shared_space_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Database inMemoryDb;
  late DatabaseHelper dbHelper;
  late LocalStorageService storage;
  late SharedSpaceService service;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    inMemoryDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    dbHelper = DatabaseHelper.instance;
    dbHelper.setDatabaseForTesting(inMemoryDb);

    await dbHelper.ensureSharedSpacesTableExist(inMemoryDb);
    await dbHelper.ensureSyncQueueTableExist(inMemoryDb);

    SharedPreferences.setMockInitialValues({});
    storage = await LocalStorageService.init();
    service = SharedSpaceService(
      storage: storage,
      dbHelper: dbHelper,
    );
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('SharedSpaceService Invite Code Cryptographic Format Tests', () {
    test('generateSecureInviteCode produces standard NEST-XXXXXX format', () {
      final code = service.generateSecureInviteCode();
      expect(code, startsWith('NEST-'));
      expect(code.length, equals(11));

      // Must only contain permitted unambiguous characters (no 0, O, 1, I)
      final body = code.substring(5);
      final allowedRegex = RegExp(r'^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{6}$');
      expect(allowedRegex.hasMatch(body), isTrue);
    });

    test('generateSecureInviteCode produces high entropy unique codes', () {
      final codes = <String>{};
      for (int i = 0; i < 50; i++) {
        final code = service.generateSecureInviteCode();
        expect(codes.contains(code), isFalse, reason: 'Duplicate code generated: $code');
        codes.add(code);
      }
      expect(codes.length, equals(50));
    });
  });

  group('SharedSpaceInviteModel Integrity Tests', () {
    test('isValid returns true for active, unexpired invite', () {
      final now = DateTime.now();
      final invite = SharedSpaceInviteModel(
        inviteCode: 'NEST-ABCDEF',
        spaceId: 'space_123',
        creatorUid: 'user_a',
        creatorName: 'Arjun',
        status: 'ACTIVE',
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 48)),
      );

      expect(invite.isValid, isTrue);
      expect(invite.isExpired, isFalse);
    });

    test('isExpired returns true when past expiration time', () {
      final now = DateTime.now();
      final expiredInvite = SharedSpaceInviteModel(
        inviteCode: 'NEST-EXPIRED',
        spaceId: 'space_123',
        creatorUid: 'user_a',
        creatorName: 'Arjun',
        status: 'ACTIVE',
        createdAt: now.subtract(const Duration(hours: 50)),
        expiresAt: now.subtract(const Duration(hours: 2)),
      );

      expect(expiredInvite.isExpired, isTrue);
      expect(expiredInvite.isValid, isFalse);
    });

    test('isValid returns false when status is ACCEPTED', () {
      final now = DateTime.now();
      final acceptedInvite = SharedSpaceInviteModel(
        inviteCode: 'NEST-CLAIMED',
        spaceId: 'space_123',
        creatorUid: 'user_a',
        creatorName: 'Arjun',
        status: 'ACCEPTED',
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 48)),
        claimedByUid: 'user_b',
      );

      expect(acceptedInvite.isValid, isFalse);
    });
  });

  group('SharedSpaceModel 1-to-1 Constraints & Member Resolution', () {
    test('isPaired is true only when strictly 2 members are present', () {
      final spaceSolo = SharedSpaceModel(
        id: 'space_1',
        name: 'Study Grove',
        inviteCode: 'NEST-TEST01',
        createdByUserId: 'user_a',
        memberIds: ['user_a'],
        memberProfiles: {
          'user_a': {'displayName': 'Arjun'},
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(spaceSolo.isPaired, isFalse);

      final spacePaired = spaceSolo.copyWith(
        memberIds: ['user_a', 'user_b'],
        memberProfiles: {
          'user_a': {'displayName': 'Arjun'},
          'user_b': {'displayName': 'Diya'},
        },
      );

      expect(spacePaired.isPaired, isTrue);
    });

    test('getPartnerName resolves opposite user displayName correctly', () {
      final space = SharedSpaceModel(
        id: 'space_1',
        name: 'Study Grove',
        inviteCode: 'NEST-TEST01',
        createdByUserId: 'user_a',
        memberIds: ['user_a', 'user_b'],
        memberProfiles: {
          'user_a': {'displayName': 'Arjun'},
          'user_b': {'displayName': 'Diya'},
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(space.getPartnerName('user_a'), equals('Diya'));
      expect(space.getPartnerName('user_b'), equals('Arjun'));
      expect(space.getPartnerId('user_a'), equals('user_b'));
      expect(space.getPartnerId('user_b'), equals('user_a'));
    });

    test('Serialization toMap and fromMap preserves all fields and structure', () {
      final now = DateTime(2026, 10, 12, 12, 0, 0);
      final space = SharedSpaceModel(
        id: 'space_42',
        name: 'Board Exam Sprint',
        inviteCode: 'NEST-SPRINT',
        createdByUserId: 'user_a',
        memberIds: ['user_a', 'user_b'],
        memberProfiles: {
          'user_a': {'displayName': 'Arjun'},
          'user_b': {'displayName': 'Diya'},
        },
        createdAt: now,
        updatedAt: now,
      );

      final map = space.toMap();
      final deserialized = SharedSpaceModel.fromMap(map);

      expect(deserialized.id, equals('space_42'));
      expect(deserialized.name, equals('Board Exam Sprint'));
      expect(deserialized.inviteCode, equals('NEST-SPRINT'));
      expect(deserialized.memberIds, equals(['user_a', 'user_b']));
      expect(deserialized.getPartnerName('user_a'), equals('Diya'));
    });
  });

  group('SharedCheerModel Serialization Tests', () {
    test('Converts to and from Firestore map format accurately', () {
      final now = DateTime(2026, 10, 12, 14, 30, 0);
      final cheer = SharedCheerModel(
        id: 'cheer_1',
        spaceId: 'space_42',
        senderUid: 'user_b',
        senderName: 'Diya',
        emoji: '🔥',
        message: 'Keep going! Crushing CBSE Physics today!',
        createdAt: now,
      );

      final firestoreMap = cheer.toFirestore();
      expect(firestoreMap['emoji'], equals('🔥'));
      expect(firestoreMap['senderName'], equals('Diya'));

      final restored = SharedCheerModel.fromFirestore(firestoreMap, 'cheer_1');
      expect(restored.id, equals('cheer_1'));
      expect(restored.message, equals('Keep going! Crushing CBSE Physics today!'));
      expect(restored.senderUid, equals('user_b'));
    });
  });

  group('SharedSpaceService Offline SQLite Persistence', () {
    test('createInvitation stores space locally in SQLite and localStorage', () async {
      final invite = await service.createInvitation(
        creatorUid: 'student_1',
        creatorName: 'Arjun',
        spaceName: 'Arjun & Partner Space',
      );

      expect(invite.inviteCode, startsWith('NEST-'));
      expect(invite.creatorUid, equals('student_1'));

      // Check SQLite
      final cachedSpace = await dbHelper.getActiveSharedSpace();
      expect(cachedSpace, isNotNull);
      expect(cachedSpace!.createdByUserId, equals('student_1'));
      expect(cachedSpace.name, equals('Arjun & Partner Space'));

      // Check localStorage
      expect(storage.sharedInviteCode, equals(invite.inviteCode));
    });

    test('leaveSpace clears local SQLite shared space and local storage', () async {
      await service.createInvitation(
        creatorUid: 'student_1',
        creatorName: 'Arjun',
      );
      expect(await dbHelper.getActiveSharedSpace(), isNotNull);

      await service.leaveSpace(spaceId: 'any_space', userId: 'student_1');

      expect(await dbHelper.getActiveSharedSpace(), isNull);
      expect(storage.isSharedPaired, isFalse);
    });
  });
}
