const functions = require("firebase-functions");
const admin = require("firebase-admin");

/**
 * Generate blurred thumbnail when a profile photo is uploaded
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

      if (!filePath || !filePath.startsWith("user_photos/")) {
        console.log("Not a user photo, skipping:", filePath);
        return null;
      }

      if (filePath.includes("_blurred")) {
        console.log("Already blurred, skipping:", filePath);
        return null;
      }

      if (!contentType || !contentType.startsWith("image/")) {
        console.log("Not an image, skipping:", filePath);
        return null;
      }

      try {
        const fileName = path.basename(filePath);
        const tempFilePath = path.join(os.tmpdir(), fileName);
        const blurredFileName = path.basename(filePath, path.extname(filePath)) + "_blurred.jpg";
        const blurredFilePath = path.dirname(filePath) + "/" + blurredFileName;
        const tempBlurredPath = path.join(os.tmpdir(), blurredFileName);

        await bucket.file(filePath).download({destination: tempFilePath});
        console.log("Downloaded original image to:", tempFilePath);

        await sharp(tempFilePath)
            .resize(200, 200, {fit: "cover"})
            .blur(30)
            .jpeg({quality: 60})
            .toFile(tempBlurredPath);
        console.log("Created blurred thumbnail:", tempBlurredPath);

        await bucket.upload(tempBlurredPath, {
          destination: blurredFilePath,
          metadata: {
            contentType: "image/jpeg",
            metadata: {originalFile: filePath, isBlurred: "true"},
          },
        });
        console.log("Uploaded blurred image to:", blurredFilePath);

        const blurredFile = bucket.file(blurredFilePath);
        await blurredFile.makePublic();
        const blurredUrl = `https://storage.googleapis.com/${object.bucket}/${blurredFilePath}`;

        const pathParts = filePath.split("/");
        if (pathParts.length >= 2) {
          const userId = pathParts[1];
          const userRef = admin.firestore().collection("users").doc(userId);
          const userDoc = await userRef.get();

          if (userDoc.exists) {
            const userData = userDoc.data();
            const blurredUrls = userData.blurredMediaUrls || {};

            const originalFile = bucket.file(filePath);
            await originalFile.makePublic();
            const originalUrl = `https://storage.googleapis.com/${object.bucket}/${filePath}`;

            blurredUrls[originalUrl] = blurredUrl;
            await userRef.update({blurredMediaUrls: blurredUrls});
            console.log("Updated user blurred URLs for:", userId);
          }
        }

        fs.unlinkSync(tempFilePath);
        fs.unlinkSync(tempBlurredPath);
        return null;
      } catch (error) {
        console.error("Error creating blurred thumbnail:", error);
        return null;
      }
    });
