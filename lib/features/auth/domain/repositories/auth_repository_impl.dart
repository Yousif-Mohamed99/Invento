import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRepositoryImpl({required this.firebaseAuth, required this.firestore});

  @override
  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw "An unexpected error occurred, please try again";
    }
  }

  @override
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String storeName,
    required String city,
  }) async {
    try {
      // 1. Create account in Firebase Auth
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = credential.user!.uid;
      final DateTime now = DateTime.now();
      final DateTime trialExpiry = now.add(const Duration(days: 7));
      await firestore.collection('merchants').doc(uid).set({
        'uid': uid,
        'email': email,
        'storeName': storeName,
        'city': city,
        'createdAt': FieldValue.serverTimestamp(),
        'trialEndsAt': Timestamp.fromDate(trialExpiry),
        'isSubscribed': false,
        'plan': 'starter',
      });

      await credential.user?.updateDisplayName(storeName);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw "Account registration failed, please try again.";
    }
  }

  @override
  Future<void> signOut() async => await firebaseAuth.signOut();

  @override
  Future<User?> getCurrentUser() async => firebaseAuth.currentUser;

  @override
  Future<void> resetPassword(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw "An error occurred while sending the password reset link";
    }
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw "Sign in cancelled";
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user != null) {
        // Check if merchant profile exists
        final doc = await firestore.collection('merchants').doc(user.uid).get();

        if (!doc.exists) {
          final DateTime now = DateTime.now();
          final DateTime trialExpiry = now.add(const Duration(days: 7));

          await firestore.collection('merchants').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'storeName': user.displayName ?? "My Store",
            'city': "Not Specified",
            'createdAt': FieldValue.serverTimestamp(),
            'trialEndsAt': Timestamp.fromDate(trialExpiry),
            'isSubscribed': false,
            'plan': 'starter',
          });
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw "Google sign in failed, please try again.";
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "User not found, please check your email.";
      case 'wrong-password':
        return "Wrong password.";
      case 'email-already-in-use':
        return "Email already in use.";
      case 'network-request-failed':
        return "Network request failed, please try again.";
      case 'invalid-email':
        return "Invalid email format.";
      case 'weak-password':
        return "Password is too weak.";
      default:
        return "Sorry, an error occurred during the login process.";
    }
  }
}
