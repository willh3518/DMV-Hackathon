import 'package:accessibility_frontend/contracts/authentication_gateway.dart';
import 'package:accessibility_frontend/domain/authentication/authentication_models.dart';

/// Non-sensitive record of which authentication path was requested.
final class SyntheticAuthenticationAttempt {
  const SyntheticAuthenticationAttempt({required this.operation});

  final AuthenticationOperation operation;
}

/// Deterministic authentication fixture for frontend development and tests.
///
/// The configured results are returned for every matching operation. Credentials
/// are accepted to satisfy [AuthenticationGateway] and are never retained.
final class SyntheticAuthenticationGateway implements AuthenticationGateway {
  SyntheticAuthenticationGateway({
    this.signUpResult = const AuthenticationSuccess(
      nextStep: StartOnboardingNextStep(),
    ),
    this.signInResult = const AuthenticationSuccess(
      nextStep: OpenChatNextStep(),
    ),
  });

  final AuthenticationResult signUpResult;
  final AuthenticationResult signInResult;
  final List<SyntheticAuthenticationAttempt> _attempts =
      <SyntheticAuthenticationAttempt>[];

  List<SyntheticAuthenticationAttempt> get attempts =>
      List<SyntheticAuthenticationAttempt>.unmodifiable(_attempts);

  @override
  Future<AuthenticationResult> signUp({
    required String email,
    required String password,
  }) async {
    _attempts.add(
      const SyntheticAuthenticationAttempt(
        operation: AuthenticationOperation.signUp,
      ),
    );
    return signUpResult;
  }

  @override
  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  }) async {
    _attempts.add(
      const SyntheticAuthenticationAttempt(
        operation: AuthenticationOperation.signIn,
      ),
    );
    return signInResult;
  }
}
