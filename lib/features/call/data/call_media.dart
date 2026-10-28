import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Where the audio connection stands.
enum CallMediaState { connecting, connected, disconnected, failed }

/// The audio side of a call: the microphone and one WebRTC peer connection.
/// The signalling (who sends what, when) is the controller's job; this only
/// wraps the peer connection so the controller can be tested without it.
abstract class CallMedia {
  /// Opens the microphone. The first call asks for the permission; a refusal
  /// throws.
  Future<void> openMicrophone();

  /// Creates the peer connection with the backend's [iceServers] and the
  /// microphone track.
  Future<void> connect(List<Map<String, dynamic>> iceServers);

  /// Creates an offer, sets it as the local description and returns it as
  /// `{type, sdp}`. [iceRestart] for a network change.
  Future<Map<String, dynamic>> createOffer({bool iceRestart = false});

  /// Answers the remote offer (already set) and returns `{type, sdp}`.
  Future<Map<String, dynamic>> createAnswer();

  /// Applies the other phone's `{type, sdp}`.
  Future<void> setRemoteDescription(Map<String, dynamic> description);

  /// Applies one of the other phone's `{candidate, sdpMid, sdpMLineIndex}`.
  Future<void> addCandidate(Map<String, dynamic> candidate);

  /// This phone's ICE candidates, as `{candidate, sdpMid, sdpMLineIndex}`.
  Stream<Map<String, dynamic>> get candidates;

  Stream<CallMediaState> get states;

  Future<void> setMuted(bool muted);

  Future<void> setSpeaker(bool on);

  Future<void> close();
}

class WebRtcCallMedia implements CallMedia {
  MediaStream? _mic;
  RTCPeerConnection? _pc;
  final _candidates = StreamController<Map<String, dynamic>>.broadcast();
  final _states = StreamController<CallMediaState>.broadcast();

  @override
  Stream<Map<String, dynamic>> get candidates => _candidates.stream;

  @override
  Stream<CallMediaState> get states => _states.stream;

  @override
  Future<void> openMicrophone() async {
    if (_mic != null) return;
    await _configureAudio();
    _mic = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
  }

  /// A voice call's audio session: playAndRecord / voiceChat on iOS (the
  /// earpiece, with Bluetooth), the communication mode on Android.
  Future<void> _configureAudio() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await Helper.setAppleAudioConfiguration(
          AppleAudioConfiguration(
            appleAudioCategory: AppleAudioCategory.playAndRecord,
            appleAudioCategoryOptions: const {
              AppleAudioCategoryOption.allowBluetooth,
            },
            appleAudioMode: AppleAudioMode.voiceChat,
          ),
        );
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        await Helper.setAndroidAudioConfiguration(
          AndroidAudioConfiguration.communication,
        );
      }
    } catch (e) {
      debugPrint('CallMedia: audio configuration failed (ignored): $e');
    }
  }

  @override
  Future<void> connect(List<Map<String, dynamic>> iceServers) async {
    await openMicrophone();
    final pc = await createPeerConnection({
      'iceServers': iceServers,
      'sdpSemantics': 'unified-plan',
    });
    _pc = pc;
    pc.onIceCandidate = (c) {
      if (c.candidate == null) return;
      _candidates.add({
        'candidate': c.candidate,
        'sdpMid': c.sdpMid,
        'sdpMLineIndex': c.sdpMLineIndex,
      });
    };
    pc.onConnectionState = (s) {
      final state = switch (s) {
        RTCPeerConnectionState.RTCPeerConnectionStateConnected =>
          CallMediaState.connected,
        RTCPeerConnectionState.RTCPeerConnectionStateDisconnected =>
          CallMediaState.disconnected,
        RTCPeerConnectionState.RTCPeerConnectionStateFailed =>
          CallMediaState.failed,
        RTCPeerConnectionState.RTCPeerConnectionStateNew ||
        RTCPeerConnectionState.RTCPeerConnectionStateConnecting =>
          CallMediaState.connecting,
        RTCPeerConnectionState.RTCPeerConnectionStateClosed => null,
      };
      if (state != null && !_states.isClosed) _states.add(state);
    };
    for (final track in _mic!.getAudioTracks()) {
      await pc.addTrack(track, _mic!);
    }
  }

  @override
  Future<Map<String, dynamic>> createOffer({bool iceRestart = false}) async {
    final pc = _pc!;
    final offer = await pc.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
      if (iceRestart) 'iceRestart': true,
    });
    await pc.setLocalDescription(offer);
    return {'type': offer.type, 'sdp': offer.sdp};
  }

  @override
  Future<Map<String, dynamic>> createAnswer() async {
    final pc = _pc!;
    final answer = await pc.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });
    await pc.setLocalDescription(answer);
    return {'type': answer.type, 'sdp': answer.sdp};
  }

  @override
  Future<void> setRemoteDescription(Map<String, dynamic> description) =>
      _pc!.setRemoteDescription(
        RTCSessionDescription(
          description['sdp'] as String?,
          description['type'] as String?,
        ),
      );

  @override
  Future<void> addCandidate(Map<String, dynamic> candidate) =>
      _pc!.addCandidate(
        RTCIceCandidate(
          candidate['candidate'] as String?,
          candidate['sdpMid'] as String?,
          (candidate['sdpMLineIndex'] as num?)?.toInt(),
        ),
      );

  @override
  Future<void> setMuted(bool muted) async {
    for (final track in _mic?.getAudioTracks() ?? const <MediaStreamTrack>[]) {
      track.enabled = !muted;
    }
  }

  @override
  Future<void> setSpeaker(bool on) => Helper.setSpeakerphoneOn(on);

  @override
  Future<void> close() async {
    final pc = _pc;
    final mic = _mic;
    _pc = null;
    _mic = null;
    try {
      await pc?.close();
      for (final track in mic?.getTracks() ?? const <MediaStreamTrack>[]) {
        await track.stop();
      }
      await mic?.dispose();
    } catch (e) {
      debugPrint('CallMedia: close failed (ignored): $e');
    }
    await _candidates.close();
    await _states.close();
  }
}
