import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/models/shared_cheer_model.dart';
import '../../../../core/models/shared_space_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/shared_space_service.dart';

class SharedSpaceProvider extends ChangeNotifier {
  final SharedSpaceService _service;
  final AuthService _authService;
  final DatabaseHelper _dbHelper;
  final LocalStorageService _storage;

  SharedSpaceModel? _currentSpace;
  List<SharedCheerModel> _cheers = [];
  Map<String, dynamic>? _partnerStatus;

  bool _isLoading = false;
  String? _errorMessage;
  String? _statusMessage;

  StreamSubscription<SharedSpaceModel?>? _spaceSubscription;
  StreamSubscription<List<SharedCheerModel>>? _cheersSubscription;
  StreamSubscription<Map<String, dynamic>?>? _partnerStatusSubscription;

  SharedSpaceProvider({
    required SharedSpaceService service,
    required AuthService authService,
    DatabaseHelper? dbHelper,
    required LocalStorageService storage,
  })  : _service = service,
        _authService = authService,
        _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _storage = storage;

  SharedSpaceModel? get currentSpace => _currentSpace;
  List<SharedCheerModel> get cheers => _cheers;
  Map<String, dynamic>? get partnerStatus => _partnerStatus;

  bool get isPaired => _currentSpace?.isPaired ?? _storage.isSharedPaired;
  String get currentUserId => _authService.effectiveUserId;

  String get partnerName {
    if (_currentSpace != null && _currentSpace!.isPaired) {
      final name = _currentSpace!.getPartnerName(currentUserId);
      if (name.isNotEmpty) return name;
    }
    return _storage.sharedPartnerName;
  }

  String get inviteCode {
    if (_currentSpace?.inviteCode != null && _currentSpace!.inviteCode.isNotEmpty) {
      return _currentSpace!.inviteCode;
    }
    return _storage.sharedInviteCode;
  }

  String get partnerTopic => _partnerStatus?['currentSubject'] as String? ?? 'CBSE Class 10 Board Prep';
  int get partnerFocusMinutesToday => (_partnerStatus?['todayFocusMinutes'] as num?)?.toInt() ?? 0;
  int get partnerTreesCountToday => (_partnerStatus?['todayTreesCount'] as num?)?.toInt() ?? 0;
  bool get isPartnerFocusing => _partnerStatus?['isFocusing'] as bool? ?? false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Load cached space from local SQLite
      final localSpace = await _dbHelper.getActiveSharedSpace();
      if (localSpace != null) {
        _currentSpace = localSpace;
        _startListening(localSpace.id);
      } else if (_storage.isSharedPaired) {
        // Fallback for legacy state
        _storage.setSharedPaired(false);
      }
    } catch (e) {
      debugPrint('Error initializing SharedSpaceProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startListening(String spaceId) {
    _spaceSubscription?.cancel();
    _cheersSubscription?.cancel();
    _partnerStatusSubscription?.cancel();

    if (_dbHelper.isDemoMode) {
      _partnerStatus = {
        'currentSubject': 'Science: Acids, Bases and Salts',
        'todayFocusMinutes': 90,
        'todayTreesCount': 2,
        'isFocusing': true,
      };
      notifyListeners();
      return;
    }

    _spaceSubscription = _service.watchSharedSpace(spaceId).listen((space) {
      if (space != null) {
        _currentSpace = space;
        _dbHelper.saveSharedSpace(space);
        _storage.setSharedPaired(space.isPaired);
        if (space.isPaired) {
          final partner = space.getPartnerName(currentUserId);
          _storage.setSharedPartnerName(partner);
          _listenPartnerStatus(space.id, space.getPartnerId(currentUserId));
        }
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('Error listening to shared space: $e');
    });

    _cheersSubscription = _service.watchCheers(spaceId).listen((cheersList) {
      _cheers = cheersList;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to cheers: $e');
    });
  }

  void _listenPartnerStatus(String spaceId, String partnerUid) {
    if (partnerUid.isEmpty) return;
    _partnerStatusSubscription?.cancel();
    _partnerStatusSubscription =
        _service.watchPartnerStatus(spaceId, partnerUid).listen((status) {
      _partnerStatus = status;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to partner status: $e');
    });
  }

  /// Generate or refresh invitation code
  Future<String?> generateInviteCode() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _authService.currentUser;
      final creatorUid = _authService.effectiveUserId;
      final creatorName = user?.displayName ?? 'Student';

      final invite = await _service.createInvitation(
        creatorUid: creatorUid,
        creatorName: creatorName,
        existingSpaceId: _currentSpace?.id,
      );

      final localSpace = await _dbHelper.getActiveSharedSpace();
      if (localSpace != null) {
        _currentSpace = localSpace;
        _startListening(localSpace.id);
      }

      _statusMessage = 'Generated code: ${invite.inviteCode} (Valid for 48h)';
      return invite.inviteCode;
    } catch (e) {
      _errorMessage = 'Could not generate invite: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Join an existing space using an invite code
  Future<bool> joinSpace(String inviteCode, {String? partnerNameOverride}) async {
    _isLoading = true;
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();

    try {
      final user = _authService.currentUser;
      final joiningUid = _authService.effectiveUserId;
      final joiningName = user?.displayName ?? partnerNameOverride ?? 'Student';

      final joinedSpace = await _service.joinSpaceWithCode(
        inviteCode: inviteCode,
        joiningUid: joiningUid,
        joiningName: joiningName,
      );

      _currentSpace = joinedSpace;
      _startListening(joinedSpace.id);
      _statusMessage = 'Successfully joined private space with ${joinedSpace.getPartnerName(joiningUid)}!';
      return true;
    } catch (e) {
      _errorMessage = e is StateError ? e.message : 'Failed to join: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Disconnect / Leave space
  Future<void> leaveSpace() async {
    if (_currentSpace == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final spaceId = _currentSpace!.id;
      final userId = _authService.effectiveUserId;

      _spaceSubscription?.cancel();
      _cheersSubscription?.cancel();
      _partnerStatusSubscription?.cancel();

      await _service.leaveSpace(spaceId: spaceId, userId: userId);

      _currentSpace = null;
      _partnerStatus = null;
      _cheers = [];
      _statusMessage = 'Disconnected from Shared Space.';
    } catch (e) {
      _errorMessage = 'Error leaving space: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send encouragement cheer
  Future<bool> sendCheer(String emoji, String message) async {
    if (_currentSpace == null) return false;
    try {
      final user = _authService.currentUser;
      await _service.sendCheer(
        spaceId: _currentSpace!.id,
        senderUid: _authService.effectiveUserId,
        senderName: user?.displayName ?? 'Partner',
        emoji: emoji,
        message: message,
      );
      return true;
    } catch (e) {
      debugPrint('Error sending cheer: $e');
      return false;
    }
  }

  /// Update own focus study status for partner accountability
  Future<void> reportStudyProgress({
    required bool isFocusing,
    String? subjectName,
    required int todayFocusMinutes,
    required int todayTreesCount,
  }) async {
    if (_currentSpace == null || !_currentSpace!.isPaired) return;
    try {
      final user = _authService.currentUser;
      await _service.updateMemberStatus(
        spaceId: _currentSpace!.id,
        uid: _authService.effectiveUserId,
        displayName: user?.displayName ?? 'Student',
        isFocusing: isFocusing,
        currentSubject: subjectName,
        todayFocusMinutes: todayFocusMinutes,
        todayTreesCount: todayTreesCount,
      );
    } catch (e) {
      debugPrint('Error reporting study progress: $e');
    }
  }

  @override
  void dispose() {
    _spaceSubscription?.cancel();
    _cheersSubscription?.cancel();
    _partnerStatusSubscription?.cancel();
    super.dispose();
  }
}
