abstract class Failure {
  final String message;
  Failure(this.message);
}

class ServerFailure extends Failure {
  ServerFailure(super.message);
}

class AuthFailure extends Failure {
  AuthFailure(super.message);
}

class NetworkFailure extends Failure {
  NetworkFailure(super.message);
}

class ValidationFailure extends Failure {
  ValidationFailure(super.message);
}

class PaymentFailure extends Failure {
  PaymentFailure(super.message);
}

class PaymentCancelledFailure extends Failure {
  PaymentCancelledFailure(super.message);
}
