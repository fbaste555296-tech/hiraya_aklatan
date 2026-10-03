import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/config/app_constants.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

/// Repository for authentication operations
class AuthRepository {
  AuthRepository({required this._firestoreService})
    : _auth = FirebaseAuth.instance;

  final FirebaseAuth _auth;
  final FirestoreService _firestoreService;
  final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn();

  /// Gets the current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Registers a new user with email and password
  /// Automatically creates a user document with 'reader' role
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to create user account');
      }

      // Create user document in Firestore
      final userModel = UserModel(
        uid: user.uid,
        name: name,
        email: email,
        role: AppConstants.roleReader,
        vipExpiry: null,
        createdAt: DateTime.now(),
      );

      await _firestoreService.users.doc(user.uid).set(userModel.toMap());

      // Update display name in Firebase Auth
      await user.updateDisplayName(name);

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to register: ${e.toString()}');
    }
  }

  /// Signs in with Google.
  ///
  /// On web, uses a popup. On mobile, uses the native Google Sign-In flow.
  /// Creates a Firestore user document with 'reader' role on first sign-in.
  Future<UserModel> signInWithGoogle() async {
    try {
      final UserCredential userCredential;

      if (kIsWeb) {
        // Web: use popup
        final googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobile: use native Google Sign-In
        final googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) {
          throw Exception('Google sign-in cancelled');
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Google sign-in failed');
      }

      // Create Firestore user document if it doesn't exist
      final userDoc = await _firestoreService.users.doc(user.uid).get();
      if (!userDoc.exists) {
        final userModel = UserModel(
          uid: user.uid,
          name: user.displayName ?? 'Reader',
          email: user.email ?? '',
          role: AppConstants.roleReader,
          vipExpiry: null,
          createdAt: DateTime.now(),
        );

        await _firestoreService.users.doc(user.uid).set(userModel.toMap());
        return userModel;
      }

      // Return existing user
      return UserModel.fromMap(
        userDoc.data() as Map<String, dynamic>,
        user.uid,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to sign in with Google: ${e.toString()}');
    }
  }

  /// Signs in with email and password
  Future<User> signIn({required String email, required String password}) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Sign in failed');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  /// Signs out the current user
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn?.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  /// Sends a password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  /// Updates the user's password
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to update password: ${e.toString()}');
    }
  }

  /// Deletes the current user account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      // Delete user document from Firestore
      await _firestoreService.users.doc(user.uid).delete();

      // Delete Firebase Auth account
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }

  /// Handles Firebase Auth exceptions and returns user-friendly exception
  Exception _handleAuthException(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'weak-password':
        message = 'The password is too weak';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email';
        break;
      case 'invalid-email':
        message = 'Invalid email address';
        break;
      case 'missing-email':
        message = 'Enter an email address to continue';
        break;
      case 'user-disabled':
        message = 'This account has been disabled';
        break;
      case 'user-not-found':
        message = 'No account found with this email';
        break;
      case 'wrong-password':
        message = 'Incorrect password';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Please try again later';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your connection';
        break;
      case 'requires-recent-login':
        message = 'Please sign in again to continue';
        break;
      case 'account-exists-with-different-credential':
        message = 'An account already exists with a different sign-in method';
        break;
      case 'invalid-credential':
      case 'invalid-login-credentials':
        message = 'Invalid sign-in credentials';
        break;
      case 'operation-not-allowed':
        message =
            'This sign-in method is not enabled in Firebase Authentication.';
        break;
      case 'configuration-not-found':
        message =
            'Firebase Authentication is not configured for this project. '
            'Enable Email/Password and Google sign-in in the Firebase Console.';
        break;
      default:
        final firebaseMessage = e.message;
        message =
            firebaseMessage == null ||
                firebaseMessage.trim().isEmpty ||
                firebaseMessage.trim().toLowerCase() == 'error'
            ? 'Authentication failed (${e.code}). Please try again.'
            : firebaseMessage;
    }
    return Exception(message);
  }
}
