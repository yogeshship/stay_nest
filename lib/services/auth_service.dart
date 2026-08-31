import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  Future<void> reauthenticateWithPassword(String currentPassword) async {
    final user = _firebaseAuth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.trim().isEmpty) {
      throw StateError('A signed-in email account is required.');
    }
    if (currentPassword.isEmpty) {
      throw ArgumentError('Enter your current password.');
    }
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: currentPassword),
    );
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    validateNewPassword(newPassword);
    await reauthenticateWithPassword(currentPassword);
    await user.updatePassword(newPassword);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final trimmed = email.trim();
    if (!isPlausibleEmail(trimmed)) {
      throw ArgumentError('Enter a valid email address.');
    }
    await _firebaseAuth.sendPasswordResetEmail(email: trimmed);
  }

  Future<void> deleteCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    await user.delete();
  }
}

String friendlyAuthError(FirebaseAuthException error) {
  return switch (error.code) {
    'invalid-email' => 'Please enter a valid email address.',
    'weak-password' => 'Please choose a password with at least 6 characters.',
    'email-already-in-use' =>
      'An account already exists for this email. Try logging in instead.',
    'invalid-credential' =>
      'The current password could not be verified. Please try again.',
    'user-not-found' =>
      'This account could not be found. Please sign in again.',
    'wrong-password' => 'The current password is incorrect. Please try again.',
    'requires-recent-login' =>
      'For security, please sign in again before changing your password.',
    'user-disabled' =>
      'This account has been disabled. Please contact StayNest support.',
    'too-many-requests' =>
      'Too many attempts. Please wait a moment and try again.',
    'network-request-failed' =>
      'Could not connect. Please check your internet connection and try again.',
    'operation-not-allowed' =>
      'Email login is not available right now. Please contact StayNest support.',
    _ => 'Authentication failed. Please try again.',
  };
}

String friendlyLoginAuthError(FirebaseAuthException error) {
  if (error.code == 'invalid-credential' ||
      error.code == 'wrong-password' ||
      error.code == 'user-not-found') {
    return 'The email or password is incorrect. Please try again.';
  }
  return friendlyAuthError(error);
}

String friendlyPasswordChangeAuthError(FirebaseAuthException error) =>
    friendlyAuthError(error);

String friendlyPasswordResetAuthError(FirebaseAuthException error) {
  if (error.code == 'user-not-found') {
    return 'If an account exists for that email, password reset instructions have been sent.';
  }
  return friendlyAuthError(error);
}

void validateNewPassword(String value) {
  if (value.length < 6) {
    throw ArgumentError('Password must be at least 6 characters.');
  }
}

bool isPlausibleEmail(String value) =>
    value.length <= 320 &&
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
