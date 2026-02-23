abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String uid;
  AuthSuccess(this.uid);
}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}

/// Emitted when a password-reset email has been sent successfully.
class AuthPasswordResetSuccess extends AuthState {
  final String message;
  AuthPasswordResetSuccess(this.message);
}
