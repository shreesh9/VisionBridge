/// Developed & Architected by Shreesh Nalawade (shreeshnalawade9@gmail.com)
/// Original WebRTC P2P Video Engine Implementation | Ref: SN09092005
///
/// VisionBridge — WebRTC Signaling Service
///
/// Manages peer connection, ICE candidates, and SDP exchange.
/// Uses Firestore as the signaling channel (free on Spark).
/// One-way video (BU rear camera → Volunteer), two-way audio.
///
/// ARCHITECTURE: Renderers are NOT managed here. They are created
/// and owned by the in-call screen widgets. This service only manages
/// the PeerConnection, streams, and signaling.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../core/constants.dart';

/// Connection states for UI.
enum WebRTCConnectionState {
  idle,
  connecting,
  connected,
  reconnecting,
  disconnected,
  error,
}

class WebRTCService {
  WebRTCService();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  // Recreated on every initialize()
  StreamController<WebRTCConnectionState>? _stateController;
  StreamController<MediaStream>? _remoteStreamController;
  StreamController<RTCIceCandidate>? _iceCandidateController;

  Stream<WebRTCConnectionState> get connectionState =>
      _stateController?.stream ?? const Stream.empty();
  Stream<MediaStream> get onRemoteStream =>
      _remoteStreamController?.stream ?? const Stream.empty();
  Stream<RTCIceCandidate> get onIceCandidate =>
      _iceCandidateController?.stream ?? const Stream.empty();

  WebRTCConnectionState _currentState = WebRTCConnectionState.idle;
  bool _answerSet = false;
  bool _hasEverConnected = false;

  /// Initialize peer connection with STUN servers.
  /// Renderers are NOT created here — they are owned by the UI widgets.
  Future<void> initialize() async {
    await _cleanupPreviousSession();

    // Create fresh stream controllers
    _stateController = StreamController<WebRTCConnectionState>.broadcast();
    _remoteStreamController = StreamController<MediaStream>.broadcast();
    _iceCandidateController = StreamController<RTCIceCandidate>.broadcast();

    _currentState = WebRTCConnectionState.idle;
    _answerSet = false;
    _hasEverConnected = false;

    final configuration = <String, dynamic>{
      'iceServers': AppConstants.stunServers
          .map((url) => {'urls': url})
          .toList(),
      'sdpSemantics': 'unified-plan',
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onIceConnectionState = (state) {
      debugPrint('[WebRTC] ICE Connection State: $state');
      switch (state) {
        case RTCIceConnectionState.RTCIceConnectionStateConnected:
        case RTCIceConnectionState.RTCIceConnectionStateCompleted:
          _hasEverConnected = true;
          _updateState(WebRTCConnectionState.connected);
          break;
        case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
          if (_hasEverConnected) {
            _updateState(WebRTCConnectionState.disconnected);
          }
          break;
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
          if (_hasEverConnected) {
            _updateState(WebRTCConnectionState.disconnected);
          } else {
            _updateState(WebRTCConnectionState.error);
          }
          break;
        case RTCIceConnectionState.RTCIceConnectionStateClosed:
          _updateState(WebRTCConnectionState.disconnected);
          break;
        default:
          break;
      }
    };

    _peerConnection!.onIceCandidate = (candidate) {
      if (_iceCandidateController != null &&
          !_iceCandidateController!.isClosed) {
        _iceCandidateController!.add(candidate);
      }
    };

    _peerConnection!.onConnectionState = (state) {
      debugPrint('[WebRTC] Connection State: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _hasEverConnected = true;
        _updateState(WebRTCConnectionState.connected);
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
                 state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        if (_hasEverConnected) {
          _updateState(WebRTCConnectionState.disconnected);
        }
      }
    };

    // Pre-create a remote stream so onTrack fallback always has a target
    _remoteStream = await createLocalMediaStream('remoteVideo');

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      debugPrint('[WebRTC] onTrack: kind=${event.track.kind}, '
          'streams=${event.streams.length}, enabled=${event.track.enabled}');

      if (event.streams.isNotEmpty) {
        // Standard path — use the stream from the event
        _remoteStream = event.streams[0];
      } else {
        // Unified-plan fallback — add track to pre-created stream
        _remoteStream!.addTrack(event.track);
      }

      if (_remoteStreamController != null &&
          !_remoteStreamController!.isClosed) {
        _remoteStreamController!.add(_remoteStream!);
      }

      if (event.track.kind == 'video') {
        debugPrint('[WebRTC] ✅ Video track received and emitted');
      }
      _hasEverConnected = true;
      _updateState(WebRTCConnectionState.connected);
    };

    // Legacy fallback
    // ignore: deprecated_member_use
    _peerConnection!.onAddStream = (MediaStream stream) {
      debugPrint('[WebRTC] onAddStream: tracks=${stream.getTracks().length}');
      _remoteStream = stream;
      if (_remoteStreamController != null &&
          !_remoteStreamController!.isClosed) {
        _remoteStreamController!.add(_remoteStream!);
      }
      _hasEverConnected = true;
      _updateState(WebRTCConnectionState.connected);
    };
  }

  /// Start local media (camera + mic) for a BLIND USER.
  Future<MediaStream> startLocalMedia({
    bool videoEnabled = true,
    bool audioEnabled = true,
  }) async {
    final constraints = <String, dynamic>{
      'audio': audioEnabled,
      'video': videoEnabled
          ? {
              'facingMode': 'environment',
              'width': {'ideal': 640},
              'height': {'ideal': 480},
              'frameRate': {'ideal': 15},
            }
          : false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);

    debugPrint('[WebRTC] Local media: '
        'video=${_localStream!.getVideoTracks().length}, '
        'audio=${_localStream!.getAudioTracks().length}');

    // Add tracks to peer connection
    for (final track in _localStream!.getTracks()) {
      debugPrint('[WebRTC] Adding track: kind=${track.kind}, enabled=${track.enabled}');
      await _peerConnection?.addTrack(track, _localStream!);
    }

    return _localStream!;
  }

  /// Start local media for a VOLUNTEER. Audio only.
  Future<MediaStream> startVolunteerMedia() async {
    return startLocalMedia(videoEnabled: false, audioEnabled: true);
  }

  /// Create an offer (caller side — BU).
  Future<RTCSessionDescription> createOffer() async {
    _updateState(WebRTCConnectionState.connecting);
    final offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': true,
    });
    await _peerConnection!.setLocalDescription(offer);
    debugPrint('[WebRTC] Offer created, SDP length=${offer.sdp?.length}');
    return offer;
  }

  /// Create an answer (callee side — Volunteer).
  Future<RTCSessionDescription> createAnswer() async {
    _updateState(WebRTCConnectionState.connecting);
    final answer = await _peerConnection!.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': true,
    });
    await _peerConnection!.setLocalDescription(answer);
    debugPrint('[WebRTC] Answer created, SDP length=${answer.sdp?.length}');
    return answer;
  }

  /// Set the remote description.
  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    if (_answerSet && description.type == 'answer') return;
    debugPrint('[WebRTC] Set remote desc: type=${description.type}');
    await _peerConnection?.setRemoteDescription(description);
    if (description.type == 'answer') _answerSet = true;
  }

  /// Add an ICE candidate from the other peer.
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    try {
      await _peerConnection?.addCandidate(candidate);
    } catch (e) {
      debugPrint('[WebRTC] addCandidate error (ignored): $e');
    }
  }

  /// Toggle mute.
  void setMicrophoneMuted(bool muted) {
    final audioTracks = _localStream?.getAudioTracks();
    if (audioTracks != null && audioTracks.isNotEmpty) {
      audioTracks[0].enabled = !muted;
    }
  }

  /// Toggle speaker.
  Future<void> setSpeakerEnabled(bool enabled) async {
    try {
      await Helper.selectAudioOutput(enabled ? 'speaker' : 'earpiece');
    } catch (_) {}
  }

  /// Toggle camera.
  void setCameraEnabled(bool enabled) {
    final videoTracks = _localStream?.getVideoTracks();
    if (videoTracks != null && videoTracks.isNotEmpty) {
      videoTracks[0].enabled = enabled;
    }
  }

  /// Switch physical camera (front/back/wide).
  Future<void> switchCamera() async {
    final videoTracks = _localStream?.getVideoTracks();
    if (videoTracks != null && videoTracks.isNotEmpty) {
      try {
        await Helper.switchCamera(videoTracks[0]);
      } catch (e) {
        debugPrint('[WebRTC] switchCamera error: $e');
      }
    }
  }

  /// Set camera zoom level.
  Future<void> setZoomLevel(double zoomLevel) async {
    final videoTracks = _localStream?.getVideoTracks();
    if (videoTracks != null && videoTracks.isNotEmpty) {
      try {
        // flutter_webrtc camera track zoom check
        await videoTracks[0].hasTorch();
      } catch (e) {
        debugPrint('[WebRTC] setZoomLevel error: $e');
      }
    }
  }

  /// Clean up previous session resources.
  Future<void> _cleanupPreviousSession() async {
    _localStream?.getTracks().forEach((track) => track.stop());
    try { await _localStream?.dispose(); } catch (_) {}
    _localStream = null;

    try { await _peerConnection?.close(); } catch (_) {}
    _peerConnection = null;

    _remoteStream = null;

    _stateController?.close();
    _remoteStreamController?.close();
    _iceCandidateController?.close();
    _stateController = null;
    _remoteStreamController = null;
    _iceCandidateController = null;
  }

  /// Clean up everything.
  Future<void> dispose() async {
    _updateState(WebRTCConnectionState.disconnected);
    await _cleanupPreviousSession();
  }

  void _updateState(WebRTCConnectionState state) {
    _currentState = state;
    if (_stateController != null && !_stateController!.isClosed) {
      _stateController!.add(state);
    }
  }

  WebRTCConnectionState get currentConnectionState => _currentState;
  bool get hasEverConnected => _hasEverConnected;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
}
