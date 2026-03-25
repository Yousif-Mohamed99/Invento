abstract class AuthEvent {}

// Login event
class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested(this.email, this.password);
}

// Register new merchant event
class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String storeName;
  final String city;

  SignUpRequested({
    required this.email,
    required this.password,
    required this.storeName,
    required this.city,
  });
}

class LogoutRequested extends AuthEvent {}

class ResetPasswordRequested extends AuthEvent {
  final String email;
  ResetPasswordRequested(this.email);
}

class GoogleSignInRequested extends AuthEvent {}
