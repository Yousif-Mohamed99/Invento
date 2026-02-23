abstract class AuthEvent {}

// حدث تسجيل الدخول
class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested(this.email, this.password);
}

// حدث تسجيل تاجر جديد
class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String storeName;
  final String city;
  final String address;

  SignUpRequested({
    required this.email,
    required this.password,
    required this.storeName,
    required this.city,
    required this.address,
  });
}

class LogoutRequested extends AuthEvent {}

class ResetPasswordRequested extends AuthEvent {
  final String email;
  ResetPasswordRequested(this.email);
}

class GoogleSignInRequested extends AuthEvent {}
