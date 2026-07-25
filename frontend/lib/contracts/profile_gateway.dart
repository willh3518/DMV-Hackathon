import 'package:accessibility_frontend/domain/profile/profile_models.dart';

abstract interface class ProfileGateway {
  Future<ProfileLoadResult> loadProfile();

  Future<ProfileSaveResult> saveProfile(ProfileSnapshot draft);

  Future<LegalContentResult> loadLegalDocument(LegalDocumentKind kind);

  Future<SignOutResult> signOut();

  Future<AccountDeletionResult> requestAccountDeletion();

  Future<AccountDeletionResult> loadAccountDeletionStatus();
}
