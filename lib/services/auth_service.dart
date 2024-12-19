import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email & Password Sign Up
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Send email verification
      await result.user?.sendEmailVerification();
      return result;
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  // Email & Password Sign In
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Begin interactive sign in process
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn().catchError((error) {
        debugPrint('Sign in error caught: $error');
        return null;
      });

      if (googleUser == null) {
        debugPrint('Google Sign In was aborted');
        return null;
      }

      // Even if we get an error in authentication, try to get the auth details
      GoogleSignInAuthentication? googleAuth;
      try {
        googleAuth = await googleUser.authentication;
      } catch (e) {
        debugPrint('Authentication error: $e');
        // If authentication fails, try to get tokens directly
        final tokens = await googleUser.authHeaders;
        final idToken = tokens['id_token'];
        final accessToken = tokens['access_token'];

        if (idToken != null && accessToken != null) {
          final credential = GoogleAuthProvider.credential(
            accessToken: accessToken,
            idToken: idToken,
          );
          return await _auth.signInWithCredential(credential);
        }
        return null;
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Final Google sign in error: $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithApple() async {
    try {
      final isAvailable = await SignInWithApple.isAvailable();

      if (!isAvailable) {
        throw Exception('Apple Sign In is not available on this device');
      }

      // Request credential for the user
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId:
              'com.example.biztrail', // Replace with your service identifier
          redirectUri:
              Uri.parse('https://biz-trail.firebaseapp.com/__/auth/handler'),
        ),
      );

      // Create an OAuthCredential from the Apple ID credential
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // If this is a new sign-in and we got user info, create a display name
      String? displayName;
      if (appleCredential.givenName != null ||
          appleCredential.familyName != null) {
        displayName =
            '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                .trim();
      }

      // Sign in to Firebase with the Apple OAuth credential
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // If this is a new user and we have a display name, update their profile
      if (userCredential.additionalUserInfo?.isNewUser == true &&
          displayName != null &&
          displayName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(displayName);
      }

      return userCredential;
    } catch (e) {
      debugPrint('Apple sign in error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }
}
