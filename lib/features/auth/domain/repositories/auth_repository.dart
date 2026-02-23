import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Future<UserCredential> signIn(String email, String password);

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String storeName,
    required String city,
    required String address,
  });

  Future<void> signOut();
  Future<User?> getCurrentUser();
  Future<void> resetPassword(String email);
  Future<UserCredential> signInWithGoogle();
}
