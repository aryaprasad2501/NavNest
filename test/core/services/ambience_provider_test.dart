import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navnest/core/services/ambience_provider.dart';

class MockAudioAdapter implements AmbienceAudioAdapter {
  final StreamController<PlayerState> _stateController = StreamController<PlayerState>.broadcast();
  String? lastPlayedAsset;
  bool? lastLoop;
  double? lastVolume;
  bool isPlaying = false;
  bool isDisposed = false;
  bool shouldThrowOnPlay = false;

  @override
  Stream<PlayerState> get onPlayerStateChanged => _stateController.stream;

  @override
  Future<void> playAsset(String assetPath, {required bool loop, required double volume}) async {
    if (shouldThrowOnPlay) {
      throw Exception('Synthetic audio play failure');
    }
    lastPlayedAsset = assetPath;
    lastLoop = loop;
    lastVolume = volume;
    isPlaying = true;
    _stateController.add(PlayerState.playing);
  }

  @override
  Future<void> pause() async {
    isPlaying = false;
    _stateController.add(PlayerState.paused);
  }

  @override
  Future<void> resume() async {
    isPlaying = true;
    _stateController.add(PlayerState.playing);
  }

  @override
  Future<void> stop() async {
    isPlaying = false;
    _stateController.add(PlayerState.stopped);
  }

  @override
  Future<void> setVolume(double volume) async {
    lastVolume = volume;
  }

  @override
  void dispose() {
    isDisposed = true;
    _stateController.close();
  }
}

void main() {
  group('AmbienceProvider Tests', () {
    late MockAudioAdapter mockAdapter;
    late AmbienceProvider provider;

    setUp(() {
      mockAdapter = MockAudioAdapter();
      provider = AmbienceProvider(adapter: mockAdapter);
    });

    tearDown(() {
      provider.dispose();
    });

    test('Initial state is idle with no track and default 70% volume', () {
      expect(provider.currentTrack, AmbienceTrack.none);
      expect(provider.isPlaying, isFalse);
      expect(provider.hasActiveAudio, isFalse);
      expect(provider.volume, 0.7);
      expect(provider.errorMessage, isNull);
    });

    test('playTrack switches track, requests loop and updates active audio flag', () async {
      await provider.playTrack(AmbienceTrack.rain);

      expect(provider.currentTrack, AmbienceTrack.rain);
      expect(provider.isPlaying, isTrue);
      expect(provider.hasActiveAudio, isTrue);
      expect(mockAdapter.lastPlayedAsset, 'audio/rain_ambience.wav');
      expect(mockAdapter.lastLoop, isTrue);
      expect(mockAdapter.lastVolume, 0.7);
    });

    test('playTrack with forest track switches seamlessly', () async {
      await provider.playTrack(AmbienceTrack.forest);

      expect(provider.currentTrack, AmbienceTrack.forest);
      expect(provider.isPlaying, isTrue);
      expect(mockAdapter.lastPlayedAsset, 'audio/forest_ambience.wav');
    });

    test('playTrack with none stops audio and resets state', () async {
      await provider.playTrack(AmbienceTrack.rain);
      expect(provider.isPlaying, isTrue);

      await provider.playTrack(AmbienceTrack.none);
      expect(provider.currentTrack, AmbienceTrack.none);
      expect(provider.isPlaying, isFalse);
      expect(provider.hasActiveAudio, isFalse);
    });

    test('pause and resume toggles playback without resetting selected track', () async {
      await provider.playTrack(AmbienceTrack.rain);
      expect(provider.isPlaying, isTrue);

      await provider.pause();
      expect(provider.isPlaying, isFalse);
      expect(provider.currentTrack, AmbienceTrack.rain);
      expect(provider.hasActiveAudio, isFalse);

      await provider.resume();
      expect(provider.isPlaying, isTrue);
      expect(provider.currentTrack, AmbienceTrack.rain);
      expect(provider.hasActiveAudio, isTrue);
    });

    test('togglePlayPause plays default rain when none selected', () async {
      await provider.togglePlayPause();
      expect(provider.currentTrack, AmbienceTrack.rain);
      expect(provider.isPlaying, isTrue);

      await provider.togglePlayPause();
      expect(provider.isPlaying, isFalse);
    });

    test('setVolume clamps volume between 0.0 and 1.0', () async {
      await provider.setVolume(1.5);
      expect(provider.volume, 1.0);
      expect(mockAdapter.lastVolume, 1.0);

      await provider.setVolume(-0.2);
      expect(provider.volume, 0.0);
      expect(mockAdapter.lastVolume, 0.0);

      await provider.setVolume(0.45);
      expect(provider.volume, 0.45);
      expect(mockAdapter.lastVolume, 0.45);
    });

    test('Gracefully captures error without throwing or corrupting app state', () async {
      mockAdapter.shouldThrowOnPlay = true;

      await provider.playTrack(AmbienceTrack.rain);
      expect(provider.isPlaying, isFalse);
      expect(provider.currentTrack, AmbienceTrack.none);
      expect(provider.errorMessage, isNotNull);
      expect(provider.errorMessage, contains('Synthetic audio play failure'));
    });
  });
}
