abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// 400 INVALID_PHONE: the server refused the number itself. [message] is the
/// server's own `error` text, shown under the phone field.
class InvalidPhoneFailure extends Failure {
  const InvalidPhoneFailure(super.message);
}
