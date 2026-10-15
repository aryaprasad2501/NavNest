import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';
import '../database/database_helper.dart';
import 'cloud_sync_service.dart';

class AuthService extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  final GoogleSignIn _googleSignIn;
  FirebaseAuth? _firebaseAuth;

  UserProfile? _currentUser;
  bool _isLoading = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _syncStatusMessage;
  StreamSubscription<User?>? _authSubscription;

  AuthService({
    DatabaseHelper? dbHelper,
    GoogleSignIn? googleSignIn,
    FirebaseAuth? firebaseAuth,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId: '385060063635-0v55tebqgg5bc0u354jtlr238e8ep2vm.apps.googleusercontent.com',
              scopes: <String>[
                'email',
                'https://www.googleapis.com/auth/userinfo.profile',
              ],
            ) {
    if (firebaseAuth != null) {
      _firebaseAuth = firebaseAuth;
    } else {
      try {
        _firebaseAuth = FirebaseAuth.instance;
      } catch (e) {
        debugPrint('FirebaseAuth not yet initialized in current environment: $e');
      }
    }
  }

  UserProfile? get currentUser => _currentUser;
  User? get firebaseUser => _firebaseAuth?.currentUser;
  String get effectiveUserId => firebaseUser?.uid ?? _currentUser?.id ?? 'default_student';

  bool get isAuthenticated => firebaseUser != null;
  bool get isGoogleLinked =>
      firebaseUser != null &&
      (firebaseUser!.providerData.any((p) => p.providerId == 'google.com') ||
          (_currentUser?.email != null && _currentUser!.email!.isNotEmpty));

  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get syncStatusMessage => _syncStatusMessage;

  Stream<User?> get authStateChanges {
    if (_firebaseAuth != null) {
      return _firebaseAuth!.authStateChanges();
    }
    return const Stream.empty();
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Listen to real Firebase Auth state changes
      if (_firebaseAuth != null) {
        _authSubscription?.cancel();
        _authSubscription = _firebaseAuth!.authStateChanges().listen((user) async {
          await _syncFromFirebaseUser(user);
        });
      }

      // 2. Load authoritative local user profile
      final currentFirebaseUser = _firebaseAuth?.currentUser;
      if (currentFirebaseUser != null) {
        await _syncFromFirebaseUser(currentFirebaseUser);
      } else {
        _currentUser = await _dbHelper.getUserProfile('default_student');
        if (_currentUser == null) {
          final newProfile = UserProfile.defaultProfile();
          await _dbHelper.saveUserProfile(newProfile);
          _currentUser = newProfile;
        }
      }
    } catch (e) {
      debugPrint('Error initializing AuthService: $e');
      _currentUser = UserProfile.defaultProfile();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reloads user profile from active database (production or demo)
  Future<void> reloadProfile() async {
    if (_dbHelper.isDemoMode) {
      _currentUser = await _dbHelper.getUserProfile('demo_student_arya');
      notifyListeners();
      return;
    }
    final currentFirebaseUser = _firebaseAuth?.currentUser;
    if (currentFirebaseUser != null) {
      await _syncFromFirebaseUser(currentFirebaseUser);
    } else {
      _currentUser = await _dbHelper.getUserProfile('default_student');
      if (_currentUser == null) {
        final newProfile = UserProfile.defaultProfile();
        await _dbHelper.saveUserProfile(newProfile);
        _currentUser = newProfile;
      }
    }
    notifyListeners();
  }

  Future<void> _syncFromFirebaseUser(User? user) async {
    if (user != null) {
      var profile = await _dbHelper.getUserProfile(user.uid);
      if (profile == null) {
        // Fallback to default_student data or create fresh profile linked to this Firebase UID
        final defaultStudent = await _dbHelper.getUserProfile('default_student');
        profile = UserProfile(
          id: user.uid,
          displayName: user.displayName?.isNotEmpty == true
              ? user.displayName!
              : (defaultStudent?.displayName ?? 'Student'),
          email: user.email,
          photoUrl: user.photoURL,
          streakDays: defaultStudent?.streakDays ?? 0,
          bestStreak: defaultStudent?.bestStreak ?? 0,
          totalXp: defaultStudent?.totalXp ?? 0,
          coins: defaultStudent?.coins ?? 0,
          dailyTargetMinutes: defaultStudent?.dailyTargetMinutes ?? 120,
          activeSharedSpaceId: defaultStudent?.activeSharedSpaceId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        profile = profile.copyWith(
          displayName: user.displayName?.isNotEmpty == true ? user.displayName : profile.displayName,
          email: user.email ?? profile.email,
          photoUrl: user.photoURL ?? profile.photoUrl,
          updatedAt: DateTime.now(),
        );
      }
      await _dbHelper.saveUserProfile(profile);
      _currentUser = profile;
    } else {
      // Revert to local default_student profile if signed out
      _currentUser = await _dbHelper.getUserProfile('default_student');
      if (_currentUser == null) {
        _currentUser = UserProfile.defaultProfile();
        await _dbHelper.saveUserProfile(_currentUser!);
      }
    }
    notifyListeners();
  }

  /// Updates profile data (XP, streak, display name, etc.)
  Future<void> updateProfile(UserProfile updated) async {
    _currentUser = updated;
    await _dbHelper.saveUserProfile(updated);
    notifyListeners();
  }

  /// Genuine Google Sign-In with Native OAuth Token Exchange with Firebase Auth
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _syncStatusMessage = 'Connecting to Google Services...';
    notifyListeners();

    try {
      final googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        _syncStatusMessage = 'Sign in cancelled by user.';
        return false;
      }

      final googleAuth = await googleAccount.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (_firebaseAuth != null) {
        final userCredential = await _firebaseAuth!.signInWithCredential(credential);
        final user = userCredential.user;
        if (user != null) {
          await _syncFromFirebaseUser(user);
          _lastSyncTime = DateTime.now();
          _syncStatusMessage = 'Signed in as ${user.email ?? user.displayName} ✓';
          return true;
        }
      } else {
        // Fallback when Firebase native engine is offline / uninitialized
        final updated = (_currentUser ?? UserProfile.defaultProfile()).copyWith(
          displayName: googleAccount.displayName ?? 'Google Student',
          email: googleAccount.email,
          photoUrl: googleAccount.photoUrl,
          updatedAt: DateTime.now(),
        );
        await updateProfile(updated);
        _lastSyncTime = DateTime.now();
        _syncStatusMessage = 'Linked with Google account: ${googleAccount.email}';
        return true;
      }

      return false;
    } on FirebaseAuthException catch (fe) {
      debugPrint('Firebase Auth error: ${fe.code} - ${fe.message}');
      _syncStatusMessage = _formatFirebaseAuthError(fe);
      return false;
    } catch (e) {
      debugPrint('Sign-in error: $e');
      _syncStatusMessage = 'Could not sign in with Google: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Connects / associates an account profile with display name and email.
  Future<bool> linkGoogleAccount({
    required String displayName,
    required String email,
    String? photoUrl,
  }) async {
    _isLoading = true;
    _syncStatusMessage = 'Connecting account...';
    notifyListeners();

    try {
      if (firebaseUser != null) {
        try {
          await firebaseUser!.updateDisplayName(displayName);
        } catch (_) {}
      }

      final current = _currentUser ?? UserProfile.defaultProfile();
      final updated = current.copyWith(
        displayName: displayName.isNotEmpty ? displayName : current.displayName,
        email: email.trim(),
        photoUrl: photoUrl ?? current.photoUrl,
        updatedAt: DateTime.now(),
      );
      await updateProfile(updated);
      _lastSyncTime = DateTime.now();
      _syncStatusMessage = 'Account linked: $email ✓';
      return true;
    } catch (e) {
      debugPrint('Error linking Google account: $e');
      _syncStatusMessage = 'Failed to link account: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Triggers cloud backup synchronization with CloudSyncService
  Future<bool> syncDataWithCloud({CloudSyncService? syncService}) async {
    _isSyncing = true;
    notifyListeners();
    try {
      if (syncService != null) {
        final success = await syncService.triggerFullBackup();
        _lastSyncTime = syncService.lastSyncTime ?? DateTime.now();
        _syncStatusMessage = syncService.statusMessage;
        return success;
      }
      final directSync = CloudSyncService(
        firebaseAuth: _firebaseAuth,
        dbHelper: _dbHelper,
      );
      final success = await directSync.triggerFullBackup();
      _lastSyncTime = directSync.lastSyncTime ?? DateTime.now();
      _syncStatusMessage = directSync.statusMessage;
      return success;
    } catch (e) {
      _syncStatusMessage = 'Sync failed: $e';
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Sign In with Email and Password
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (_firebaseAuth == null) {
      _syncStatusMessage = 'Firebase Authentication is not available.';
      return false;
    }

    _isLoading = true;
    _syncStatusMessage = 'Signing in with email...';
    notifyListeners();

    try {
      final cred = await _firebaseAuth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (cred.user != null) {
        await _syncFromFirebaseUser(cred.user);
        _syncStatusMessage = 'Signed in successfully as ${cred.user!.email}';
        return true;
      }
      return false;
    } on FirebaseAuthException catch (fe) {
      _syncStatusMessage = _formatFirebaseAuthError(fe);
      return false;
    } catch (e) {
      _syncStatusMessage = 'Sign in failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register / Create Account with Email and Password
  Future<bool> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (_firebaseAuth == null) {
      _syncStatusMessage = 'Firebase Authentication is not available.';
      return false;
    }

    _isLoading = true;
    _syncStatusMessage = 'Creating account...';
    notifyListeners();

    try {
      final cred = await _firebaseAuth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (cred.user != null) {
        await cred.user!.updateDisplayName(displayName.trim());
        await _syncFromFirebaseUser(cred.user);
        _syncStatusMessage = 'Account created for ${cred.user!.email}';
        return true;
      }
      return false;
    } on FirebaseAuthException catch (fe) {
      _syncStatusMessage = _formatFirebaseAuthError(fe);
      return false;
    } catch (e) {
      _syncStatusMessage = 'Account registration failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      if (_firebaseAuth != null) {
        await _firebaseAuth!.signOut();
      }

      // Revert to local default_student profile without wiping local database
      _currentUser = await _dbHelper.getUserProfile('default_student');
      _lastSyncTime = null;
      _syncStatusMessage = 'Signed out. Personal study data remains safely preserved on device.';
    } catch (e) {
      debugPrint('Error signing out: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _formatFirebaseAuthError(FirebaseAuthException fe) {
    switch (fe.code) {
      case 'user-not-found':
        return 'No student account found for this email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please verify and try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'Network connection unavailable. Changes will sync once back online.';
      default:
        return fe.message ?? 'Authentication error (${fe.code}).';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
