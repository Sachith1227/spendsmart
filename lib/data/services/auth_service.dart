import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thrown with a user-friendly message for display in the UI.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Wraps Firebase Auth + Firestore user profile storage.
///
/// Passwords are never stored by the app; Firebase Auth handles hashing.
/// Only non-sensitive profile fields are written to `users/{uid}`, and
/// Firestore rules (firestore.rules) restrict each document to its owner.
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  bool _googleInitialized = false;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) => _db.collection('users').doc(uid);

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email';
    if (!_emailPattern.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  /// Strong password policy: 8+ chars with upper, lower, digit and symbol.
  static String? validatePassword(String? value) {
    final v = value ?? '';
    if (v.length < 8) return 'Use at least 8 characters';
    if (v.length > 128) return 'Password is too long';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Add an uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Add a lowercase letter';
    if (!RegExp(r'\d').hasMatch(v)) return 'Add a number';
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(v)) return 'Add a symbol';
    return null;
  }

  static String? validateName(String? value) {
    final v = value?.trim() ?? '';
    if (v.length < 2) return 'Enter your name';
    if (v.length > 50) return 'Name is too long';
    return null;
  }

  Future<void> register({required String name, required String email, required String password}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      final user = cred.user!;
      await user.updateDisplayName(name.trim());
      await _saveProfile(user, name: name.trim(), provider: 'password');
      await user.sendEmailVerification();
    } on FirebaseException catch (e) {
      throw AuthFailure(_message(e));
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      await _saveProfile(cred.user!, provider: 'password');
    } on FirebaseException catch (e) {
      throw AuthFailure(_message(e));
    }
  }

  /// Returns false if the user cancelled the Google flow.
  Future<bool> signInWithGoogle() async {
    try {
      UserCredential cred;
      if (kIsWeb) {
        cred = await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        final google = GoogleSignIn.instance;
        if (!_googleInitialized) {
          await google.initialize();
          _googleInitialized = true;
        }
        final account = await google.authenticate();
        final idToken = account.authentication.idToken;
        if (idToken == null) throw const AuthFailure('Google sign-in failed. Please try again.');
        cred = await _auth.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
      }
      await _saveProfile(cred.user!, provider: 'google');
      return true;
    } on GoogleSignInException catch (e) {
      debugPrint('GoogleSignInException: ${e.code} ${e.description}');
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      throw AuthFailure(e.code == GoogleSignInExceptionCode.clientConfigurationError
          ? 'Google sign-in is not configured. Add the SHA-1 key in Firebase.'
          : 'Google sign-in failed. Please try again.');
    } on FirebaseException catch (e) {
      if (e.code == 'popup-closed-by-user' || e.code == 'cancelled-popup-request') return false;
      throw AuthFailure(_message(e));
    }
  }

  /// Always reports success so the UI can't be used to discover registered emails.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') throw AuthFailure(_message(e));
    }
  }

  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(name);
    await _userDoc(user.uid).update({'name': name, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> signOut() async {
    if (!kIsWeb && _googleInitialized) await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  /// Creates the profile on first sign-in, otherwise refreshes login metadata.
  Future<void> _saveProfile(User user, {String? name, required String provider}) async {
    final doc = _userDoc(user.uid);
    final snapshot = await doc.get();
    if (!snapshot.exists) {
      await doc.set({
        'uid': user.uid,
        'name': name ?? user.displayName ?? 'SpendSmart User',
        'email': user.email,
        'photoUrl': user.photoURL,
        'provider': provider,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } else {
      await doc.update({
        'photoUrl': user.photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Generic messages for credential errors avoid revealing whether an account exists.
  String _message(FirebaseException e) {
    debugPrint('FirebaseException [${e.plugin}] ${e.code}: ${e.message}');
    return switch (e.code) {
        'invalid-email' => 'Enter a valid email address.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' => 'Incorrect email or password.',
        'email-already-in-use' => 'Could not create an account with these details.',
        'weak-password' => 'Password is too weak.',
        'user-disabled' => 'This account has been disabled.',
        'too-many-requests' => 'Too many attempts. Please wait and try again.',
        'network-request-failed' => 'Network error. Check your connection.',
        'account-exists-with-different-credential' => 'Sign in with the method you originally used.',
        'operation-not-allowed' => 'This sign-in method is not enabled in Firebase.',
        'permission-denied' => 'Could not save your profile (Firestore rules).',
        'unavailable' || 'not-found' => 'Database unavailable. Is Firestore created?',
        _ => 'Something went wrong (${e.code}). Please try again.',
      };
  }
}
