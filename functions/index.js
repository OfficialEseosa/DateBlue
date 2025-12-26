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
 * Send push notification when someone receives a like
 * Triggered when receivedLikes field is updated
 */
exports.onLikeReceived = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();
      const userId = context.params.userId;

      // Check if receivedLikes was updated
      const beforeLikes = before.receivedLikes || [];
      const afterLikes = after.receivedLikes || [];

      // Only proceed if a new like was added
      if (afterLikes.length <= beforeLikes.length) {
        return null;
      }

      // Get the FCM token
      const fcmToken = after.fcmToken;
      if (!fcmToken) {
        console.log("No FCM token for user:", userId);
        return null;
      }

      // Get the new liker's info
      const newLike = afterLikes[afterLikes.length - 1];
      const likerId = newLike.fromUserId;

      try {
        const likerDoc = await admin.firestore().collection("users").doc(likerId).get();
        const likerData = likerDoc.data() || {};
        const likerName = likerData.firstName || "Someone";
        const likerPhoto = (likerData.mediaUrls && likerData.mediaUrls[0]) || null;

        // Send push notification
        const message = {
          token: fcmToken,
          notification: {
            title: "Someone likes you! 💙",
            body: `${likerName} just liked your profile. Tap to see who!`,
          },
          data: {
            type: "like_received",
            fromUserId: likerId,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            notification: {
              channelId: "likes",
              priority: "high",
              imageUrl: likerPhoto,
            },
          },
          apns: {
            payload: {
              aps: {
                badge: 1,
                sound: "default",
              },
            },
            fcmOptions: {
              imageUrl: likerPhoto,
            },
          },
        };

        await admin.messaging().send(message);
        console.log("Notification sent to:", userId);
        return null;
      } catch (error) {
        console.error("Error sending notification:", error);
        return null;
      }
    });

