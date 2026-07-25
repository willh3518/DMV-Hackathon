import 'package:accessibility_frontend/contracts/profile_gateway.dart';
import 'package:accessibility_frontend/domain/profile/profile_models.dart';

/// Frontend-only Profile fixture. It records operation counts, not profile data.
final class SyntheticProfileGateway implements ProfileGateway {
  SyntheticProfileGateway({
    required this.loadResult,
    this.saveResult = const ProfileSaveConfirmed(),
    this.termsResult = const LegalContentUnavailable(),
    this.privacyResult = const LegalContentUnavailable(),
    this.signOutResult = const SignOutConfirmed(),
    this.deletionRequestResult = const AccountDeletionSubmitted(),
    this.deletionStatusResult = const AccountDeletionPending(),
  });

  final ProfileLoadResult loadResult;
  final ProfileSaveResult saveResult;
  final LegalContentResult termsResult;
  final LegalContentResult privacyResult;
  final SignOutResult signOutResult;
  final AccountDeletionResult deletionRequestResult;
  final AccountDeletionResult deletionStatusResult;

  int loadCount = 0;
  int saveCount = 0;
  int legalLoadCount = 0;
  int signOutCount = 0;
  int deletionRequestCount = 0;
  int deletionStatusCount = 0;

  @override
  Future<ProfileLoadResult> loadProfile() async {
    loadCount += 1;
    return loadResult;
  }

  @override
  Future<ProfileSaveResult> saveProfile(ProfileSnapshot draft) async {
    saveCount += 1;
    return saveResult;
  }

  @override
  Future<LegalContentResult> loadLegalDocument(LegalDocumentKind kind) async {
    legalLoadCount += 1;
    return switch (kind) {
      LegalDocumentKind.terms => termsResult,
      LegalDocumentKind.privacy => privacyResult,
    };
  }

  @override
  Future<SignOutResult> signOut() async {
    signOutCount += 1;
    return signOutResult;
  }

  @override
  Future<AccountDeletionResult> requestAccountDeletion() async {
    deletionRequestCount += 1;
    return deletionRequestResult;
  }

  @override
  Future<AccountDeletionResult> loadAccountDeletionStatus() async {
    deletionStatusCount += 1;
    return deletionStatusResult;
  }
}
