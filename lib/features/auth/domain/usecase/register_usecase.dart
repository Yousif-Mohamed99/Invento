import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<UserCredential> call({
    required String email,
    required String password,
    required String storeName,
    required String city,
    required String address,
  }) async {
    return await repository.signUp(
      email: email,
      password: password,
      storeName: storeName,
      city: city,
      address: address,
    );
  }
}
