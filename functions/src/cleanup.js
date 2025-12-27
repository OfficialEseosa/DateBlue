const functions = require("firebase-functions");
const admin = require("firebase-admin");

/**
 * Clean up all references when a user deletes their account
 * Triggered when a user document is deleted from Firestore
 */
exports.onUserDeleted = functions.firestore
    .document("users/{userId}")
    .onDelete(async (snapshot, context) => {
      const deletedUserId = context.params.userId;
      console.log("User deleted, cleaning up references for:", deletedUserId);

      try {
        // 1. Remove from all users' receivedLikes
        await cleanupReceivedLikes(deletedUserId);

        // 2. Delete all matches involving this user
        await cleanupMatches(deletedUserId);

        // 3. Delete interactions subcollection
        await deleteSubcollection(deletedUserId, "interactions");

        // 4. Delete user's photos from Storage
        await cleanupStorage(deletedUserId);

        // 5. Remove from any other users' interactions (where they were the target)
        await cleanupInteractionReferences(deletedUserId);

        console.log("Successfully cleaned up all references for:", deletedUserId);
        return null;
      } catch (error) {
        console.error("Error cleaning up user references:", error);
        return null;
      }
    });

/**
 * Remove deleted user from all receivedLikes arrays
 * @param {string} deletedUserId - The deleted user's ID
 */
async function cleanupReceivedLikes(deletedUserId) {
  try {
    // Query all users who have this user in their receivedLikes
    const usersSnapshot = await admin.firestore().collection("users").get();
    let batch = admin.firestore().batch();
    let batchCount = 0;

    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      const receivedLikes = userData.receivedLikes || [];

      // Check if deleted user is in this user's receivedLikes
      const hasDeletedUser = receivedLikes.some(
          (like) => like.fromUserId === deletedUserId,
      );

      if (hasDeletedUser) {
        const filteredLikes = receivedLikes.filter(
            (like) => like.fromUserId !== deletedUserId,
        );

        batch.update(userDoc.ref, {receivedLikes: filteredLikes});
        batchCount++;

        // Firestore batch limit is 500, commit and create new batch
        if (batchCount >= 400) {
          await batch.commit();
          batch = admin.firestore().batch();
          batchCount = 0;
        }
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    console.log("Cleaned up receivedLikes references");
  } catch (error) {
    console.error("Error cleaning up receivedLikes:", error);
  }
}

/**
 * Delete all matches involving the deleted user
 * @param {string} deletedUserId - The deleted user's ID
 */
async function cleanupMatches(deletedUserId) {
  try {
    const matchesSnapshot = await admin.firestore()
        .collection("matches")
        .where("users", "array-contains", deletedUserId)
        .get();

    let batch = admin.firestore().batch();
    let batchCount = 0;

    for (const matchDoc of matchesSnapshot.docs) {
      batch.delete(matchDoc.ref);
      batchCount++;

      if (batchCount >= 400) {
        await batch.commit();
        batch = admin.firestore().batch();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    console.log(`Deleted ${matchesSnapshot.size} matches`);
  } catch (error) {
    console.error("Error cleaning up matches:", error);
  }
}

/**
 * Delete a subcollection for a user
 * @param {string} userId - The user's ID
 * @param {string} subcollectionName - Name of the subcollection to delete
 */
async function deleteSubcollection(userId, subcollectionName) {
  try {
    const subcollectionRef = admin.firestore()
        .collection("users")
        .doc(userId)
        .collection(subcollectionName);

    const snapshot = await subcollectionRef.get();

    let batch = admin.firestore().batch();
    let batchCount = 0;

    for (const doc of snapshot.docs) {
      batch.delete(doc.ref);
      batchCount++;

      if (batchCount >= 400) {
        await batch.commit();
        batch = admin.firestore().batch();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    console.log(`Deleted ${snapshot.size} documents from ${subcollectionName}`);
  } catch (error) {
    console.error(`Error deleting subcollection ${subcollectionName}:`, error);
  }
}

/**
 * Delete user's photos from Storage
 * @param {string} userId - The user's ID
 */
async function cleanupStorage(userId) {
  try {
    const bucket = admin.storage().bucket("dateblue-gsu.firebasestorage.app");
    const [files] = await bucket.getFiles({prefix: `user_photos/${userId}/`});

    for (const file of files) {
      await file.delete();
      console.log("Deleted file:", file.name);
    }

    console.log(`Deleted ${files.length} files from storage`);
  } catch (error) {
    console.error("Error cleaning up storage:", error);
  }
}

/**
 * Remove interactions where the deleted user was the target
 * (Clean up other users' interactions subcollections)
 * @param {string} deletedUserId - The deleted user's ID
 */
async function cleanupInteractionReferences(deletedUserId) {
  try {
    // Get all users
    const usersSnapshot = await admin.firestore().collection("users").get();
    let deleteCount = 0;

    for (const userDoc of usersSnapshot.docs) {
      // Check if this user has an interaction with the deleted user
      const interactionRef = admin.firestore()
          .collection("users")
          .doc(userDoc.id)
          .collection("interactions")
          .doc(deletedUserId);

      const interactionDoc = await interactionRef.get();

      if (interactionDoc.exists) {
        await interactionRef.delete();
        deleteCount++;
      }
    }

    console.log(`Deleted ${deleteCount} interaction references`);
  } catch (error) {
    console.error("Error cleaning up interaction references:", error);
  }
}
