import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The "ตู๊ด… ตู๊ด…" the caller hears while the driver's phone rings. The
/// server sends nothing for it: the app plays it from the start request's 201
/// until `call_accepted` / `call_ended`, or `ring_timeout_sec`.
abstract class CallRingback {
  Future<void> start();
  Future<void> stop();
}

final callRingbackProvider = Provider<CallRingback>((ref) {
  final ringback = AssetCallRingback();
  ref.onDispose(ringback.dispose);
  return ringback;
});

/// Loops `assets/sounds/ringback.wav` (Thai ringing tone: 400 Hz, 1 s on,
/// 4 s off) in the call's audio session, so it doesn't fight WebRTC for it:
/// play-and-record on iOS, call signalling on Android without taking audio
/// focus.
class AssetCallRingback implements CallRingback {
  AudioPlayer? _player;
  bool _playing = false;

  static final _context = AudioContext(
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playAndRecord,
      options: const {AVAudioSessionOptions.allowBluetooth},
    ),
    android: const AudioContextAndroid(
      usageType: AndroidUsageType.voiceCommunicationSignalling,
      contentType: AndroidContentType.sonification,
      audioFocus: AndroidAudioFocus.none,
    ),
  );

  @override
  Future<void> start() async {
    if (_playing) return;
    _playing = true;
    try {
      final player = _player ??= AudioPlayer(playerId: 'call_ringback');
      await player.setAudioContext(_context);
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(0.6);
      // Stopped while it was being set up.
      if (!_playing) return;
      await player.play(AssetSource('sounds/ringback.wav'));
      if (!_playing) await player.stop();
    } catch (e) {
      debugPrint('Call: ringback failed: $e');
    }
  }

  @override
  Future<void> stop() async {
    if (!_playing) return;
    _playing = false;
    try {
      await _player?.stop();
    } catch (e) {
      debugPrint('Call: ringback stop failed: $e');
    }
  }

  void dispose() {
    _playing = false;
    _player?.dispose();
    _player = null;
  }
}
