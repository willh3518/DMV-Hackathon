import 'package:accessibility_frontend/contracts/profile_gateway.dart';
import 'package:accessibility_frontend/domain/onboarding/onboarding_answers.dart';
import 'package:accessibility_frontend/domain/profile/profile_models.dart';

typedef LoadProfileCallback = Future<ProfileLoadResult> Function();
typedef SaveProfileCallback =
    Future<ProfileSaveResult> Function(ProfileSnapshot draft);
typedef LoadLegalCallback =
    Future<LegalContentResult> Function(LegalDocumentKind kind);
typedef SignOutCallback = Future<SignOutResult> Function();
typedef DeletionCallback = Future<AccountDeletionResult> Function();

final class TestProfileGateway implements ProfileGateway {
  TestProfileGateway({
    LoadProfileCallback? loadProfile,
    SaveProfileCallback? saveProfile,
    LoadLegalCallback? loadLegal,
    SignOutCallback? signOut,
    DeletionCallback? requestDeletion,
    DeletionCallback? loadDeletionStatus,
  }) : _loadProfile = loadProfile ?? _defaultLoad,
       _saveProfile = saveProfile ?? _defaultSave,
       _loadLegal = loadLegal ?? _defaultLegal,
       _signOut = signOut ?? _defaultSignOut,
       _requestDeletion = requestDeletion ?? _defaultDeletionRequest,
       _loadDeletionStatus = loadDeletionStatus ?? _defaultDeletionStatus;

  final LoadProfileCallback _loadProfile;
  final SaveProfileCallback _saveProfile;
  final LoadLegalCallback _loadLegal;
  final SignOutCallback _signOut;
  final DeletionCallback _requestDeletion;
  final DeletionCallback _loadDeletionStatus;

  int loadCount = 0;
  int saveCount = 0;
  int legalCount = 0;
  int signOutCount = 0;
  int deletionRequestCount = 0;
  int deletionStatusCount = 0;

  @override
  Future<ProfileLoadResult> loadProfile() {
    loadCount += 1;
    return _loadProfile();
  }

  @override
  Future<ProfileSaveResult> saveProfile(ProfileSnapshot draft) {
    saveCount += 1;
    return _saveProfile(draft);
  }

  @override
  Future<LegalContentResult> loadLegalDocument(LegalDocumentKind kind) {
    legalCount += 1;
    return _loadLegal(kind);
  }

  @override
  Future<SignOutResult> signOut() {
    signOutCount += 1;
    return _signOut();
  }

  @override
  Future<AccountDeletionResult> requestAccountDeletion() {
    deletionRequestCount += 1;
    return _requestDeletion();
  }

  @override
  Future<AccountDeletionResult> loadAccountDeletionStatus() {
    deletionStatusCount += 1;
    return _loadDeletionStatus();
  }

  static Future<ProfileLoadResult> _defaultLoad() async {
    return const ProfileLoadSuccess(profile: mixedProfile);
  }

  static Future<ProfileSaveResult> _defaultSave(ProfileSnapshot draft) async {
    return const ProfileSaveConfirmed();
  }

  static Future<LegalContentResult> _defaultLegal(
    LegalDocumentKind kind,
  ) async {
    return LegalContentLoaded(
      document: LegalDocument(
        kind: kind,
        title: kind == LegalDocumentKind.terms ? 'Terms' : 'Privacy',
        body: 'Synthetic placeholder content.',
        isPlaceholder: true,
      ),
    );
  }

  static Future<SignOutResult> _defaultSignOut() async {
    return const SignOutConfirmed();
  }

  static Future<AccountDeletionResult> _defaultDeletionRequest() async {
    return const AccountDeletionSubmitted();
  }

  static Future<AccountDeletionResult> _defaultDeletionStatus() async {
    return const AccountDeletionPending();
  }
}

const ProfileSnapshot mixedProfile = ProfileSnapshot(
  responses: OnboardingSubmission(
    accommodations: AccommodationsDraft(
      options: <AccommodationOption>{
        AccommodationOption.stepFreeAccess,
        AccommodationOption.accessibleRestroom,
      },
    ),
    experiencePreferences: ExperiencePreferencesDraft.skipped(),
    travelComfort: TravelComfortDraft(
      option: TravelComfortOption.custom,
      customValue: '0.5',
      customUnit: TravelCustomUnit.miles,
    ),
    interests: InterestsDraft(
      options: <InterestOption>{InterestOption.museums},
      other: 'Synthetic community art classes',
    ),
    planningSituations: PlanningSituationsDraft.none(),
  ),
);

const ProfileSnapshot editedProfile = ProfileSnapshot(
  responses: OnboardingSubmission(
    accommodations: AccommodationsDraft(
      options: <AccommodationOption>{
        AccommodationOption.stepFreeAccess,
        AccommodationOption.accessibleRestroom,
      },
      other: 'Synthetic seating request',
    ),
    experiencePreferences: ExperiencePreferencesDraft.skipped(),
    travelComfort: TravelComfortDraft(
      option: TravelComfortOption.custom,
      customValue: '0.5',
      customUnit: TravelCustomUnit.miles,
    ),
    interests: InterestsDraft(
      options: <InterestOption>{InterestOption.museums},
      other: 'Synthetic community art classes',
    ),
    planningSituations: PlanningSituationsDraft.none(),
  ),
);
