import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';

class GoogleSignInUseCase {
  final AuthRepository repository;

  GoogleSignInUseCase(this.repository);

  Future<UserCredential> call() async {
    return await repository.signInWithGoogle();
  }
}
