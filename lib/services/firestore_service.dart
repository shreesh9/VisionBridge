/// Realtime Database & Signaling Channel by Shreesh Nalawade | SN09092005
///
/// VisionBridge — Firestore Service
///
/// All Firestore operations. Bounded queries only (Section 3.1 of build spec).
/// Never use unbounded queries — always limit() + paginate.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';

/// Firestore collection paths — no magic strings.
abstract final class FirestorePaths {
  static const String users = 'users';
  static const String callRequests = 'call_requests';
  static const String callHistory = 'call_history';
  static const String emergencyContacts = 'emergency_contacts';
  static const String sosAlerts = 'sos_alerts';
  // WebRTC signaling rooms
  static const String signalingRooms = 'signaling_rooms';
}

/// User roles stored in Firestore.
enum UserRole { blindUser, volunteer }

/// Firestore user document.
class VBUser {
  const VBUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    this.photoUrl,
    this.isOnline = false,
    this.fcmToken,
    this.createdAt,
  });

  factory VBUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VBUser(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] == 'volunteer' ? UserRole.volunteer : UserRole.blindUser,
      photoUrl: data['photoUrl'] as String?,
      isOnline: data['isOnline'] as bool? ?? false,
      fcmToken: data['fcmToken'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  final String uid;
  final String displayName;
  final String email;
  final UserRole role;
  final String? photoUrl;
  final bool isOnline;
  final String? fcmToken;
  final DateTime? createdAt;

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'role': role == UserRole.volunteer ? 'volunteer' : 'blindUser',
      'photoUrl': photoUrl,
      'isOnline': isOnline,
      'fcmToken': fcmToken,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

/// Call request document.
class CallRequest {
  const CallRequest({
    required this.id,
    required this.blindUserId,
    this.volunteerId,
    required this.status,
    this.detectedObjects = const [],
    this.aiDescription,
    this.createdAt,
  });

  factory CallRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CallRequest(
      id: doc.id,
      blindUserId: data['blindUserId'] as String? ?? '',
      volunteerId: data['volunteerId'] as String?,
      status: data['status'] as String? ?? 'pending',
      detectedObjects: List<String>.from(data['detectedObjects'] as List? ?? []),
      aiDescription: data['aiDescription'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  final String id;
  final String blindUserId;
  final String? volunteerId;
  final String status; // 'pending', 'claimed', 'active', 'completed', 'cancelled'
  final List<String> detectedObjects;
  final String? aiDescription;
  final DateTime? createdAt;

  Map<String, dynamic> toFirestore() {
    return {
      'blindUserId': blindUserId,
      'volunteerId': volunteerId,
      'status': status,
      'detectedObjects': detectedObjects,
      'aiDescription': aiDescription,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // === Users ===

  /// Create or update user doc on registration.
  Future<void> createUser(VBUser user) async {
    await _db
        .collection(FirestorePaths.users)
        .doc(user.uid)
        .set(user.toFirestore(), SetOptions(merge: true));
  }

  /// Get user document.
  Future<VBUser?> getUser(String uid) async {
    final doc = await _db.collection(FirestorePaths.users).doc(uid).get();
    if (!doc.exists) return null;
    return VBUser.fromFirestore(doc);
  }

  /// Set volunteer online/offline status.
  Future<void> setOnlineStatus(String uid, bool isOnline) async {
    await _db.collection(FirestorePaths.users).doc(uid).update({
      'isOnline': isOnline,
    });
  }

  /// Update FCM token.
  Future<void> updateFcmToken(String uid, String token) async {
    await _db.collection(FirestorePaths.users).doc(uid).update({
      'fcmToken': token,
    });
  }

  // === Call Requests ===

  /// Create a call request (BU requesting help).
  Future<String> createCallRequest({
    required String blindUserId,
    List<String> detectedObjects = const [],
    String? aiDescription,
  }) async {
    final docRef = await _db.collection(FirestorePaths.callRequests).add({
      'blindUserId': blindUserId,
      'volunteerId': null,
      'status': 'pending',
      'detectedObjects': detectedObjects,
      'aiDescription': aiDescription,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Claim a call request (Volunteer accepting).
  /// Uses Firestore transaction for atomic claim (prevents double-accept).
  Future<bool> claimCallRequest({
    required String callRequestId,
    required String volunteerId,
  }) async {
    try {
      await _db.runTransaction((transaction) async {
        final docRef = _db
            .collection(FirestorePaths.callRequests)
            .doc(callRequestId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists || snapshot.data()?['status'] != 'pending') {
          throw Exception('Call already claimed or cancelled');
        }

        transaction.update(docRef, {
          'volunteerId': volunteerId,
          'status': 'claimed',
        });
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Listen for pending call requests (Volunteer listens for incoming calls).
  /// BOUNDED query per build spec Section 3.1. Sorted in Dart to prevent index requirements.
  Stream<List<CallRequest>> pendingCallRequests() {
    return _db
        .collection(FirestorePaths.callRequests)
        .where('status', isEqualTo: 'pending')
        .limit(AppConstants.firestoreDefaultQueryLimit)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map(CallRequest.fromFirestore).toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(2000);
        final bTime = b.createdAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  /// Update call request status.
  Future<void> updateCallStatus(
    String callRequestId,
    String status, {
    int? durationSeconds,
  }) async {
    final updateData = <String, dynamic>{'status': status};
    if (durationSeconds != null) {
      updateData['durationSeconds'] = durationSeconds;
    }
    await _db
        .collection(FirestorePaths.callRequests)
        .doc(callRequestId)
        .update(updateData);
  }

  // === Call History ===

  /// Get call history for a user (BU or Volunteer).
  /// BOUNDED query per build spec Section 3.1.
  Future<List<Map<String, dynamic>>> getCallHistory(
    String uid, {
    int limit = 20,
  }) async {
    // Check both blindUserId and volunteerId fields without requiring composite indexes
    final asBlindUser = await _db
        .collection(FirestorePaths.callRequests)
        .where('blindUserId', isEqualTo: uid)
        .limit(limit * 2)
        .get();

    final asVolunteer = await _db
        .collection(FirestorePaths.callRequests)
        .where('volunteerId', isEqualTo: uid)
        .limit(limit * 2)
        .get();

    final allDocs = [...asBlindUser.docs, ...asVolunteer.docs]
        .where((doc) => doc.data()['status'] == 'completed')
        .toList();

    allDocs.sort((a, b) {
      final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });

    return allDocs.take(limit).map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Get call history for a volunteer with caller names enriched.
  /// Queries by volunteerId only and filters status in memory to avoid
  /// needing a composite Firestore index.
  Future<List<Map<String, dynamic>>> getVolunteerCallHistory(
    String volunteerUid, {
    int limit = 100,
  }) async {
    try {
      final snap = await _db
          .collection(FirestorePaths.callRequests)
          .where('volunteerId', isEqualTo: volunteerUid)
          .get();

      // Filter for completed calls in memory (avoids composite index requirement)
      final completedDocs = snap.docs.where((doc) {
        final status = doc.data()['status'] as String?;
        return status == 'completed';
      }).toList();

      completedDocs.sort((a, b) {
        final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });

      final results = <Map<String, dynamic>>[];
      for (final doc in completedDocs.take(limit)) {
        final data = doc.data();
        final blindUserId = data['blindUserId'] as String?;
        String blindUserName = 'Visually Impaired User';
        String? blindUserPhotoUrl;
        if (blindUserId != null) {
          try {
            final uDoc = await getUser(blindUserId);
            if (uDoc?.displayName != null && uDoc!.displayName.trim().isNotEmpty) {
              blindUserName = uDoc.displayName.trim();
            }
            blindUserPhotoUrl = uDoc?.photoUrl;
          } catch (_) {}
        }
        results.add({
          'id': doc.id,
          ...data,
          'blindUserName': blindUserName,
          'blindUserPhotoUrl': blindUserPhotoUrl,
        });
      }
      return results;
    } catch (e) {
      debugPrint('[FirestoreService] getVolunteerCallHistory error: $e');
      return [];
    }
  }

  /// Get call history for a blind user with volunteer names enriched.
  /// Queries by blindUserId only and filters status in memory to avoid
  /// needing a composite Firestore index.
  Future<List<Map<String, dynamic>>> getBlindUserCallHistory(
    String blindUserUid, {
    int limit = 100,
  }) async {
    try {
      final snap = await _db
          .collection(FirestorePaths.callRequests)
          .where('blindUserId', isEqualTo: blindUserUid)
          .get();

      // Filter for completed calls in memory (avoids composite index requirement)
      final completedDocs = snap.docs.where((doc) {
        final status = doc.data()['status'] as String?;
        return status == 'completed';
      }).toList();

      completedDocs.sort((a, b) {
        final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });

      final results = <Map<String, dynamic>>[];
      for (final doc in completedDocs.take(limit)) {
        final data = doc.data();
        final volunteerId = data['volunteerId'] as String?;
        String volunteerName = 'Community Volunteer';
        String? volunteerPhotoUrl;
        if (volunteerId != null) {
          try {
            final uDoc = await getUser(volunteerId);
            if (uDoc?.displayName != null && uDoc!.displayName.trim().isNotEmpty) {
              volunteerName = uDoc.displayName.trim();
            }
            volunteerPhotoUrl = uDoc?.photoUrl;
          } catch (_) {}
        }
        results.add({
          'id': doc.id,
          ...data,
          'volunteerName': volunteerName,
          'volunteerPhotoUrl': volunteerPhotoUrl,
        });
      }
      return results;
    } catch (e) {
      debugPrint('[FirestoreService] getBlindUserCallHistory error: $e');
      return [];
    }
  }

  /// Update user profile (display name & photo URL).
  Future<void> updateUserProfile(String uid, {String? displayName, String? photoUrl}) async {
    final updateData = <String, dynamic>{};
    if (displayName != null) updateData['displayName'] = displayName;
    if (photoUrl != null) updateData['photoUrl'] = photoUrl;
    if (updateData.isNotEmpty) {
      await _db.collection(FirestorePaths.users).doc(uid).set(updateData, SetOptions(merge: true));
    }
  }

  // === SOS ===

  /// Create an SOS alert with location.
  Future<void> createSOSAlert({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    await _db.collection(FirestorePaths.sosAlerts).add({
      'userId': userId,
      'location': GeoPoint(latitude, longitude),
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // === WebRTC Signaling ===

  /// Create a signaling room and return its ID (uses callRequestId directly as doc ID).
  Future<String> createSignalingRoom(String callRequestId) async {
    await _db.collection(FirestorePaths.signalingRooms).doc(callRequestId).set({
      'callRequestId': callRequestId,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return callRequestId;
  }

  /// Write SDP offer/answer to signaling room.
  Future<void> writeSDP(String roomId, String type, String sdp) async {
    await _db.collection(FirestorePaths.signalingRooms).doc(roomId).set({
      type: {'sdp': sdp, 'type': type}, // type = 'offer' or 'answer'
    }, SetOptions(merge: true));
  }

  /// Listen for SDP changes in a signaling room.
  Stream<DocumentSnapshot> listenSignalingRoom(String roomId) {
    return _db
        .collection(FirestorePaths.signalingRooms)
        .doc(roomId)
        .snapshots();
  }

  /// Add ICE candidate to signaling room subcollection.
  Future<void> addIceCandidate(
    String roomId,
    String peerId,
    Map<String, dynamic> candidate,
  ) async {
    await _db
        .collection(FirestorePaths.signalingRooms)
        .doc(roomId)
        .collection('candidates_$peerId')
        .add(candidate);
  }

  /// Get existing ICE candidates generated prior to listener setup.
  Future<List<Map<String, dynamic>>> getExistingIceCandidates(
    String roomId,
    String peerId,
  ) async {
    final snapshot = await _db
        .collection(FirestorePaths.signalingRooms)
        .doc(roomId)
        .collection('candidates_$peerId')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Listen for ICE candidates from the other peer.
  Stream<QuerySnapshot> listenIceCandidates(String roomId, String peerId) {
    return _db
        .collection(FirestorePaths.signalingRooms)
        .doc(roomId)
        .collection('candidates_$peerId')
        .snapshots();
  }
}

/// Riverpod provider for FirestoreService.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});
