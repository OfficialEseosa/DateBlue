import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class VerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  /// Code expiration time in minutes
  static const int codeExpirationMinutes = 5;
  
  /// Rate limit cooldown in seconds
  static const int resendCooldownSeconds = 60;
  
  /// Maximum PIN verification attempts before lockout
  static const int maxVerificationAttempts = 3;
  
  /// Lockout duration in minutes after max attempts
  static const int lockoutDurationMinutes = 15;

  /// Check if user is already verified
  Future<bool> isUserVerified(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists && doc.data()?['isVerified'] == true;
  }

  /// Send verification email via Cloud Function (secure)
  Future<void> sendVerificationEmail({
    required User user,
    required String campusId,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('sendVerificationEmail')
          .call({'campusId': campusId});
      
      if (result.data['success'] != true) {
        throw Exception('Failed to send verification email');
      }
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to send verification email');
    } catch (e) {
      throw Exception('Failed to send verification email: $e');
    }
  }

  /// Resend verification code via Cloud Function (secure)
  Future<void> resendVerificationCode() async {
    try {
      final result = await _functions
          .httpsCallable('resendVerificationCode')
          .call({});
      
      if (result.data['success'] != true) {
        throw Exception('Failed to resend verification code');
      }
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to resend verification code');
    } catch (e) {
      throw Exception('Failed to resend verification code: $e');
    }
  }

  /// Verify PIN code via Cloud Function (secure with rate limiting)
  Future<bool> verifyPin({
    required String pin,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('verifyPin')
          .call({'pin': pin});
      
      return result.data['success'] == true;
    } on FirebaseFunctionsException catch (e) {
      // Extract the message from the error
      throw Exception(e.message ?? 'Failed to verify PIN');
    } catch (e) {
      throw Exception('Failed to verify PIN: $e');
    }
  }

  /// Logout user
  Future<void> logout() async {
    await GoogleSignIn.instance.signOut();
    await FirebaseAuth.instance.signOut();
  }
}
