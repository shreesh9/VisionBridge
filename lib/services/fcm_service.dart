/// VisionBridge — FCM Service
///
/// Handles Firebase Cloud Messaging for background incoming call notifications.
/// Uses flutter_callkit_incoming for native Android full-screen ringing UI.
///
/// Designed & Implemented by Shreesh Nalawade | SN09092005
library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';

import 'firestore_service.dart';

/// Top-level background message handler.
/// MUST be a top-level function (not a class method) for Flutter isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM BG] Background message received: ${message.data}');

  final data = message.data;
  final type = data['type'];

  if (type == 'INCOMING_CALL') {
    await _showIncomingCallUI(data);
  } else if (type == 'CANCEL_CALL') {
    await _dismissIncomingCallUI(data);
  }
}

/// Show native full-screen incoming call UI via flutter_callkit_incoming.
Future<void> _showIncomingCallUI(Map<String, dynamic> data) async {
  final callRequestId = data['callRequestId'] ?? '';
  final callerName = data['callerName'] ?? 'Visually Impaired User';

  // Use callRequestId as the unique call UUID for dismiss tracking
  final callUuid = callRequestId.isNotEmpty
      ? callRequestId
      : const Uuid().v4();

  final params = CallKitParams(
    id: callUuid,
    nameCaller: callerName,
    appName: 'VisionBridge',
    type: 0, // 0 = incoming call
    textAccept: 'Accept',
    textDecline: 'Decline',
    duration: 30000, // 30 second ring timeout
    extra: <String, dynamic>{
      'callRequestId': callRequestId,
      'signalingRoomId': data['signalingRoomId'] ?? callRequestId,
    },
    android: const AndroidParams(
      isCustomNotification: false,
      isShowLogo: false,
      ringtonePath: 'system_ringtone_default',
      backgroundColor: '#1A1A2E',
      actionColor: '#6C63FF',
      textColor: '#FFFFFF',
      isShowFullLockedScreen: true,
      isShowCallID: false,
    ),
    ios: const IOSParams(
      // iOS params for future use — currently Android-only
      handleType: 'generic',
      supportsVideo: true,
      maximumCallGroups: 1,
      maximumCallsPerCallGroup: 1,
      ringtonePath: 'system_ringtone_default',
    ),
    callingNotification: const NotificationParams(
      showNotification: true,
      subtitle: 'Needs visual assistance',
      callbackText: 'Call back',
    ),
  );

  await FlutterCallkitIncoming.showCallkitIncoming(params);
  debugPrint('[FCM] Showed incoming call UI for $callRequestId from $callerName');
}

/// Dismiss an active incoming call UI (when BU cancels or another volunteer accepts).
Future<void> _dismissIncomingCallUI(Map<String, dynamic> data) async {
  final callRequestId = data['callRequestId'] ?? '';
  if (callRequestId.isNotEmpty) {
    await FlutterCallkitIncoming.endCall(callRequestId);
    debugPrint('[FCM] Dismissed incoming call UI for $callRequestId (reason: ${data['reason']})');
  } else {
    await FlutterCallkitIncoming.endAllCalls();
    debugPrint('[FCM] Dismissed all incoming call UIs');
  }
}

/// FCM Service singleton — manages token registration and foreground message handling.
class FCMService {
  FCMService._();
  static final FCMService instance = FCMService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription? _tokenRefreshSub;
  bool _isInitialized = false;

  /// Callback invoked when user accepts a call from the native ringing UI.
  /// The app's main widget / router should set this to navigate to the incoming call screen.
  void Function(String callRequestId, String signalingRoomId)? onCallAccepted;

  /// Callback invoked when user declines a call from the native ringing UI.
  void Function(String callRequestId)? onCallDeclined;

  /// Initialize FCM: request permissions, register token, set up listeners.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Request notification permission (Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );
    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

    // 2. Get current FCM token and store it
    await _refreshAndStoreToken();

    // 3. Listen for token refreshes
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('[FCM] Token refreshed');
      await _storeToken(newToken);
    });

    // 4. Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Handle when user taps notification to open app
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 6. Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // 7. Listen for CallKit events (accept / decline / timeout)
    _setupCallKitListeners();

    debugPrint('[FCM] Service initialized');
  }

  /// Refresh FCM token and store it in Firestore.
  Future<void> _refreshAndStoreToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _storeToken(token);
      }
    } catch (e) {
      debugPrint('[FCM] Failed to get token: $e');
    }
  }

  /// Store FCM token in the user's Firestore document.
  Future<void> _storeToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestoreService.updateFcmToken(uid, token);
      debugPrint('[FCM] Token stored for user $uid');
    } catch (e) {
      debugPrint('[FCM] Failed to store token: $e');
    }
  }

  /// Handle foreground FCM messages.
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM FG] Foreground message: ${message.data}');

    final data = message.data;
    final type = data['type'];

    if (type == 'INCOMING_CALL') {
      // In foreground, the existing Firestore listener in v_home_screen.dart
      // will handle showing the incoming call screen. But we also show the
      // native call UI as a backup (e.g. if user is in a different screen).
      _showIncomingCallUI(data);
    } else if (type == 'CANCEL_CALL') {
      _dismissIncomingCallUI(data);
    }
  }

  /// Handle when app is opened from a notification tap.
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] App opened from notification: ${message.data}');

    final data = message.data;
    if (data['type'] == 'INCOMING_CALL') {
      final callRequestId = data['callRequestId'] ?? '';
      final signalingRoomId = data['signalingRoomId'] ?? callRequestId;
      if (callRequestId.isNotEmpty) {
        onCallAccepted?.call(callRequestId, signalingRoomId);
      }
    }
  }

  /// Set up listeners for CallKit accept/decline events.
  void _setupCallKitListeners() {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;

      debugPrint('[CallKit] Event: ${event.event}, body: ${event.body}');

      switch (event.event) {
        case Event.actionCallAccept:
          _onCallAccepted(event.body);
          break;
        case Event.actionCallDecline:
          _onCallDeclined(event.body);
          break;
        case Event.actionCallTimeout:
          _onCallTimeout(event.body);
          break;
        case Event.actionCallEnded:
          // Call ended normally
          break;
        default:
          break;
      }
    });
  }

  /// User accepted the call from native UI.
  void _onCallAccepted(dynamic rawBody) {
    if (rawBody == null) return;
    final body = rawBody is Map ? Map<String, dynamic>.from(rawBody) : <String, dynamic>{};

    final extraRaw = body['extra'];
    final extra = extraRaw is Map ? Map<String, dynamic>.from(extraRaw) : <String, dynamic>{};
    final callRequestId = extra['callRequestId']?.toString() ?? body['id']?.toString() ?? '';
    final signalingRoomId = extra['signalingRoomId']?.toString() ?? callRequestId;

    debugPrint('[CallKit] Call ACCEPTED: callRequestId=$callRequestId');

    if (callRequestId.isNotEmpty) {
      onCallAccepted?.call(callRequestId, signalingRoomId);
    }
  }

  /// User declined the call from native UI.
  void _onCallDeclined(dynamic rawBody) {
    if (rawBody == null) return;
    final body = rawBody is Map ? Map<String, dynamic>.from(rawBody) : <String, dynamic>{};

    final extraRaw = body['extra'];
    final extra = extraRaw is Map ? Map<String, dynamic>.from(extraRaw) : <String, dynamic>{};
    final callRequestId = extra['callRequestId']?.toString() ?? body['id']?.toString() ?? '';

    debugPrint('[CallKit] Call DECLINED: callRequestId=$callRequestId');

    if (callRequestId.isNotEmpty) {
      onCallDeclined?.call(callRequestId);
    }
  }

  /// Call timed out (30 seconds).
  void _onCallTimeout(dynamic rawBody) {
    if (rawBody == null) return;
    debugPrint('[CallKit] Call TIMED OUT');
    // No action needed — the native UI auto-dismisses
  }

  /// Clear FCM token from Firestore (call on logout).
  Future<void> clearToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await _firestoreService.updateFcmToken(uid, '');
      } catch (_) {}
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
  }
}
