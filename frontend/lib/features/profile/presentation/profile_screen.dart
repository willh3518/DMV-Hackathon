import 'package:accessibility_frontend/contracts/profile_gateway.dart';
import 'package:accessibility_frontend/design_system/app_colors.dart';
import 'package:accessibility_frontend/design_system/components/section_surface.dart';
import 'package:accessibility_frontend/domain/onboarding/onboarding_answers.dart';
import 'package:accessibility_frontend/domain/profile/profile_models.dart';
import 'package:accessibility_frontend/features/profile/presentation/delete_account_dialog.dart';
import 'package:flutter/material.dart';

typedef ProfileSectionEditor =
    Future<ProfileSnapshot?> Function(
      ProfileSectionId section,
      ProfileSnapshot currentDraft,
    );

/// Profile presentation with provider-neutral loading, save, and account states.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.gateway,
    required this.onEditSection,
    required this.onOpenLegal,
    required this.onSignedOut,
    required this.onAccountDeleted,
    this.headingFocusNode,
    this.requestInitialHeadingFocus = true,
    super.key,
  });

  static const Key headingKey = Key('profile_heading');
  static const Key loadingKey = Key('profile_loading');
  static const Key loadErrorKey = Key('profile_load_error');
  static const Key retryLoadButtonKey = Key('profile_retry_load');
  static const Key saveButtonKey = Key('profile_save');
  static const Key saveStatusKey = Key('profile_save_status');
  static const Key termsButtonKey = Key('profile_terms');
  static const Key privacyButtonKey = Key('profile_privacy');
  static const Key signOutButtonKey = Key('profile_sign_out');
  static const Key signOutStatusKey = Key('profile_sign_out_status');
  static const Key deleteAccountButtonKey = Key('profile_delete_account');
  static const Key scrollViewKey = Key('profile_scroll_view');

  static Key sectionKey(ProfileSectionId section) =>
      ValueKey<String>('profile_section_${section.name}');

  static Key editSectionKey(ProfileSectionId section) =>
      ValueKey<String>('profile_edit_${section.name}');

  final ProfileGateway gateway;
  final ProfileSectionEditor onEditSection;
  final ValueChanged<LegalDocumentKind> onOpenLegal;
  final VoidCallback onSignedOut;
  final VoidCallback onAccountDeleted;
  final FocusNode? headingFocusNode;
  final bool requestInitialHeadingFocus;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late FocusNode _headingFocusNode;
  late bool _ownsHeadingFocusNode;
  final FocusNode _loadErrorFocusNode = FocusNode(
    debugLabel: 'Profile load error',
  );
  final FocusNode _saveStatusFocusNode = FocusNode(
    debugLabel: 'Profile save status',
  );
  final FocusNode _signOutStatusFocusNode = FocusNode(
    debugLabel: 'Profile sign out status',
  );

  ProfileSnapshot? _draft;
  ProfileOperationFailureReason? _loadFailure;
  ProfileOperationFailureReason? _saveFailure;
  ProfileOperationFailureReason? _signOutFailure;
  bool _loading = true;
  bool _dirty = false;
  bool _saving = false;
  bool _saveConfirmed = false;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _setHeadingFocusNode(widget.headingFocusNode);
    if (widget.requestInitialHeadingFocus) {
      _requestFocus(_headingFocusNode);
    }
    _loadProfile();
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.headingFocusNode != widget.headingFocusNode) {
      if (_ownsHeadingFocusNode) {
        _headingFocusNode.dispose();
      }
      _setHeadingFocusNode(widget.headingFocusNode);
    }
  }

  @override
  void dispose() {
    if (_ownsHeadingFocusNode) {
      _headingFocusNode.dispose();
    }
    _loadErrorFocusNode.dispose();
    _saveStatusFocusNode.dispose();
    _signOutStatusFocusNode.dispose();
    super.dispose();
  }

  void _setHeadingFocusNode(FocusNode? suppliedFocusNode) {
    _ownsHeadingFocusNode = suppliedFocusNode == null;
    _headingFocusNode =
        suppliedFocusNode ?? FocusNode(debugLabel: 'Profile heading');
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _loadFailure = null;
    });

    ProfileLoadResult result;
    try {
      result = await widget.gateway.loadProfile();
    } catch (_) {
      result = const ProfileLoadFailure(
        reason: ProfileOperationFailureReason.unknown,
      );
    }
    if (!mounted) {
      return;
    }

    switch (result) {
      case ProfileLoadSuccess success:
        setState(() {
          _draft = success.profile;
          _loading = false;
          _dirty = false;
          _saveFailure = null;
          _saveConfirmed = false;
        });
      case ProfileLoadFailure failure:
        setState(() {
          _draft = null;
          _loading = false;
          _loadFailure = failure.reason;
        });
        _requestFocus(_loadErrorFocusNode);
    }
  }

  Future<void> _editSection(ProfileSectionId section) async {
    final ProfileSnapshot? currentDraft = _draft;
    if (currentDraft == null || _saving || _signingOut) {
      return;
    }

    final ProfileSnapshot? updated = await widget.onEditSection(
      section,
      currentDraft,
    );
    if (!mounted || updated == null) {
      return;
    }

    setState(() {
      _draft = updated;
      _dirty = true;
      _saveFailure = null;
      _saveConfirmed = false;
    });
  }

  Future<void> _saveProfile() async {
    final ProfileSnapshot? currentDraft = _draft;
    if (currentDraft == null || !_dirty || _saving) {
      return;
    }

    setState(() {
      _saving = true;
      _saveFailure = null;
      _saveConfirmed = false;
    });

    ProfileSaveResult result;
    try {
      result = await widget.gateway.saveProfile(currentDraft);
    } catch (_) {
      result = const ProfileSaveFailure(
        reason: ProfileOperationFailureReason.unknown,
      );
    }
    if (!mounted) {
      return;
    }

    switch (result) {
      case ProfileSaveConfirmed():
        setState(() {
          _saving = false;
          _dirty = false;
          _saveConfirmed = true;
        });
      case ProfileSaveFailure failure:
        setState(() {
          _saving = false;
          _saveFailure = failure.reason;
        });
    }
    _requestFocus(_saveStatusFocusNode);
  }

  Future<void> _signOut() async {
    if (_signingOut) {
      return;
    }

    setState(() {
      _signingOut = true;
      _signOutFailure = null;
    });

    SignOutResult result;
    try {
      result = await widget.gateway.signOut();
    } catch (_) {
      result = const SignOutFailure(
        reason: ProfileOperationFailureReason.unknown,
      );
    }
    if (!mounted) {
      return;
    }

    switch (result) {
      case SignOutConfirmed():
        setState(() => _signingOut = false);
        widget.onSignedOut();
      case SignOutFailure failure:
        setState(() {
          _signingOut = false;
          _signOutFailure = failure.reason;
        });
        _requestFocus(_signOutStatusFocusNode);
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return DeleteAccountDialog(
          gateway: widget.gateway,
          onDeletionConfirmed: widget.onAccountDeleted,
        );
      },
    );
  }

  void _requestFocus(FocusNode focusNode) {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted && focusNode.canRequestFocus) {
        focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[AppColors.canvasTop, AppColors.canvasBottom],
        ),
      ),
      child: SafeArea(
        child: FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          key: ProfileScreen.scrollViewKey,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Focus(
                key: ProfileScreen.headingKey,
                focusNode: _headingFocusNode,
                skipTraversal: true,
                child: Semantics(
                  header: true,
                  child: Text(
                    'Your profile',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Review what helps a place work for you. You can update these '
                'optional responses anytime.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 26),
              if (_loading)
                _buildLoading(context)
              else if (_loadFailure
                  case final ProfileOperationFailureReason reason)
                _buildLoadFailure(context, reason)
              else if (_draft case final ProfileSnapshot draft)
                _buildLoaded(context, draft),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Semantics(
      key: ProfileScreen.loadingKey,
      container: true,
      liveRegion: true,
      label: 'Loading your profile.',
      child: ExcludeSemantics(
        child: SectionSurface(
          child: Row(
            children: <Widget>[
              const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Loading your profile…',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadFailure(
    BuildContext context,
    ProfileOperationFailureReason reason,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Focus(
          focusNode: _loadErrorFocusNode,
          skipTraversal: true,
          child: Semantics(
            key: ProfileScreen.loadErrorKey,
            container: true,
            liveRegion: true,
            label: 'Profile did not load. ${reason.userMessage} Retry.',
            onTap: _loadProfile,
            child: ExcludeSemantics(
              child: SectionSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Your profile did not load',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(reason.userMessage),
                    const SizedBox(height: 18),
                    FilledButton(
                      key: ProfileScreen.retryLoadButtonKey,
                      onPressed: _loadProfile,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),
        _buildAccountSection(context),
      ],
    );
  }

  Widget _buildLoaded(BuildContext context, ProfileSnapshot draft) {
    final List<_ProfileSectionContent> sections = _sectionContents(
      draft.responses,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int index = 0; index < sections.length; index += 1) ...<Widget>[
          if (index > 0) const SizedBox(height: 16),
          _ProfileSectionCard(
            key: ProfileScreen.sectionKey(sections[index].section),
            content: sections[index],
            enabled: !_saving && !_signingOut,
            onEdit: () => _editSection(sections[index].section),
          ),
        ],
        const SizedBox(height: 20),
        if (_saving || _saveFailure != null || _saveConfirmed)
          _buildSaveStatus(context),
        if (_saving || _saveFailure != null || _saveConfirmed)
          const SizedBox(height: 14),
        FilledButton(
          key: ProfileScreen.saveButtonKey,
          onPressed: _dirty && !_saving && !_signingOut ? _saveProfile : null,
          child: Text(
            _saving
                ? 'Saving changes'
                : _saveFailure != null
                ? 'Retry save'
                : 'Save changes',
          ),
        ),
        const SizedBox(height: 26),
        _buildAccountSection(context),
      ],
    );
  }

  Widget _buildSaveStatus(BuildContext context) {
    late final String label;
    late final IconData icon;
    if (_saving) {
      label = 'Saving your profile changes.';
      icon = Icons.hourglass_top_rounded;
    } else if (_saveFailure case final ProfileOperationFailureReason reason) {
      label = 'Profile changes were not saved. ${reason.userMessage}';
      icon = Icons.error_outline_rounded;
    } else {
      label = 'Profile changes saved.';
      icon = Icons.check_circle_rounded;
    }

    return Focus(
      focusNode: _saveStatusFocusNode,
      skipTraversal: true,
      child: Semantics(
        key: ProfileScreen.saveStatusKey,
        container: true,
        liveRegion: true,
        label: label,
        child: ExcludeSemantics(
          child: _InlineStatus(
            icon: icon,
            message: label,
            isError: _saveFailure != null,
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Semantics(
      container: true,
      child: SectionSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                'Account and legal',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Legal content remains clearly marked until approved content is '
              'supplied.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            _AccountActionButton(
              key: ProfileScreen.termsButtonKey,
              icon: Icons.description_outlined,
              label: 'Terms',
              onPressed: _signingOut
                  ? null
                  : () => widget.onOpenLegal(LegalDocumentKind.terms),
            ),
            const SizedBox(height: 8),
            _AccountActionButton(
              key: ProfileScreen.privacyButtonKey,
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy',
              onPressed: _signingOut
                  ? null
                  : () => widget.onOpenLegal(LegalDocumentKind.privacy),
            ),
            const SizedBox(height: 8),
            _AccountActionButton(
              key: ProfileScreen.signOutButtonKey,
              icon: Icons.logout_rounded,
              label: _signingOut
                  ? 'Signing out'
                  : _signOutFailure != null
                  ? 'Retry sign out'
                  : 'Sign out',
              onPressed: _signingOut ? null : _signOut,
            ),
            if (_signingOut || _signOutFailure != null) ...<Widget>[
              const SizedBox(height: 10),
              Focus(
                focusNode: _signOutStatusFocusNode,
                skipTraversal: true,
                child: Semantics(
                  key: ProfileScreen.signOutStatusKey,
                  liveRegion: true,
                  label: _signingOut
                      ? 'Signing out. Please wait.'
                      : 'Sign out was not confirmed. '
                            '${_signOutFailure!.userMessage}',
                  child: ExcludeSemantics(
                    child: Text(
                      _signingOut
                          ? 'Signing out…'
                          : 'Sign out was not confirmed. '
                                '${_signOutFailure!.userMessage}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: ProfileScreen.deleteAccountButtonKey,
              onPressed: _signingOut ? null : _showDeleteAccountDialog,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 52),
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({
    required this.content,
    required this.enabled,
    required this.onEdit,
    super.key,
  });

  final _ProfileSectionContent content;
  final bool enabled;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: SectionSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                content.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 10),
            for (int index = 0; index < content.lines.length; index += 1) ...[
              if (index > 0) const SizedBox(height: 6),
              Text(
                content.lines[index],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: ProfileScreen.editSectionKey(content.section),
                onPressed: enabled ? onEdit : null,
                icon: const Icon(Icons.edit_outlined),
                label: Text('Edit ${content.editLabel}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountActionButton extends StatelessWidget {
  const _AccountActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 52),
        alignment: Alignment.centerLeft,
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _InlineStatus extends StatelessWidget {
  const _InlineStatus({
    required this.icon,
    required this.message,
    required this.isError,
  });

  final IconData icon;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isError
            ? Theme.of(context).colorScheme.errorContainer
            : AppColors.surfaceBlue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBlueStrong),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

final class _ProfileSectionContent {
  const _ProfileSectionContent({
    required this.section,
    required this.title,
    required this.editLabel,
    required this.lines,
  });

  final ProfileSectionId section;
  final String title;
  final String editLabel;
  final List<String> lines;
}

List<_ProfileSectionContent> _sectionContents(OnboardingSubmission responses) {
  return <_ProfileSectionContent>[
    _ProfileSectionContent(
      section: ProfileSectionId.accommodations,
      title: 'Accommodations',
      editLabel: 'accommodations',
      lines: _accommodationLines(responses.accommodations),
    ),
    _ProfileSectionContent(
      section: ProfileSectionId.experiencePreferences,
      title: 'Food, service, and environment',
      editLabel: 'food, service, and environment',
      lines: _experienceLines(responses.experiencePreferences),
    ),
    _ProfileSectionContent(
      section: ProfileSectionId.travelComfort,
      title: 'Travel comfort',
      editLabel: 'travel comfort',
      lines: _travelLines(responses.travelComfort),
    ),
    _ProfileSectionContent(
      section: ProfileSectionId.interests,
      title: 'Interests',
      editLabel: 'interests',
      lines: _interestLines(responses.interests),
    ),
    _ProfileSectionContent(
      section: ProfileSectionId.planningSituations,
      title: 'Situations to plan around',
      editLabel: 'situations to plan around',
      lines: _planningSituationLines(responses.planningSituations),
    ),
  ];
}

List<String> _accommodationLines(AccommodationsDraft draft) {
  if (draft.skipped) {
    return const <String>['Skipped'];
  }
  if (!draft.hasAnswer) {
    return const <String>['Not answered'];
  }
  return <String>[
    for (final AccommodationOption option in AccommodationOption.values)
      if (draft.options.contains(option)) _accommodationLabels[option]!,
    if (draft.other.trim().isNotEmpty) 'Something else: ${draft.other.trim()}',
  ];
}

List<String> _experienceLines(ExperiencePreferencesDraft draft) {
  if (draft.skipped) {
    return const <String>['Skipped'];
  }
  if (!draft.hasAnswer) {
    return const <String>['Not answered'];
  }
  return <String>[
    for (final FoodPreference option in FoodPreference.values)
      if (draft.food.contains(option))
        'Food preference: ${_foodLabels[option]}',
    for (final DietaryRequirement option in DietaryRequirement.values)
      if (draft.dietaryRequirements.contains(option))
        'Dietary requirement: ${_dietaryLabels[option]}',
    for (final ExperiencePreference option in ExperiencePreference.values)
      if (draft.experience.contains(option))
        'Experience preference: ${_experienceLabels[option]}',
    if (draft.otherDietaryRequirement.trim().isNotEmpty)
      'Dietary requirement: ${draft.otherDietaryRequirement.trim()}',
  ];
}

List<String> _travelLines(TravelComfortDraft draft) {
  if (draft.skipped) {
    return const <String>['Skipped'];
  }
  final TravelComfortOption? option = draft.option;
  if (option == null) {
    return const <String>['Not answered'];
  }
  if (option == TravelComfortOption.custom) {
    if (!draft.hasValidCustomAnswer) {
      return const <String>['Custom travel response is incomplete'];
    }
    final String unit = switch (draft.customUnit!) {
      TravelCustomUnit.minutes => 'minutes',
      TravelCustomUnit.miles => 'miles',
    };
    return <String>['${draft.customValue.trim()} $unit'];
  }
  return <String>[_travelLabels[option]!];
}

List<String> _interestLines(InterestsDraft draft) {
  if (draft.skipped) {
    return const <String>['Skipped'];
  }
  if (!draft.hasAnswer) {
    return const <String>['Not answered'];
  }
  return <String>[
    for (final InterestOption option in InterestOption.values)
      if (draft.options.contains(option)) _interestLabels[option]!,
    if (draft.other.trim().isNotEmpty) 'Something else: ${draft.other.trim()}',
  ];
}

List<String> _planningSituationLines(PlanningSituationsDraft draft) {
  if (draft.skipped) {
    return const <String>['Skipped'];
  }
  if (draft.noneApply) {
    return const <String>['None'];
  }
  if (!draft.hasAnswer) {
    return const <String>['Not answered'];
  }
  return <String>[
    for (final PlanningSituation situation in PlanningSituation.values)
      if (draft.situations.contains(situation)) _planningLabels[situation]!,
    if (draft.other.trim().isNotEmpty) 'Something else: ${draft.other.trim()}',
  ];
}

const Map<AccommodationOption, String> _accommodationLabels =
    <AccommodationOption, String>{
      AccommodationOption.stepFreeAccess: 'Step-free access',
      AccommodationOption.wheelchairAccessibleSpaces:
          'Wheelchair-accessible spaces',
      AccommodationOption.accessibleRestroom: 'Accessible restroom',
      AccommodationOption.accessibleParking: 'Accessible parking',
      AccommodationOption.seatingAccommodation: 'Seating accommodation',
      AccommodationOption.lowVisionSupport: 'Low-vision support',
      AccommodationOption.hearingOrCommunicationSupport:
          'Hearing or communication support',
      AccommodationOption.serviceAnimalAccess: 'Service-animal access',
      AccommodationOption.staffAssistance: 'Staff assistance',
    };

const Map<FoodPreference, String> _foodLabels = <FoodPreference, String>{
  FoodPreference.italian: 'Italian',
  FoodPreference.mexican: 'Mexican',
  FoodPreference.american: 'American',
  FoodPreference.mediterranean: 'Mediterranean',
  FoodPreference.eastAsian: 'East Asian',
  FoodPreference.southAsian: 'South Asian',
  FoodPreference.cafesAndBakeries: 'Cafés and bakeries',
};

const Map<DietaryRequirement, String> _dietaryLabels =
    <DietaryRequirement, String>{
      DietaryRequirement.vegetarian: 'Vegetarian',
      DietaryRequirement.vegan: 'Vegan',
      DietaryRequirement.glutenFree: 'Gluten-free',
      DietaryRequirement.halal: 'Halal',
      DietaryRequirement.kosher: 'Kosher',
      DietaryRequirement.allergyDiscussionNeeded: 'Allergy discussion needed',
    };

const Map<ExperiencePreference, String> _experienceLabels =
    <ExperiencePreference, String>{
      ExperiencePreference.tableService: 'Table service',
      ExperiencePreference.counterService: 'Counter service',
      ExperiencePreference.quieterEnvironment: 'Quieter environment',
      ExperiencePreference.patientStaff: 'Patient staff',
      ExperiencePreference.simpleExplanations: 'Simple explanations',
      ExperiencePreference.detailedExplanations: 'Detailed explanations',
      ExperiencePreference.digitalMenu: 'Digital menu',
      ExperiencePreference.largeTextMenu: 'Large-text menu',
      ExperiencePreference.softerLighting: 'Softer lighting',
      ExperiencePreference.brighterLighting: 'Brighter lighting',
      ExperiencePreference.lowerCrowds: 'Lower crowds',
    };

const Map<TravelComfortOption, String> _travelLabels =
    <TravelComfortOption, String>{
      TravelComfortOption.fewMinutes: 'A few minutes',
      TravelComfortOption.quarterMile: 'About ¼ mile',
      TravelComfortOption.halfMile: 'About ½ mile',
      TravelComfortOption.oneMile: 'About 1 mile',
      TravelComfortOption.moreThanOneMile: 'More than 1 mile',
      TravelComfortOption.depends: 'It depends',
      TravelComfortOption.noDistanceRestriction: 'No distance restriction',
      TravelComfortOption.custom: 'Custom',
    };

const Map<InterestOption, String> _interestLabels = <InterestOption, String>{
  InterestOption.restaurantsAndCafes: 'Restaurants and cafés',
  InterestOption.museums: 'Museums',
  InterestOption.parksAndNature: 'Parks and nature',
  InterestOption.shopping: 'Shopping',
  InterestOption.liveMusic: 'Live music',
  InterestOption.moviesAndTheater: 'Movies and theater',
  InterestOption.sports: 'Sports',
  InterestOption.games: 'Games',
  InterestOption.artsAndCrafts: 'Arts and crafts',
  InterestOption.socialActivities: 'Social activities',
  InterestOption.familyActivities: 'Family activities',
};

const Map<PlanningSituation, String>
_planningLabels = <PlanningSituation, String>{
  PlanningSituation.stairs: 'Stairs',
  PlanningSituation.longPeriodsOfStanding: 'Long periods of standing',
  PlanningSituation.narrowOrCrowdedSpaces: 'Narrow or crowded spaces',
  PlanningSituation.loudEnvironments: 'Loud environments',
  PlanningSituation.flashingOrIntenseLighting: 'Flashing or intense lighting',
  PlanningSituation.longTravelDistances: 'Long travel distances',
  PlanningSituation.complexInstructions: 'Complex instructions',
  PlanningSituation.unexpectedPhysicalContact: 'Unexpected physical contact',
  PlanningSituation.largeCrowds: 'Large crowds',
  PlanningSituation.limitedRestroomAccess: 'Limited restroom access',
};
