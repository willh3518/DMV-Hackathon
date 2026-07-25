import 'package:accessibility_frontend/domain/authentication/authentication_models.dart';

/// Provider-neutral boundary for the Version 1 sign-up and sign-in screens.
///
/// Implementations must use [email] and [password] only for the in-flight
/// request. They must not log credentials or retain the raw values for request
/// history, diagnostics, fixtures, or analytics.
abstract interface class AuthenticationGateway {
  Future<AuthenticationResult> signUp({
    required String email,
    required String password,
  });

  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  });
}
