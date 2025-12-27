const functions = require("firebase-functions");
const admin = require("firebase-admin");

/**
 * Helper function to remove a user from receivedLikes
 * @param {string} userId - The user whose receivedLikes to update
 * @param {string} fromUserId - The user to remove from receivedLikes
 */
async function removeFromReceivedLikes(userId, fromUserId) {
  try {
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const data = userDoc.data();
    if (!data) return;

    const receivedLikes = data.receivedLikes || [];
    const filteredLikes = receivedLikes.filter((like) => like.fromUserId !== fromUserId);

    await admin.firestore().collection("users").doc(userId).update({
      receivedLikes: filteredLikes,
    });
  } catch (error) {
    console.error("Error removing from receivedLikes:", error);
  }
}

/**
 * Send match notifications to both users
 * @param {string} user1Id - First user in the match
 * @param {string} user2Id - Second user in the match
 */
async function sendMatchNotifications(user1Id, user2Id) {
  try {
    const [user1Doc, user2Doc] = await Promise.all([
      admin.firestore().collection("users").doc(user1Id).get(),
      admin.firestore().collection("users").doc(user2Id).get(),
    ]);

    const user1Data = user1Doc.data();
    const user2Data = user2Doc.data();

    if (user1Data && user1Data.fcmToken) {
      const user2Name = (user2Data && user2Data.firstName) || "Someone";
      await admin.messaging().send({
        token: user1Data.fcmToken,
        notification: {
          title: "It's a Match! 💙",
          body: `You and ${user2Name} like each other! Start chatting now.`,
        },
        data: {type: "match", matchedUserId: user2Id, click_action: "FLUTTER_NOTIFICATION_CLICK"},
        android: {notification: {channelId: "matches", priority: "high"}},
        apns: {payload: {aps: {badge: 1, sound: "default"}}},
      });
      console.log("Match notification sent to:", user1Id);
    }

    if (user2Data && user2Data.fcmToken) {
      const user1Name = (user1Data && user1Data.firstName) || "Someone";
      await admin.messaging().send({
        token: user2Data.fcmToken,
        notification: {
          title: "It's a Match! 💙",
          body: `You and ${user1Name} like each other! Start chatting now.`,
        },
        data: {type: "match", matchedUserId: user1Id, click_action: "FLUTTER_NOTIFICATION_CLICK"},
        android: {notification: {channelId: "matches", priority: "high"}},
        apns: {payload: {aps: {badge: 1, sound: "default"}}},
      });
      console.log("Match notification sent to:", user2Id);
    }
  } catch (error) {
    console.error("Error sending match notifications:", error);
  }
}

/**
 * Handle new interactions (likes/passes)
 */
exports.onInteractionCreated = functions.firestore
    .document("users/{fromUserId}/interactions/{toUserId}")
    .onCreate(async (snapshot, context) => {
      const interactionData = snapshot.data();
      const fromUserId = context.params.fromUserId;
      const toUserId = context.params.toUserId;

      if (interactionData.action !== "like") {
        console.log("Interaction is a pass, skipping");
        return null;
      }

      try {
      // Add to target user's receivedLikes
      // Note: serverTimestamp() not allowed inside arrays, use Timestamp.now()
        await admin.firestore().collection("users").doc(toUserId).update({
          receivedLikes: admin.firestore.FieldValue.arrayUnion({
            fromUserId: fromUserId,
            timestamp: admin.firestore.Timestamp.now(),
          }),
        });
        console.log("Added to receivedLikes for:", toUserId);

        // Check for mutual like (match detection)
        const reverseInteraction = await admin.firestore()
            .collection("users").doc(toUserId).collection("interactions").doc(fromUserId).get();

        if (reverseInteraction.exists && reverseInteraction.data().action === "like") {
          const matchId = fromUserId < toUserId ?
          `${fromUserId}_${toUserId}` : `${toUserId}_${fromUserId}`;

          await admin.firestore().collection("matches").doc(matchId).set({
            users: [fromUserId, toUserId],
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
            lastMessage: null,
          });
          console.log("Match created:", matchId);

          await removeFromReceivedLikes(fromUserId, toUserId);
          await removeFromReceivedLikes(toUserId, fromUserId);
          await sendMatchNotifications(fromUserId, toUserId);
          return null;
        }

        // Send push notification for the like
        const targetUser = await admin.firestore().collection("users").doc(toUserId).get();
        const targetData = targetUser.data();
        if (!targetData || !targetData.fcmToken) {
          console.log("No FCM token for user:", toUserId);
          return null;
        }

        // Get liker's blurred photo
        let blurredPhotoUrl = null;
        try {
          const likerDoc = await admin.firestore().collection("users").doc(fromUserId).get();
          const likerData = likerDoc.data();
          if (likerData && likerData.mediaUrls && likerData.mediaUrls.length > 0) {
            const firstPhotoUrl = likerData.mediaUrls[0];
            if (likerData.blurredMediaUrls && likerData.blurredMediaUrls[firstPhotoUrl]) {
              blurredPhotoUrl = likerData.blurredMediaUrls[firstPhotoUrl];
            }
          }
        } catch (e) {
          console.log("Could not get blurred photo:", e);
        }

        await admin.messaging().send({
          token: targetData.fcmToken,
          notification: {
            title: "Someone likes you! 💙",
            body: "Someone just liked your profile. Open DateBlue to find out who!",
            imageUrl: blurredPhotoUrl,
          },
          data: {type: "like_received", fromUserId: fromUserId, click_action: "FLUTTER_NOTIFICATION_CLICK"},
          android: {notification: {channelId: "likes", priority: "high", imageUrl: blurredPhotoUrl}},
          apns: {
            payload: {aps: {badge: 1, sound: "default"}},
            fcmOptions: blurredPhotoUrl ? {imageUrl: blurredPhotoUrl} : {},
          },
        });
        console.log("Like notification sent to:", toUserId);
        return null;
      } catch (error) {
        console.error("Error processing interaction:", error);
        return null;
      }
    });
