/**
 * VisionBridge — Firebase Cloud Functions
 * 
 * Handles sending FCM push notifications for incoming call requests
 * so that volunteer devices wake up even when the app is killed/backgrounded.
 * 
 * Designed & Implemented by Shreesh Nalawade | SN09092005
 */

const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

/**
 * Triggered when a new call_request document is created.
 * Queries all online volunteers and sends them a high-priority
 * data-only FCM message to trigger flutter_callkit_incoming.
 */
exports.onCallRequestCreated = onDocumentCreated(
  "call_requests/{callId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const callData = snap.data();
    const callId = event.params.callId;

    // Only process 'pending' requests
    if (callData.status !== "pending") return;

    // Get caller display name for the ringing UI
    let callerName = "Visually Impaired User";
    try {
      const callerDoc = await db.collection("users").doc(callData.blindUserId).get();
      if (callerDoc.exists) {
        const callerData = callerDoc.data();
        if (callerData.displayName && callerData.displayName.trim()) {
          callerName = callerData.displayName.trim();
        }
      }
    } catch (err) {
      console.error("Failed to fetch caller name:", err);
    }

    // Query online volunteers who have FCM tokens
    const volunteersSnap = await db
      .collection("users")
      .where("role", "==", "volunteer")
      .where("isOnline", "==", true)
      .get();

    if (volunteersSnap.empty) {
      console.log(`No online volunteers found for call ${callId}`);
      return;
    }

    const tokens = [];
    const volunteerUids = [];

    volunteersSnap.forEach((doc) => {
      const data = doc.data();
      if (data.fcmToken && data.fcmToken.trim()) {
        tokens.push(data.fcmToken.trim());
        volunteerUids.push(doc.id);
      }
    });

    if (tokens.length === 0) {
      console.log(`Online volunteers found but none have FCM tokens for call ${callId}`);
      return;
    }

    console.log(`Sending INCOMING_CALL to ${tokens.length} volunteer(s) for call ${callId}`);

    // Build data-only message (NO notification key — ensures background handler runs)
    const message = {
      tokens: tokens,
      data: {
        type: "INCOMING_CALL",
        callRequestId: callId,
        signalingRoomId: callId, // signaling room uses same ID as callRequest
        callerName: callerName,
        timestamp: Date.now().toString(),
      },
      android: {
        priority: "high",
        ttl: 60000, // 60 seconds — matches volunteer call timeout
      },
    };

    try {
      const response = await messaging.sendEachForMulticast(message);
      console.log(
        `FCM result for call ${callId}: ${response.successCount} success, ${response.failureCount} failure`
      );

      // Clean up invalid tokens
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const errorCode = resp.error?.code;
          if (
            errorCode === "messaging/invalid-registration-token" ||
            errorCode === "messaging/registration-token-not-registered"
          ) {
            console.log(`Removing stale FCM token for volunteer ${volunteerUids[idx]}`);
            db.collection("users").doc(volunteerUids[idx]).update({ fcmToken: null });
          }
        }
      });
    } catch (err) {
      console.error(`FCM send failed for call ${callId}:`, err);
    }
  }
);

/**
 * Triggered when a call_request document is updated.
 * If status changes to 'cancelled', 'completed', or 'claimed',
 * sends a CANCEL_CALL message to dismiss ringing on volunteer phones.
 */
exports.onCallRequestUpdated = onDocumentUpdated(
  "call_requests/{callId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!before || !after) return;

    const callId = event.params.callId;

    // Only act on status transitions that should dismiss ringing
    const dismissStatuses = ["cancelled", "completed", "claimed", "active"];
    if (before.status === "pending" && dismissStatuses.includes(after.status)) {
      console.log(`Call ${callId} status changed to '${after.status}' — sending CANCEL_CALL`);

      // Get all online volunteers to dismiss their ringing
      const volunteersSnap = await db
        .collection("users")
        .where("role", "==", "volunteer")
        .where("isOnline", "==", true)
        .get();

      const tokens = [];
      volunteersSnap.forEach((doc) => {
        const data = doc.data();
        // Don't send cancel to the volunteer who accepted (they're transitioning to call)
        if (after.volunteerId && doc.id === after.volunteerId) return;
        if (data.fcmToken && data.fcmToken.trim()) {
          tokens.push(data.fcmToken.trim());
        }
      });

      if (tokens.length === 0) return;

      const message = {
        tokens: tokens,
        data: {
          type: "CANCEL_CALL",
          callRequestId: callId,
          reason: after.status, // 'cancelled', 'claimed', 'completed', 'active'
        },
        android: {
          priority: "high",
          ttl: 30000,
        },
      };

      try {
        const response = await messaging.sendEachForMulticast(message);
        console.log(
          `CANCEL_CALL for ${callId}: ${response.successCount} success, ${response.failureCount} failure`
        );
      } catch (err) {
        console.error(`CANCEL_CALL FCM failed for ${callId}:`, err);
      }
    }
  }
);
