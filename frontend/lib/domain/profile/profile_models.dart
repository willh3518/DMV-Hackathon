import 'package:accessibility_frontend/domain/onboarding/onboarding_answers.dart';

enum ProfileSectionId {
  accommodations,
  experiencePreferences,
  travelComfort,
  interests,
  planningSituations,
}

final class ProfileSnapshot {
  const ProfileSnapshot({required this.responses});

  final OnboardingSubmission responses;
}

enum ProfileOperationFailureReason {
  networkUnavailable('We could not connect. Check your connection and retry.'),
  serviceUnavailable('This action is temporarily unavailable. Try again.'),
  unknown('Something interrupted this action. Try again.');

  const ProfileOperationFailureReason(this.userMessage);

  final String userMessage;
}

sealed class ProfileLoadResult {
  const ProfileLoadResult();
}

final class ProfileLoadSuccess extends ProfileLoadResult {
  const ProfileLoadSuccess({required this.profile});

  final ProfileSnapshot profile;
}

final class ProfileLoadFailure extends ProfileLoadResult {
  const ProfileLoadFailure({required this.reason});

  final ProfileOperationFailureReason reason;
}

sealed class ProfileSaveResult {
  const ProfileSaveResult();
}

final class ProfileSaveConfirmed extends ProfileSaveResult {
  const ProfileSaveConfirmed();
}

final class ProfileSaveFailure extends ProfileSaveResult {
  const ProfileSaveFailure({required this.reason});

  final ProfileOperationFailureReason reason;
}

enum LegalDocumentKind { terms, privacy }

final class LegalDocument {
  const LegalDocument({
    required this.kind,
    required this.title,
    required this.body,
    required this.isPlaceholder,
  });

  final LegalDocumentKind kind;
  final String title;
  final String body;
  final bool isPlaceholder;
}

sealed class LegalContentResult {
  const LegalContentResult();
}

final class LegalContentLoaded extends LegalContentResult {
  const LegalContentLoaded({required this.document});

  final LegalDocument document;
}

final class LegalContentUnavailable extends LegalContentResult {
  const LegalContentUnavailable();
}

final class LegalContentFailure extends LegalContentResult {
  const LegalContentFailure({required this.reason});

  final ProfileOperationFailureReason reason;
}

sealed class SignOutResult {
  const SignOutResult();
}

final class SignOutConfirmed extends SignOutResult {
  const SignOutConfirmed();
}

final class SignOutFailure extends SignOutResult {
  const SignOutFailure({required this.reason});

  final ProfileOperationFailureReason reason;
}

sealed class AccountDeletionResult {
  const AccountDeletionResult();
}

final class AccountDeletionSubmitted extends AccountDeletionResult {
  const AccountDeletionSubmitted();
}

final class AccountDeletionPending extends AccountDeletionResult {
  const AccountDeletionPending();
}

final class AccountDeletionConfirmed extends AccountDeletionResult {
  const AccountDeletionConfirmed();
}

final class AccountDeletionFailure extends AccountDeletionResult {
  const AccountDeletionFailure({required this.reason});

  final ProfileOperationFailureReason reason;
}
