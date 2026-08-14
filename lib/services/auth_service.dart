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
}

String friendlyAuthError(FirebaseAuthException error) {
  return switch (error.code) {
    'invalid-email' => 'Please enter a valid email address.',
    'weak-password' => 'Please choose a password with at least 6 characters.',
    'email-already-in-use' =>
      'An account already exists for this email. Try logging in instead.',
    'invalid-credential' ||
    'user-not-found' ||
    'wrong-password' =>
      'The email or password is incorrect. Please try again.',
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
