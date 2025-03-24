enum AuthResType {
  ntuAuthFail,
  libraryAuthFail,
  invalidToken,
  authOk,
  networkError,
}

class AuthResult {
  final String message;
  final AuthResType type;

  AuthResult({
    this.type = AuthResType.authOk,
    this.message = "No Message Provided",
  });

  @override
  String toString() {
    return "${type.toString().split(".").last}: $message";
  }
}
