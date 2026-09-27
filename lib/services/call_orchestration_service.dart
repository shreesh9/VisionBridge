/// Designed & Implemented by Shreesh Nalawade
/// Signaling Orchestration Pipeline | Ref: SN09092005
///
/// VisionBridge — Call Orchestration Service
///
/// Ties together Firestore signaling + WebRTC for the full call flow:
///   BU creates call_request → Volunteer claims (transaction) →
///   Signaling room created → SDP/ICE exchanged → Connected
///
/// This is the glue layer between firestore_service and webrtc_service.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../core/constants.dart';
import 'firestore_service.dart';
import 'webrtc_service.dart';

/// Roles in a call.
enum CallRole { blindUser, volunteer }

class CallOrchestrationService {

  CallOrchestrationService({
    required this.firestoreService,
    required this.webrtcService,
  });
  static final CallOrchestrationService instance = CallOrchestrationService(
    firestoreService: FirestoreService(),
    webrtcService: WebRTCService(),
  );

  final FirestoreService firestoreService;
  final WebRTCService webrtcService;

  String? _currentCallRequestId;
  String? _currentSignalingRoomId;
  StreamSubscription? _signalingSubscription;
  StreamSubscription? _iceCandidateSubscription;
  StreamSubscription? _outgoingIceSub;
  StreamSubscription? _callStatusSubscription;
  Timer? _timeoutTimer;
  bool _isEnding = false;

  // === Blind User Flow ===

  Future<String> requestVolunteerHelp({
    required String blindUserId,
    List<String> detectedObjects = const [],
    String? aiDescription,
  }) async {
    // Clean up any previous call state
    await _cleanupSubscriptions();
    _isEnding = false;

    // 1. Initialize WebRTC (fresh PeerConnection + StreamControllers)
    await webrtcService.initialize();

    // 2. Subscribe to outgoing ICE candidates BEFORE creating offer
    //    (candidates start generating the moment setLocalDescription is called)
    await webrtcService.startLocalMedia(
      videoEnabled: true,
      audioEnabled: true,
    );

    // 3. Create Firestore call request
    _currentCallRequestId = await firestoreService.createCallRequest(
      blindUserId: blindUserId,
      detectedObjects: detectedObjects,
      aiDescription: aiDescription,
    );

    // 4. Create signaling room (uses callRequestId as doc ID)
    _currentSignalingRoomId = await firestoreService.createSignalingRoom(
      _currentCallRequestId!,
    );

    // 5. Subscribe ICE candidate relay BEFORE creating offer
    _outgoingIceSub = webrtcService.onIceCandidate.listen((candidate) {
      if (_currentSignalingRoomId != null) {
        firestoreService.addIceCandidate(
          _currentSignalingRoomId!,
          'bu',
          {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        );
      }
    });

    // 6. Create SDP offer (ICE gathering starts here)
    final offer = await webrtcService.createOffer();
    await firestoreService.writeSDP(
      _currentSignalingRoomId!,
      'offer',
      offer.sdp!,
    );

    // 7. Listen for volunteer's answer
    bool answerApplied = false;
    _signalingSubscription = firestoreService
        .listenSignalingRoom(_currentSignalingRoomId!)
        .listen((snapshot) async {
      if (answerApplied) return;
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('answer')) {
        answerApplied = true;
        _timeoutTimer?.cancel();
        _timeoutTimer = null;
        final answer = data['answer'] as Map<String, dynamic>;
        await webrtcService.setRemoteDescription(
          RTCSessionDescription(answer['sdp'] as String, 'answer'),
        );
      }
    });

    // 8. Fetch existing + listen for new volunteer ICE candidates
    _fetchAndListenIceCandidates('volunteer');

    // 9. Listen for call status changes (so BU knows if vol hangs up)
    _listenCallStatus();

    // 10. Set timeout — cancel if no volunteer picks up
    _timeoutTimer = Timer(
      const Duration(seconds: AppConstants.volunteerCallTimeoutSec),
      () => cancelCall(),
    );

    return _currentCallRequestId!;
  }

  // === Volunteer Flow ===

  Future<bool> acceptCall({
    required String callRequestId,
    required String volunteerId,
    required String signalingRoomId,
  }) async {
    // Clean up any previous call state
    await _cleanupSubscriptions();
    _isEnding = false;

    // 1. Claim atomically
    final claimed = await firestoreService.claimCallRequest(
      callRequestId: callRequestId,
      volunteerId: volunteerId,
    );
    if (!claimed) return false;

    _currentCallRequestId = callRequestId;
    _currentSignalingRoomId = signalingRoomId;

    // 2. Initialize WebRTC (fresh PeerConnection + StreamControllers)
    await webrtcService.initialize();
    await webrtcService.startVolunteerMedia();

    // 3. Subscribe ICE candidate relay BEFORE creating answer
    _outgoingIceSub = webrtcService.onIceCandidate.listen((candidate) {
      if (_currentSignalingRoomId != null) {
        firestoreService.addIceCandidate(
          signalingRoomId,
          'volunteer',
          {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        );
      }
    });

    // 4. Get BU's offer (retry for up to 5s)
    Map<String, dynamic>? roomData;
    for (int i = 0; i < 15; i++) {
      final snap = await FirebaseFirestore.instance
          .collection(FirestorePaths.signalingRooms)
          .doc(signalingRoomId)
          .get();
      roomData = snap.data();
      if (roomData != null && roomData.containsKey('offer')) break;
      await Future.delayed(const Duration(milliseconds: 350));
    }

    if (roomData == null || !roomData.containsKey('offer')) {
      throw Exception('Call offer not ready from caller. Please try again.');
    }

    final offer = roomData['offer'] as Map<String, dynamic>;
    await webrtcService.setRemoteDescription(
      RTCSessionDescription(offer['sdp'] as String, 'offer'),
    );

    // 5. Create and send answer (ICE gathering starts here)
    final answer = await webrtcService.createAnswer();
    await firestoreService.writeSDP(
      signalingRoomId,
      'answer',
      answer.sdp!,
    );

    // 6. Fetch existing + listen for new BU ICE candidates
    _fetchAndListenIceCandidates('bu');

    // 7. Listen for call status changes (so vol knows if BU hangs up)
    _listenCallStatus();

    // 8. Mark call as active
    await firestoreService.updateCallStatus(callRequestId, 'active');

    return true;
  }

  /// Listen to Firestore call_request status changes.
  /// If the other side marks the call as 'completed' or 'cancelled',
  /// this triggers a local disconnect.
  void _listenCallStatus() {
    if (_currentCallRequestId == null) return;
    _callStatusSubscription = FirebaseFirestore.instance
        .collection(FirestorePaths.callRequests)
        .doc(_currentCallRequestId!)
        .snapshots()
        .listen((snapshot) {
      final data = snapshot.data();
      if (data == null) return;
      final status = data['status'] as String?;
      if ((status == 'completed' || status == 'cancelled') && !_isEnding) {
        // The other side ended the call — trigger local disconnect
        webrtcService.dispose();
      }
    });
  }

  /// Fetch existing ICE candidates from Firestore and listen for new ones.
  void _fetchAndListenIceCandidates(String peerId) {
    if (_currentSignalingRoomId == null) return;
    final roomId = _currentSignalingRoomId!;

    // Fetch candidates already written before we started listening
    firestoreService
        .getExistingIceCandidates(roomId, peerId)
        .then((candidates) {
      for (final data in candidates) {
        if (data.containsKey('candidate')) {
          webrtcService.addIceCandidate(RTCIceCandidate(
            data['candidate'] as String,
            data['sdpMid'] as String?,
            data['sdpMLineIndex'] as int?,
          ));
        }
      }
    });

    // Listen for new candidates
    _iceCandidateSubscription = firestoreService
        .listenIceCandidates(roomId, peerId)
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          webrtcService.addIceCandidate(RTCIceCandidate(
            data['candidate'] as String,
            data['sdpMid'] as String?,
            data['sdpMLineIndex'] as int?,
          ));
        }
      }
    });
  }

  String? get currentCallRequestId => _currentCallRequestId;
  String? get currentSignalingRoomId => _currentSignalingRoomId;

  /// Clean up all subscriptions and timers.
  Future<void> _cleanupSubscriptions() async {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    await _signalingSubscription?.cancel();
    _signalingSubscription = null;
    await _iceCandidateSubscription?.cancel();
    _iceCandidateSubscription = null;
    await _outgoingIceSub?.cancel();
    _outgoingIceSub = null;
    await _callStatusSubscription?.cancel();
    _callStatusSubscription = null;
  }

  /// End the current call cleanly.
  Future<void> endCall({int durationSeconds = 0}) async {
    if (_isEnding) return;
    _isEnding = true;

    await _cleanupSubscriptions();

    if (_currentCallRequestId != null) {
      try {
        await firestoreService.updateCallStatus(
          _currentCallRequestId!,
          'completed',
          durationSeconds: durationSeconds,
        );
      } catch (_) {}
    }

    await webrtcService.dispose();
    _currentCallRequestId = null;
    _currentSignalingRoomId = null;
    _isEnding = false;
  }

  /// Cancel the call request.
  Future<void> cancelCall() async {
    if (_isEnding) return;
    _isEnding = true;

    await _cleanupSubscriptions();

    if (_currentCallRequestId != null) {
      try {
        await firestoreService.updateCallStatus(
          _currentCallRequestId!,
          'cancelled',
        );
      } catch (_) {}
    }

    await webrtcService.dispose();
    _currentCallRequestId = null;
    _currentSignalingRoomId = null;
    _isEnding = false;
  }

  void dispose() {
    _timeoutTimer?.cancel();
    _signalingSubscription?.cancel();
    _iceCandidateSubscription?.cancel();
    _outgoingIceSub?.cancel();
    _callStatusSubscription?.cancel();
  }
}
