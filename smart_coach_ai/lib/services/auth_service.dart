import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as enums;
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import '../core/app_url_helper.dart';
import '../core/appwrite_constants.dart';
import 'appwrite_service.dart';

class AuthService {
  final Account _account = AppwriteService.instance.account;

  // Sign up with email and password
  Future<models.User?> signUp(
    String email,
    String password,
    String name,
  ) async {
    // Basic client-side email validation to avoid Appwrite validation errors
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      debugPrint('Sign Up Error: Invalid email format');
      return null;
    }
    try {
      final user = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      // Automatically log in after sign up
      await login(email, password);

      // Send email verification link
      final verificationSent = await sendEmailVerification();
      if (!verificationSent) {
        debugPrint('Warning: verification email could not be sent.');
      }

      return user;
    } on AppwriteException catch (e) {
      debugPrint('Sign Up Error: ${e.message}');
      return null;
    }
  }

  // Login with email and password
  Future<models.Session?> login(String email, String password) async {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      debugPrint('Login Error: Invalid email format');
      return null;
    }
    try {
      // Attempt to create a new session
      final session = await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      return session;
    } on AppwriteException catch (e) {
      // If a session is already active, clear it and retry once
      if (e.message?.contains('already') == true) {
        try {
          await _account.deleteSession(sessionId: 'current');
        } catch (_) {}
        // Retry login
        try {
          final retrySession = await _account.createEmailPasswordSession(
            email: email,
            password: password,
          );
          return retrySession;
        } catch (e2) {
          debugPrint('Login retry Error: $e2');
          rethrow;
        }
      }
      debugPrint('Login Error: ${e.message}');
      rethrow;
    }
  }

  // Get current logged-in user
  Future<models.User?> getCurrentUser() async {
    try {
      return await _account.get();
    } on AppwriteException {
      return null;
    }
  }

  // Send email verification message
  Future<bool> sendEmailVerification() async {
    try {
      await _account.createVerification(
        url: AppUrlHelper.emailVerificationUrl,
      );
      return true;
    } on AppwriteException catch (e) {
      debugPrint('Send email verification Error: ${e.message}');
      return false;
    }
  }

  // Check if current user email is verified
  Future<bool> isEmailVerified() async {
    final user = await getCurrentUser();
    return user?.emailVerification == true;
  }

  // Confirm email verification using the userId and secret.
  Future<bool> confirmEmailVerification({
    required String userId,
    required String secret,
  }) async {
    try {
      await _account.updateVerification(
        userId: userId,
        secret: secret,
      );
      return true;
    } on AppwriteException catch (e) {
      debugPrint('Confirm email verification Error: ${e.message}');
      return false;
    }
  }

  // Create profile document for a verified user
  Future<bool> createProfileForCurrentUser() async {
    final user = await getCurrentUser();
    if (user == null) {
      return false;
    }

    try {
      await AppwriteService.instance.databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.profilesCollection,
        documentId: user.$id,
        data: {
          'userId': user.$id,
          'fullName': user.name.isNotEmpty ? user.name : 'User',
          'level': 'beginner',
        },
      );
      return true;
    } on AppwriteException catch (e) {
      if (e.code == 409) {
        // Document already exists
        return true;
      }
      debugPrint('Profile creation error: ${e.message}');
      return false;
    }
  }

  // Login with Google OAuth
  Future<models.Session?> loginWithGoogle({required String successUrl}) async {
    try {
      final session = await _account.createOAuth2Session(
        provider: enums.OAuthProvider.google,
        success: successUrl,
      );
      return session;
    } on AppwriteException catch (e) {
      debugPrint('Google Login Error: ${e.message}');
      return null;
    }
  }

  // Login with Apple OAuth
  Future<models.Session?> loginWithApple({required String successUrl}) async {
    try {
      final session = await _account.createOAuth2Session(
        provider: enums.OAuthProvider.apple,
        success: successUrl,
      );
      return session;
    } on AppwriteException catch (e) {
      debugPrint('Apple Login Error: ${e.message}');
      return null;
    }
  }

  // Send password recovery email.
  // Appwrite will email the user a link: passwordRecoveryUrl?userId=xxx&secret=yyy
  Future<bool> sendPasswordRecovery(String email) async {
    try {
      await _account.createRecovery(
        email: email,
        url: AppUrlHelper.passwordRecoveryUrl, // ← الـ URL الصحيح
      );
      return true;
    } on AppwriteException catch (e) {
      debugPrint('Password recovery error: ${e.message}');
      return false;
    }
  }

  // Complete password reset using the userId + secret from the recovery URL.
  // Called from ResetPasswordPage after the user opens the email link.
  Future<bool> confirmPasswordReset({
    required String userId,
    required String secret,
    required String newPassword,
  }) async {
    try {
      await _account.updateRecovery(
        userId: userId,
        secret: secret,
        password: newPassword,
      );
      return true;
    } on AppwriteException catch (e) {
      debugPrint('Confirm password reset error: ${e.message}');
      return false;
    }
  }

  // Send 6-digit email OTP (Token)
  Future<String?> sendEmailOtp(String email) async {
    try {
      final token = await _account.createEmailToken(
        userId: ID.unique(),
        email: email,
      );
      return token.userId;
    } on AppwriteException catch (e) {
      debugPrint('Send Email OTP Error: ${e.message}');
      return null;
    }
  }

  // Verify 6-digit email OTP (Token) and create session
  Future<models.Session?> verifyEmailOtp({
    required String userId,
    required String otp,
  }) async {
    try {
      // Log out existing session if any to avoid Session Prohibited error
      try {
        await logout();
      } catch (_) {}

      final session = await _account.createSession(
        userId: userId,
        secret: otp,
      );
      return session;
    } on AppwriteException catch (e) {
      debugPrint('Verify Email OTP Error: ${e.message}');
      return null;
    }
  }

  // Reset password after OTP verification:
  // Since the user is logged in via OTP, they have an active session.
  // Appwrite allows updating the password directly without oldPassword for users authenticated via Magic URL/Email Token.
  Future<bool> resetPasswordViaToken({
    required String email,
    required String newPassword,
  }) async {
    try {
      await _account.updatePassword(
        password: newPassword,
      );
      return true;
    } on AppwriteException catch (e) {
      debugPrint('Reset password via updatePassword error: ${e.message}');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } on AppwriteException catch (e) {
      debugPrint('Logout Error: ${e.message}');
    }
  }
}
