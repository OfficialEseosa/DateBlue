import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class VerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Generate a random 4-digit verification code
  String generateVerificationCode() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }

  /// Check if user is already verified
  Future<bool> isUserVerified(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists && doc.data()?['isVerified'] == true;
  }

  /// Check if GSU email is already used by another verified user
  Future<bool> isGsuEmailTaken(String gsuEmail, String currentUid) async {
    final query = await _firestore
        .collection('users')
        .where('gsuEmail', isEqualTo: gsuEmail)
        .where('isVerified', isEqualTo: true)
        .get();
    
    // Check if any verified user (other than current) has this email
    return query.docs.any((doc) => doc.id != currentUid);
  }

  /// Send verification email and save user data
  Future<void> sendVerificationEmail({
    required User user,
    required String campusId,
  }) async {
    final verificationCode = generateVerificationCode();
    final gsuEmail = '$campusId@student.gsu.edu';

    // Save user data and verification code to Firestore
    await _firestore.collection('users').doc(user.uid).set({
      'googleEmail': user.email,
      'displayName': user.displayName,
      'gsuEmail': gsuEmail,
      'verificationCode': verificationCode,
      'codeCreatedAt': FieldValue.serverTimestamp(),
      'isVerified': false,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Send verification email via Firebase Extension (Trigger Email)
    await _firestore.collection('mail').add({
      'to': gsuEmail,
      'message': {
        'subject': 'DateBlue Verification Code',
        'html': _buildEmailHtml(verificationCode, isResend: false),
      },
    });
  }

  /// Resend verification code
  Future<void> resendVerificationCode({
    required String uid,
    required String campusId,
  }) async {
    final verificationCode = generateVerificationCode();
    final gsuEmail = '$campusId@student.gsu.edu';

    // Update verification code in Firestore
    await _firestore.collection('users').doc(uid).update({
      'verificationCode': verificationCode,
      'codeCreatedAt': FieldValue.serverTimestamp(),
    });

    // Send new verification email
    await _firestore.collection('mail').add({
      'to': gsuEmail,
      'message': {
        'subject': 'DateBlue Verification Code',
        'html': _buildEmailHtml(verificationCode, isResend: true),
      },
    });
  }

  /// Verify PIN code
  /// Returns true if successful, throws Exception if invalid
  Future<bool> verifyPin({
    required String uid,
    required String pin,
  }) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final storedCode = userDoc.data()?['verificationCode'];

    if (storedCode == null) {
      throw Exception('No verification code found. Please request a new code.');
    }

    if (pin != storedCode) {
      throw Exception('Invalid code. Please try again.');
    }

    // Code is correct! Mark user as verified and clear the code
    await _firestore.collection('users').doc(uid).update({
      'isVerified': true,
      'verificationCode': FieldValue.delete(),
      'verifiedAt': FieldValue.serverTimestamp(),
    });

    return true;
  }

  /// Logout user
  Future<void> logout() async {
    await GoogleSignIn.instance.signOut();
    await FirebaseAuth.instance.signOut();
  }

  /// Build email HTML template
  String _buildEmailHtml(String code, {required bool isResend}) {
    final title = isResend ? 'DateBlue Verification' : 'Welcome to DateBlue!';
    final codeLabel = isResend ? 'Your new verification code is:' : 'Your verification code is:';
    
    return '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h1 style="color: #0039A6;">$title</h1>
        <p>$codeLabel</p>
        <div style="background-color: #f5f5f5; padding: 20px; text-align: center; margin: 20px 0;">
          <span style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #0039A6;">$code</span>
        </div>
        <p>Enter this code in the app to verify your GSU student email.</p>
        <p style="color: #666; font-size: 12px;">If you didn't request this code, please ignore this email.</p>
        <p style="color: #0039A6; font-weight: bold;">— The DateBlue Team</p>
      </div>
    ''';
  }
}
