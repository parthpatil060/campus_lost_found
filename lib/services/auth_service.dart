import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current firebase user
  User? get currentUser => _auth.currentUser;

  // Validate college email domain
  bool isValidCollegeEmail(String email) {
    return email.trim().toLowerCase().endsWith(AppConstants.allowedEmailDomain);
  }

  // Sign Up - creates Firebase Auth + Firestore user doc + sends verification email
  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (!isValidCollegeEmail(email)) {
      throw AuthException(
          'Only @gst.sies.edu.in emails are allowed.',
          'invalid-email-domain');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final user = credential.user!;

    // Update display name
    await user.updateDisplayName(name);

    // Send verification email
    await user.sendEmailVerification();

    // Create Firestore user document
    final userModel = UserModel(
      uid: user.uid,
      name: name,
      email: email.trim().toLowerCase(),
      role: AppConstants.roleUser,
      createdAt: DateTime.now(),
      fcmToken: null,
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(userModel.toFirestore());

    return userModel;
  }

  // Sign In - returns UserModel with role
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final user = credential.user!;

    // Check email verification (skip for admin and verifiers)
    final userDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      throw AuthException('User profile not found.', 'user-not-found');
    }

    final userModel = UserModel.fromFirestore(userDoc);

    // Regular users must verify email
    if (userModel.role == AppConstants.roleUser && !user.emailVerified) {
      throw AuthException(
          'Please verify your email before logging in.',
          'email-not-verified');
    }

    return userModel;
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Reload user to check verification status
  Future<bool> checkEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Get UserModel from Firestore by uid
  Future<UserModel?> getUserModel(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // Admin: Create verifier account
  Future<UserModel?> createVerifier({
    required String name,
    required String email,
    required String password,
  }) async {
    // Create auth account via secondary app instance approach
    // In production, this should use a Cloud Function to avoid signing out current admin
    // For now, using Admin SDK pattern as Firebase CLI callable function
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final user = credential.user!;

    final verifierModel = UserModel(
      uid: user.uid,
      name: name,
      email: email.trim().toLowerCase(),
      role: AppConstants.roleVerifier,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(verifierModel.toFirestore());

    return verifierModel;
  }

  // Admin: Delete verifier
  Future<void> deleteVerifier(String uid) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .delete();
    // Note: Deleting Firebase Auth account requires Admin SDK (Cloud Function)
  }

  // Get all verifiers
  Stream<List<UserModel>> getVerifiers() {
    return _firestore
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: AppConstants.roleVerifier)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }
}

class AuthException implements Exception {
  final String message;
  final String code;
  AuthException(this.message, this.code);

  @override
  String toString() => message;
}
