/**
 * DateBlue Cloud Functions
 * Main entry point - re-exports all functions from modular files
 */
const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
admin.initializeApp();

// Import and re-export all functions
const verification = require("./src/verification");
const interactions = require("./src/interactions");
const storage = require("./src/storage");
const cleanup = require("./src/cleanup");

// Email verification functions
exports.sendVerificationEmail = verification.sendVerificationEmail;
exports.resendVerificationCode = verification.resendVerificationCode;
exports.verifyPin = verification.verifyPin;

// Interaction and matching functions
exports.onInteractionCreated = interactions.onInteractionCreated;

// Storage functions
exports.onImageUploaded = storage.onImageUploaded;

// Cleanup functions
exports.onUserDeleted = cleanup.onUserDeleted;
