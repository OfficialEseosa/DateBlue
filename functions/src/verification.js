const functions = require("firebase-functions");
const admin = require("firebase-admin");

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
      <p>This code will expire in 10 minutes.</p>
      <p style="color: #666; font-size: 12px; margin-top: 30px;">
        If you didn't request this code, you can safely ignore this email.
      </p>
    </div>
  `;
}

/**
 * Send verification email with code
 */
exports.sendVerificationEmail = functions.https.onCall(async (data, context) => {
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

  if (!campusId || typeof campusId !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "Campus ID is required.");
  }

  if (campusId.length < 1 || campusId.length > 20) {
    throw new functions.https.HttpsError(
        "invalid-argument", "Campus ID must be between 1 and 20 characters.");
  }

  if (!/^[a-zA-Z0-9_-]+$/.test(campusId)) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Campus ID must be alphanumeric and may only contain underscores or hyphens.");
  }

  const gsuEmail = `${campusId}@student.gsu.edu`;

  try {
    const existingUsers = await admin.firestore()
        .collection("users")
        .where("gsuEmail", "==", gsuEmail)
        .where("isVerified", "==", true)
        .get();

    const isTaken = existingUsers.docs.some((doc) => doc.id !== uid);
    const verificationCode = generateSecureCode();

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
      message: "If this is a valid GSU email and not in use, you will receive a code shortly.",
    };
  } catch (error) {
    console.error("Error sending verification email:", error);
    throw new functions.https.HttpsError("internal", "Failed to send verification email.");
  }
});

/**
 * Resend verification code
 */
exports.resendVerificationCode = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
  }

  const uid = context.auth.uid;
  const COOLDOWN_SECONDS = 60;

  try {
    const userDoc = await admin.firestore().collection("users").doc(uid).get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
          "not-found", "User not found. Please start verification again.");
    }

    const userData = userDoc.data();
    const gsuEmail = userData.gsuEmail;

    if (!gsuEmail) {
      throw new functions.https.HttpsError(
          "failed-precondition", "No GSU email found. Please start verification again.");
    }

    const lastSent = userData.codeCreatedAt;
    if (lastSent) {
      const lastSentDate = lastSent.toDate();
      const now = new Date();
      const secondsSinceLastSent = (now - lastSentDate) / 1000;

      if (secondsSinceLastSent < COOLDOWN_SECONDS) {
        const remaining = Math.ceil(COOLDOWN_SECONDS - secondsSinceLastSent);
        throw new functions.https.HttpsError(
            "resource-exhausted",
            `Please wait ${remaining} seconds before requesting a new code.`);
      }
    }

    const verificationCode = generateSecureCode();

    await admin.firestore().collection("users").doc(uid).update({
      verificationCode: verificationCode,
      codeCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
      failedVerificationAttempts: 0,
    });

    await admin.firestore().collection("mail").add({
      to: gsuEmail,
      message: {
        subject: "DateBlue Verification Code",
        html: buildEmailHtml(verificationCode, true),
      },
    });

    return {success: true, message: "New verification code sent!"};
  } catch (error) {
    if (error instanceof functions.https.HttpsError) throw error;
    console.error("Error resending verification code:", error);
    throw new functions.https.HttpsError("internal", "Failed to resend verification code.");
  }
});

/**
 * Verify the PIN code
 */
exports.verifyPin = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
  }

  const {pin} = data;
  const uid = context.auth.uid;

  if (!pin || typeof pin !== "string" || pin.length !== 4) {
    throw new functions.https.HttpsError("invalid-argument", "A 4-digit PIN is required.");
  }

  const MAX_ATTEMPTS = 5;
  const LOCKOUT_MINUTES = 15;

  try {
    const userDoc = await admin.firestore().collection("users").doc(uid).get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "User not found.");
    }

    const userData = userDoc.data();
    const storedCode = userData.verificationCode;
    const failedAttempts = userData.failedVerificationAttempts || 0;
    const lastFailedAttempt = userData.lastFailedAttempt;
    const codeCreatedAt = userData.codeCreatedAt;

    if (failedAttempts >= MAX_ATTEMPTS && lastFailedAttempt) {
      const lockoutEnd = new Date(
          lastFailedAttempt.toDate().getTime() + LOCKOUT_MINUTES * 60 * 1000);
      const now = new Date();

      if (now < lockoutEnd) {
        const minutesRemaining = Math.ceil((lockoutEnd - now) / (60 * 1000));
        throw new functions.https.HttpsError(
            "resource-exhausted",
            `Too many failed attempts. Try again in ${minutesRemaining} minutes.`);
      } else {
        await admin.firestore().collection("users").doc(uid).update({
          failedVerificationAttempts: 0,
        });
      }
    }

    if (!storedCode) {
      throw new functions.https.HttpsError(
          "failed-precondition", "No verification code found. Please request a new code.");
    }

    if (codeCreatedAt) {
      const codeAge = (new Date() - codeCreatedAt.toDate()) / 1000 / 60;
      if (codeAge > 10) {
        throw new functions.https.HttpsError(
            "deadline-exceeded", "Verification code has expired. Please request a new code.");
      }
    }

    if (pin !== storedCode) {
      const newFailedAttempts = failedAttempts + 1;
      await admin.firestore().collection("users").doc(uid).update({
        failedVerificationAttempts: newFailedAttempts,
        lastFailedAttempt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const attemptsRemaining = MAX_ATTEMPTS - newFailedAttempts;
      throw new functions.https.HttpsError(
          "invalid-argument",
          `Invalid verification code. ${attemptsRemaining} attempts remaining.`);
    }

    await admin.firestore().collection("users").doc(uid).update({
      isVerified: true,
      verificationCode: admin.firestore.FieldValue.delete(),
      verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      failedVerificationAttempts: admin.firestore.FieldValue.delete(),
      lastFailedAttempt: admin.firestore.FieldValue.delete(),
    });

    return {success: true, message: "Verification successful!"};
  } catch (error) {
    if (error instanceof functions.https.HttpsError) throw error;
    console.error("Error verifying PIN:", error);
    throw new functions.https.HttpsError("internal", "Failed to verify PIN.");
  }
});
