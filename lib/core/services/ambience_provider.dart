import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum AmbienceTrack {
  none(
    id: 'none',
    displayName: 'Off',
    iconEmoji: '🔇',
    assetPath: null,
  ),
  rain(
    id: 'rain',
    displayName: 'Rain Ambience',
    iconEmoji: '🌧️',
    assetPath: 'audio/rain_ambience.wav',
  ),
  forest(
    id: 'forest',
    displayName: 'Forest Ambience',
    iconEmoji: '🌲',
    assetPath: 'audio/forest_ambience.wav',
  );

  final String id;
  final String displayName;
  final String iconEmoji;
  final String? assetPath;

  const AmbienceTrack({
    required this.id,
    required this.displayName,
    required this.iconEmoji,
    required this.assetPath,
  });
}

/// Abstract audio adapter to allow lightweight unit testing and robust platform playback.
abstract class AmbienceAudioAdapter {
  Future<void> playAsset(String assetPath, {required bool loop, required double volume});
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> setVolume(double volume);
  Stream<PlayerState> get onPlayerStateChanged;
  void dispose();
}

/// Production audio adapter utilizing package:audioplayers
class DefaultAudioplayersAdapter implements AmbienceAudioAdapter {
  final AudioPlayer _player;

  DefaultAudioplayersAdapter([AudioPlayer? player]) : _player = player ?? AudioPlayer();

  @override
  Future<void> playAsset(String assetPath, {required bool loop, required double volume}) async {
    await _player.stop();
    await _player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
    await _player.setVolume(volume);
    await _player.play(AssetSource(assetPath));
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;

  @override
  void dispose() => _player.dispose();
}

/// Authoritative single shared ambience audio management service for NavNest.
/// Synchronizes playback between Focus and NavBloom screens.
class AmbienceProvider extends ChangeNotifier {
  final AmbienceAudioAdapter _adapter;
  StreamSubscription<PlayerState>? _stateSubscription;

  AmbienceTrack _currentTrack = AmbienceTrack.none;
  bool _isPlaying = false;
  bool _isLoading = false;
  double _volume = 0.7; // Default 70% volume
  String? _errorMessage;

  AmbienceProvider({AmbienceAudioAdapter? adapter})
      : _adapter = adapter ?? DefaultAudioplayersAdapter() {
    _initListener();
  }

  void _initListener() {
    try {
      _stateSubscription = _adapter.onPlayerStateChanged.listen(
        (state) {
          final playing = state == PlayerState.playing;
          if (_isPlaying != playing) {
            _isPlaying = playing;
            notifyListeners();
          }
        },
        onError: (err) {
          debugPrint('AmbienceProvider state listener error: $err');
        },
      );
    } catch (e) {
      debugPrint('AmbienceProvider initialization warning (e.g. test environment): $e');
    }
  }

  // --- Getters ---
  AmbienceTrack get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  double get volume => _volume;
  String? get errorMessage => _errorMessage;
  bool get hasActiveAudio => _currentTrack != AmbienceTrack.none && _isPlaying;
  bool get isRaining => _isPlaying && _currentTrack == AmbienceTrack.rain;

  /// Selects and plays the specified ambience track, or stops if none.
  Future<void> selectTrack(AmbienceTrack track) => playTrack(track);

  /// Plays or switches to the specified ambience track with looping.
  Future<void> playTrack(AmbienceTrack track) async {
    if (track == AmbienceTrack.none) {
      await stop();
      return;
    }

    if (track.assetPath == null) {
      _errorMessage = 'No audio asset registered for ${track.displayName}';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentTrack = track;
      await _adapter.playAsset(
        track.assetPath!,
        loop: true,
        volume: _volume,
      );
      _isPlaying = true;
    } catch (e, stack) {
      debugPrint('AmbienceProvider error playing ${track.displayName}: $e\n$stack');
      _errorMessage = 'Failed to play ${track.displayName}: $e';
      _isPlaying = false;
      _currentTrack = AmbienceTrack.none;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles playback for the currently selected track (or starts rain by default).
  Future<void> togglePlayPause() async {
    if (_currentTrack == AmbienceTrack.none) {
      await playTrack(AmbienceTrack.rain);
      return;
    }

    if (_isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  /// Pauses the current track without resetting track selection.
  Future<void> pause() async {
    if (!_isPlaying) return;
    try {
      await _adapter.pause();
      _isPlaying = false;
      _errorMessage = null;
    } catch (e) {
      debugPrint('AmbienceProvider pause error: $e');
      _errorMessage = 'Failed to pause audio: $e';
    } finally {
      notifyListeners();
    }
  }

  /// Resumes playback of the current track.
  Future<void> resume() async {
    if (_currentTrack == AmbienceTrack.none) return;
    try {
      await _adapter.resume();
      _isPlaying = true;
      _errorMessage = null;
    } catch (e) {
      debugPrint('AmbienceProvider resume error: $e');
      _errorMessage = 'Failed to resume audio: $e';
    } finally {
      notifyListeners();
    }
  }

  /// Stops playback completely and resets active track to none.
  Future<void> stop() async {
    try {
      await _adapter.stop();
      _currentTrack = AmbienceTrack.none;
      _isPlaying = false;
      _errorMessage = null;
    } catch (e) {
      debugPrint('AmbienceProvider stop error: $e');
      _errorMessage = 'Failed to stop audio: $e';
    } finally {
      notifyListeners();
    }
  }

  /// Sets audio playback volume (clamped between 0.0 and 1.0).
  Future<void> setVolume(double newVolume) async {
    final clamped = newVolume.clamp(0.0, 1.0);
    _volume = clamped;
    notifyListeners();
    try {
      await _adapter.setVolume(_volume);
    } catch (e) {
      debugPrint('AmbienceProvider setVolume error: $e');
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    try {
      _adapter.dispose();
    } catch (_) {}
    super.dispose();
  }
}
