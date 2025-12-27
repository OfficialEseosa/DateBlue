const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Generate a cryptographically secure 4-digit verification code
 * @return {string} 4-digit code
 */
function generateSecureCode() {
  const crypto = require("crypto");
  const randomValue = crypto.randomInt(1000, 10000);
  return randomValue.toString();
}

/**
 * Send verification email with code
 * Callable function that generates a secure code and sends it via email
 */
exports.sendVerificationEmail = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated to send verification email.",
    );
  }

  const {campusId} = data;
  const uid = context.auth.uid;
  const userEmail = context.auth.token.email;
  const displayName = context.auth.token.name;

  // Validate campus ID
  if (!campusId || typeof campusId !== "string") {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Campus ID is required.",
    );
  }

  if (campusId.length < 1 || campusId.length > 20) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Campus ID must be between 1 and 20 characters.",
    );
  }

  // Validate campus ID format: only allow alphanumeric, underscore, and hyphen
  if (!/^[a-zA-Z0-9_-]+$/.test(campusId)) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Campus ID must be alphanumeric and may only contain underscores or hyphens.",
    );
  }

  const gsuEmail = `${campusId}@student.gsu.edu`;

  try {
    // Check if GSU email is already taken by another verified user
    const existingUsers = await admin.firestore()
        .collection("users")
        .where("gsuEmail", "==", gsuEmail)
        .where("isVerified", "==", true)
        .get();

    const isTaken = existingUsers.docs.some((doc) => doc.id !== uid);

    // Generate secure verification code
    const verificationCode = generateSecureCode();

    // Save user data and verification code
    await admin.firestore().collection("users").doc(uid).set({
      googleEmail: userEmail,
      displayName: displayName,
      gsuEmail: gsuEmail,
      verificationCode: verificationCode,
      codeCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
      isVerified: false,
      failedVerificationAttempts: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    // Only send email if not taken (privacy - don't reveal if email exists)
    if (!isTaken) {
      await admin.firestore().collection("mail").add({
        to: gsuEmail,
        message: {
          subject: "DateBlue Verification Code",
          html: buildEmailHtml(verificationCode, false),
        },
      });
    }

    return {
      success: true,
      message: "If this is a valid GSU email and not in use, " +
               "you will receive a code shortly.",
    };
  } catch (error) {
    // If it's already an HttpsError, re-throw it
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    console.error("Error sending verification email:", error);
    throw new functions.https.HttpsError(
        "internal",
        "Failed to send verification email.",
    );
  }
});

/**
 * Resend verification code
 * Callable function to resend a new verification code
 */
exports.resendVerificationCode = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated.",
    );
  }

  const uid = context.auth.uid;

  const RESEND_COOLDOWN_SECONDS = 60;

  try {
    // Get user document to retrieve GSU email
    const userDoc = await admin.firestore().collection("users").doc(uid).get();
    
    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
          "not-found",
          "User not found.",
      );
    }

    const userData = userDoc.data();
    const gsuEmail = userData.gsuEmail;
    const lastResendAt = userData.lastResendAt;

    if (!gsuEmail) {
      throw new functions.https.HttpsError(
          "failed-precondition",
          "No GSU email on record.",
      );
    }

    // Check rate limiting
    if (lastResendAt) {
      const timeSinceLastResend = (Date.now() - lastResendAt.toMillis()) / 1000;
      if (timeSinceLastResend < RESEND_COOLDOWN_SECONDS) {
        const remainingSeconds = Math.ceil(RESEND_COOLDOWN_SECONDS - timeSinceLastResend);
        throw new functions.https.HttpsError(
            "resource-exhausted",
            `Please wait ${remainingSeconds} seconds before requesting another code.`,
        );
      }
    }

    // Generate new secure code
    const verificationCode = generateSecureCode();

    // Update verification code and reset failed attempts
    await admin.firestore().collection("users").doc(uid).update({
      verificationCode: verificationCode,
      codeCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastResendAt: admin.firestore.FieldValue.serverTimestamp(),
      failedVerificationAttempts: 0,
      lastFailedAttempt: admin.firestore.FieldValue.delete(),
    });

    // Send new verification email
    await admin.firestore().collection("mail").add({
      to: gsuEmail,
      message: {
        subject: "DateBlue Verification Code",
        html: buildEmailHtml(verificationCode, true),
      },
    });

    return {
      success: true,
      message: "New verification code sent!",
    };
  } catch (error) {
    // If it's already an HttpsError, re-throw it
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    console.error("Error resending verification code:", error);
    throw new functions.https.HttpsError(
        "internal",
        "Failed to resend verification code.",
    );
  }
});

/**
 * Verify PIN code with rate limiting
 * Callable function to verify the PIN code entered by user
 */
exports.verifyPin = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated.",
    );
  }

  const {pin} = data;
  const uid = context.auth.uid;

  if (!pin || typeof pin !== "string" || pin.length !== 4) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "PIN must be a 4-digit string.",
    );
  }

  const MAX_ATTEMPTS = 3;
  const LOCKOUT_MINUTES = 15;
  const CODE_EXPIRATION_MINUTES = 5;

  try {
    const userDoc = await admin.firestore().collection("users").doc(uid).get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
          "not-found",
          "User not found.",
      );
    }

    const userData = userDoc.data();
    const storedCode = userData.verificationCode;
    const codeCreatedAt = userData.codeCreatedAt;
    const failedAttempts = userData.failedVerificationAttempts || 0;
    const lastFailedAttempt = userData.lastFailedAttempt;

    // Check if user is locked out
    if (lastFailedAttempt && failedAttempts >= MAX_ATTEMPTS) {
      const lockoutAge = Date.now() - lastFailedAttempt.toMillis();
      const lockoutAgeMinutes = Math.floor(lockoutAge / 60000);

      if (lockoutAgeMinutes < LOCKOUT_MINUTES) {
        const remainingMinutes = LOCKOUT_MINUTES - lockoutAgeMinutes;
        throw new functions.https.HttpsError(
            "permission-denied",
            `Too many failed attempts. Try again in ${remainingMinutes} minutes.`,
        );
      } else {
        // Reset lockout
        await admin.firestore().collection("users").doc(uid).update({
          failedVerificationAttempts: 0,
          lastFailedAttempt: admin.firestore.FieldValue.delete(),
        });
      }
    }

    // Check if code exists
    if (!storedCode) {
      throw new functions.https.HttpsError(
          "failed-precondition",
          "Invalid or expired verification code.",
      );
    }

    // Check if code has expired
    if (codeCreatedAt) {
      const codeAge = Date.now() - codeCreatedAt.toMillis();
      const codeAgeMinutes = Math.floor(codeAge / 60000);

      if (codeAgeMinutes >= CODE_EXPIRATION_MINUTES) {
        throw new functions.https.HttpsError(
            "deadline-exceeded",
            "Invalid or expired verification code.",
        );
      }
    }

    // Verify PIN
    if (pin !== storedCode) {
      const newFailedAttempts = failedAttempts + 1;

      await admin.firestore().collection("users").doc(uid).update({
        failedVerificationAttempts: newFailedAttempts,
        lastFailedAttempt: admin.firestore.FieldValue.serverTimestamp(),
      });

      if (newFailedAttempts >= MAX_ATTEMPTS) {
        throw new functions.https.HttpsError(
            "permission-denied",
            `Too many failed attempts. Account locked for ${LOCKOUT_MINUTES} minutes.`,
        );
      }

      const attemptsRemaining = MAX_ATTEMPTS - newFailedAttempts;
      throw new functions.https.HttpsError(
          "invalid-argument",
          `Invalid verification code. ${attemptsRemaining} attempts remaining.`,
      );
    }

    // PIN is correct! Mark user as verified
    await admin.firestore().collection("users").doc(uid).update({
      isVerified: true,
      verificationCode: admin.firestore.FieldValue.delete(),
      verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      failedVerificationAttempts: admin.firestore.FieldValue.delete(),
      lastFailedAttempt: admin.firestore.FieldValue.delete(),
    });

    return {
      success: true,
      message: "Verification successful!",
    };
  } catch (error) {
    // If it's already an HttpsError, re-throw it
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    console.error("Error verifying PIN:", error);
    throw new functions.https.HttpsError(
        "internal",
        "Failed to verify PIN.",
    );
  }
});

/**
 * Build email HTML template
 * @param {string} code - Verification code
 * @param {boolean} isResend - Whether this is a resend
 * @return {string} HTML string
 */
function buildEmailHtml(code, isResend) {
  const title = isResend ? "DateBlue Verification" : "Welcome to DateBlue!";
  const codeLabel = isResend ?
    "Your new verification code is:" :
    "Your verification code is:";

  return `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <h1 style="color: #0039A6;">${title}</h1>
      <p>${codeLabel}</p>
      <div style="background-color: #f5f5f5; padding: 20px; text-align: center; margin: 20px 0;">
        <span style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #0039A6;">${code}</span>
      </div>
      <p>Enter this code in the app to verify your GSU student email. The code expires in 5 minutes.</p>
      <p style="color: #666; font-size: 12px;">If you didn't request this code, please ignore this email.</p>
      <p style="color: #0039A6; font-weight: bold;">— The DateBlue Team</p>
    </div>
  `;
}

/**
 * Handle new interactions (likes/passes)
 * Triggered when a user creates an interaction with another user
 * This handles:
 * 1. Adding to receivedLikes (server-side, secure)
 * 2. Sending push notifications
 * 3. Match detection and notification
 */
exports.onInteractionCreated = functions.firestore
    .document("users/{fromUserId}/interactions/{toUserId}")
    .onCreate(async (snapshot, context) => {
      const interactionData = snapshot.data();
      const fromUserId = context.params.fromUserId;
      const toUserId = context.params.toUserId;

      // Only process likes (not passes)
      if (interactionData.action !== "like") {
        console.log("Interaction is a pass, skipping");
        return null;
      }

      try {
      // 1. Add to target user's receivedLikes (server-side only)
        await admin.firestore().collection("users").doc(toUserId).update({
          receivedLikes: admin.firestore.FieldValue.arrayUnion({
            fromUserId: fromUserId,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          }),
        });
        console.log("Added to receivedLikes for:", toUserId);

        // 2. Check for mutual like (match detection)
        const reverseInteraction = await admin.firestore()
            .collection("users")
            .doc(toUserId)
            .collection("interactions")
            .doc(fromUserId)
            .get();

        if (reverseInteraction.exists &&
        reverseInteraction.data().action === "like") {
        // It's a match! Create match document
          const matchId = fromUserId < toUserId ?
          `${fromUserId}_${toUserId}` :
          `${toUserId}_${fromUserId}`;

          await admin.firestore().collection("matches").doc(matchId).set({
            users: [fromUserId, toUserId],
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            lastMessage: null,
          });
          console.log("Match created:", matchId);

          // Remove from receivedLikes since they matched
          await removeFromReceivedLikes(fromUserId, toUserId);
          await removeFromReceivedLikes(toUserId, fromUserId);

          // Send match notifications to both users
          await sendMatchNotifications(fromUserId, toUserId);
          return null;
        }

        // 3. Send push notification for the like
        const targetUser = await admin.firestore()
            .collection("users")
            .doc(toUserId)
            .get();

        const targetData = targetUser.data();
        if (!targetData) {
          console.log("Target user not found:", toUserId);
          return null;
        }

        const fcmToken = targetData.fcmToken;
        if (!fcmToken) {
          console.log("No FCM token for user:", toUserId);
          return null;
        }

        // Get liker's blurred photo for the notification
        let blurredPhotoUrl = null;
        try {
          const likerDoc = await admin.firestore()
              .collection("users")
              .doc(fromUserId)
              .get();
          const likerData = likerDoc.data();
          if (likerData && likerData.mediaUrls && likerData.mediaUrls.length > 0) {
            const firstPhotoUrl = likerData.mediaUrls[0];
            // Check if we have a blurred version
            if (likerData.blurredMediaUrls && likerData.blurredMediaUrls[firstPhotoUrl]) {
              blurredPhotoUrl = likerData.blurredMediaUrls[firstPhotoUrl];
            }
          }
        } catch (e) {
          console.log("Could not get blurred photo:", e);
        }

        // Send anonymous push notification with blurred photo
        const message = {
          token: fcmToken,
          notification: {
            title: "Someone likes you! 💙",
            body: "Someone just liked your profile. Open DateBlue to find out who!",
            imageUrl: blurredPhotoUrl, // Blurred photo if available
          },
          data: {
            type: "like_received",
            fromUserId: fromUserId,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            notification: {
              channelId: "likes",
              priority: "high",
              imageUrl: blurredPhotoUrl,
            },
          },
          apns: {
            payload: {
              aps: {
                badge: 1,
                sound: "default",
              },
            },
            fcmOptions: blurredPhotoUrl ? {imageUrl: blurredPhotoUrl} : {},
          },
        };

        await admin.messaging().send(message);
        console.log("Like notification sent to:", toUserId);
        return null;
      } catch (error) {
        console.error("Error processing interaction:", error);
        return null;
      }
    });

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
    const filteredLikes = receivedLikes.filter((like) => {
      return like.fromUserId !== fromUserId;
    });

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
    // Get both user documents
    const [user1Doc, user2Doc] = await Promise.all([
      admin.firestore().collection("users").doc(user1Id).get(),
      admin.firestore().collection("users").doc(user2Id).get(),
    ]);

    const user1Data = user1Doc.data();
    const user2Data = user2Doc.data();

    // Send notification to user1 about matching with user2
    if (user1Data && user1Data.fcmToken) {
      const user2Name = (user2Data && user2Data.firstName) || "Someone";
      await admin.messaging().send({
        token: user1Data.fcmToken,
        notification: {
          title: "It's a Match! 💙",
          body: `You and ${user2Name} like each other! Start chatting now.`,
        },
        data: {
          type: "match",
          matchedUserId: user2Id,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          notification: {
            channelId: "matches",
            priority: "high",
          },
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: "default",
            },
          },
        },
      });
      console.log("Match notification sent to:", user1Id);
    }

    // Send notification to user2 about matching with user1
    if (user2Data && user2Data.fcmToken) {
      const user1Name = (user1Data && user1Data.firstName) || "Someone";
      await admin.messaging().send({
        token: user2Data.fcmToken,
        notification: {
          title: "It's a Match! 💙",
          body: `You and ${user1Name} like each other! Start chatting now.`,
        },
        data: {
          type: "match",
          matchedUserId: user1Id,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          notification: {
            channelId: "matches",
            priority: "high",
          },
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: "default",
            },
          },
        },
      });
      console.log("Match notification sent to:", user2Id);
    }
  } catch (error) {
    console.error("Error sending match notifications:", error);
  }
}

/**
 * Generate blurred thumbnail when a profile photo is uploaded
 * Creates a heavily blurred version for use in anonymous notifications
 * @param {Object} object - The storage object metadata
 */
exports.onImageUploaded = functions.storage
    .bucket("dateblue-gsu.firebasestorage.app")
    .object()
    .onFinalize(async (object) => {
      const sharp = require("sharp");
      const path = require("path");
      const os = require("os");
      const fs = require("fs");

      const filePath = object.name;
      const contentType = object.contentType;
      const bucket = admin.storage().bucket(object.bucket);

      // Only process images in user_photos folder
      if (!filePath || !filePath.startsWith("user_photos/")) {
        console.log("Not a user photo, skipping:", filePath);
        return null;
      }

      // Skip if already a blurred version
      if (filePath.includes("_blurred")) {
        console.log("Already blurred, skipping:", filePath);
        return null;
      }

      // Only process images
      if (!contentType || !contentType.startsWith("image/")) {
        console.log("Not an image, skipping:", filePath);
        return null;
      }

      try {
      // Download the original image
        const fileName = path.basename(filePath);
        const tempFilePath = path.join(os.tmpdir(), fileName);
        const blurredFileName = path.basename(filePath, path.extname(filePath)) +
        "_blurred.jpg";
        const blurredFilePath = path.dirname(filePath) + "/" + blurredFileName;
        const tempBlurredPath = path.join(os.tmpdir(), blurredFileName);

        await bucket.file(filePath).download({destination: tempFilePath});
        console.log("Downloaded original image to:", tempFilePath);

        // Create blurred version using sharp
        // Heavy blur (sigma 30) + resize to small thumbnail
        await sharp(tempFilePath)
            .resize(200, 200, {fit: "cover"})
            .blur(30)
            .jpeg({quality: 60})
            .toFile(tempBlurredPath);
        console.log("Created blurred thumbnail:", tempBlurredPath);

        // Upload blurred version
        await bucket.upload(tempBlurredPath, {
          destination: blurredFilePath,
          metadata: {
            contentType: "image/jpeg",
            metadata: {
              originalFile: filePath,
              isBlurred: "true",
            },
          },
        });
        console.log("Uploaded blurred image to:", blurredFilePath);

        // Make the blurred file public and get URL
        const blurredFile = bucket.file(blurredFilePath);
        await blurredFile.makePublic();
        const blurredUrl =
        `https://storage.googleapis.com/${object.bucket}/${blurredFilePath}`;

        // Extract userId from path (user_photos/{userId}/...)
        const pathParts = filePath.split("/");
        if (pathParts.length >= 2) {
          const userId = pathParts[1];

          // Update user document with blurred URL mapping
          const userRef = admin.firestore().collection("users").doc(userId);
          const userDoc = await userRef.get();

          if (userDoc.exists) {
            const userData = userDoc.data();
            const blurredUrls = userData.blurredMediaUrls || {};

            // Create public URL for original
            const originalFile = bucket.file(filePath);
            await originalFile.makePublic();
            const originalUrl =
            `https://storage.googleapis.com/${object.bucket}/${filePath}`;

            // Map original URL to blurred URL
            blurredUrls[originalUrl] = blurredUrl;

            await userRef.update({
              blurredMediaUrls: blurredUrls,
            });
            console.log("Updated user blurred URLs for:", userId);
          }
        }

        // Clean up temp files
        fs.unlinkSync(tempFilePath);
        fs.unlinkSync(tempBlurredPath);

        return null;
      } catch (error) {
        console.error("Error creating blurred thumbnail:", error);
        return null;
      }
    });
