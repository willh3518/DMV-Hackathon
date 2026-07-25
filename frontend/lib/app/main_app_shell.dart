import 'package:accessibility_frontend/contracts/discovery_gateway.dart';
import 'package:accessibility_frontend/contracts/external_action_launcher.dart';
import 'package:accessibility_frontend/contracts/place_detail_gateway.dart';
import 'package:accessibility_frontend/contracts/profile_gateway.dart';
import 'package:accessibility_frontend/app/profile_section_editor_route.dart';
import 'package:accessibility_frontend/design_system/app_colors.dart';
import 'package:accessibility_frontend/domain/chat/chat_models.dart';
import 'package:accessibility_frontend/domain/discovery/recommendation_models.dart';
import 'package:accessibility_frontend/domain/profile/profile_models.dart';
import 'package:accessibility_frontend/features/chat/presentation/chat_screen.dart';
import 'package:accessibility_frontend/features/profile/presentation/legal_document_screen.dart';
import 'package:accessibility_frontend/features/profile/presentation/profile_screen.dart';
import 'package:accessibility_frontend/features/recommendations/presentation/recommendation_results_section.dart';
import 'package:accessibility_frontend/fixtures/synthetic_discovery_gateway.dart';
import 'package:accessibility_frontend/fixtures/synthetic_external_action_launcher.dart';
import 'package:accessibility_frontend/fixtures/synthetic_place_detail_gateway.dart';
import 'package:accessibility_frontend/fixtures/synthetic_profile_gateway.dart';
import 'package:accessibility_frontend/fixtures/synthetic_recommendation_fixtures.dart';
import 'package:flutter/material.dart';

/// The two-destination MVP shell shown after onboarding or sign-in.
///
/// All data is synthetic in this frontend build. The gateway boundaries keep
/// the UI ready for a real service without implying that matching is live.
class MainAppShell extends StatefulWidget {
  const MainAppShell({
    required this.onExitToLanding,
    this.initialProfile,
    this.discoveryGateway,
    this.profileGateway,
    this.placeDetailGateway,
    this.externalActionLauncher,
    super.key,
  });

  static const Key navigationBarKey = Key('main_navigation_bar');
  static const Key chatDestinationKey = Key('main_destination_chat');
  static const Key profileDestinationKey = Key('main_destination_profile');

  final VoidCallback onExitToLanding;
  final ProfileSnapshot? initialProfile;
  final DiscoveryGateway? discoveryGateway;
  final ProfileGateway? profileGateway;
  final PlaceDetailGateway? placeDetailGateway;
  final ExternalActionLauncher? externalActionLauncher;

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  late final FocusNode _chatHeadingFocusNode;
  late final FocusNode _profileHeadingFocusNode;
  late final DiscoveryGateway _discoveryGateway;
  late final ProfileGateway _profileGateway;
  late final PlaceDetailGateway _placeDetailGateway;
  late final ExternalActionLauncher _externalActionLauncher;
  int _selectedIndex = 0;
  bool _sessionExpired = false;

  @override
  void initState() {
    super.initState();
    _chatHeadingFocusNode = FocusNode(debugLabel: 'Main chat heading');
    _profileHeadingFocusNode = FocusNode(debugLabel: 'Main profile heading');
    _discoveryGateway =
        widget.discoveryGateway ??
        SyntheticDiscoveryGateway(
          results: const <DiscoveryResult>[
            DiscoveryResults(
              conversationId: 'synthetic-conversation',
              message:
                  'Here are two example places matched to this sample profile.',
              payload: RecommendationResultsPayload(
                recommendations: <RecommendationSummary>[
                  SyntheticRecommendationFixtures.restaurant,
                  SyntheticRecommendationFixtures.activity,
                ],
                announcementLabel:
                    'Two example recommendations are ready to review.',
              ),
            ),
          ],
        );
    _profileGateway =
        widget.profileGateway ?? _buildProfileGateway(widget.initialProfile);
    _placeDetailGateway =
        widget.placeDetailGateway ??
        SyntheticPlaceDetailGateway.byId(
          results: const <String, PlaceDetailResult>{
            'restaurant-1': PlaceDetailSuccess(
              detail: SyntheticRecommendationFixtures.restaurantDetail,
            ),
            'activity-1': PlaceDetailSuccess(
              detail: SyntheticRecommendationFixtures.activityDetail,
            ),
          },
        );
    _externalActionLauncher =
        widget.externalActionLauncher ?? SyntheticExternalActionLauncher();
  }

  @override
  void dispose() {
    _chatHeadingFocusNode.dispose();
    _profileHeadingFocusNode.dispose();
    super.dispose();
  }

  void _selectDestination(int index) {
    if (index == _selectedIndex || (_sessionExpired && index == 1)) {
      return;
    }
    setState(() => _selectedIndex = index);
    final FocusNode destinationHeading = index == 0
        ? _chatHeadingFocusNode
        : _profileHeadingFocusNode;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted && destinationHeading.canRequestFocus) {
        destinationHeading.requestFocus();
      }
    });
  }

  void _handleSessionExpired() {
    if (_sessionExpired) {
      return;
    }
    Navigator.of(
      context,
      rootNavigator: true,
    ).popUntil((Route<dynamic> route) => route.isFirst);
    setState(() {
      _sessionExpired = true;
      _selectedIndex = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted && _chatHeadingFocusNode.canRequestFocus) {
        _chatHeadingFocusNode.requestFocus();
      }
    });
  }

  void _showLocationStatus() {
    _showMessage(
      'Location selection is represented by Washington, DC in this '
      'frontend build.',
    );
  }

  Future<ProfileSnapshot?> _editProfileSection(
    ProfileSectionId section,
    ProfileSnapshot current,
  ) async {
    return Navigator.of(context).push<ProfileSnapshot>(
      MaterialPageRoute<ProfileSnapshot>(
        settings: RouteSettings(name: 'edit_profile_${section.name}'),
        builder: (BuildContext routeContext) {
          return ProfileSectionEditorRoute(
            section: section,
            profile: current,
            onCancel: () => Navigator.of(routeContext).pop<ProfileSnapshot>(),
            onSave: (ProfileSnapshot updated) {
              Navigator.of(routeContext).pop<ProfileSnapshot>(updated);
            },
          );
        },
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openLegalDocument(LegalDocumentKind kind) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: 'legal_${kind.name}'),
        builder: (BuildContext routeContext) {
          return Scaffold(
            body: LegalDocumentScreen(
              gateway: _profileGateway,
              kind: kind,
              onBack: () => Navigator.of(routeContext).pop<void>(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResults(BuildContext context, DiscoveryResultsPayload payload) {
    if (payload is! RecommendationResultsPayload) {
      return const SizedBox.shrink();
    }
    return RecommendationResultsSection(
      recommendations: payload.recommendations,
      placeDetailGateway: _placeDetailGateway,
      externalActionLauncher: _externalActionLauncher,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool largeText = MediaQuery.textScalerOf(context).scale(1) >= 2;
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: <Widget>[
          ChatScreen(
            gateway: _discoveryGateway,
            suggestedPrompts: const <ChatSuggestedPrompt>[
              ChatSuggestedPrompt(
                id: 'quiet-italian',
                label: 'A quiet Italian restaurant with step-free access',
                requestText:
                    'Find a quiet Italian restaurant nearby with step-free '
                    'access.',
              ),
              ChatSuggestedPrompt(
                id: 'accessible-activity',
                label: 'An accessible activity with helpful staff',
                requestText:
                    'Find an accessible activity nearby with helpful staff.',
              ),
            ],
            location: const ChatLocationSummary(label: 'Washington, DC'),
            headingFocusNode: _chatHeadingFocusNode,
            resultsBuilder: _buildResults,
            onLocationSupport: _showLocationStatus,
            onSessionExpired: _handleSessionExpired,
            onReauthenticate: widget.onExitToLanding,
          ),
          ProfileScreen(
            gateway: _profileGateway,
            headingFocusNode: _profileHeadingFocusNode,
            requestInitialHeadingFocus: false,
            onEditSection: _editProfileSection,
            onOpenLegal: _openLegalDocument,
            onSignedOut: widget.onExitToLanding,
            onAccountDeleted: widget.onExitToLanding,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        key: MainAppShell.navigationBarKey,
        height: largeText ? 132 : 80,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.surfaceBlueStrong,
        destinations: <NavigationDestination>[
          const NavigationDestination(
            key: MainAppShell.chatDestinationKey,
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
          NavigationDestination(
            key: MainAppShell.profileDestinationKey,
            enabled: !_sessionExpired,
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

SyntheticProfileGateway _buildProfileGateway(ProfileSnapshot? initialProfile) {
  return SyntheticProfileGateway(
    loadResult: initialProfile == null
        ? const ProfileLoadFailure(
            reason: ProfileOperationFailureReason.serviceUnavailable,
          )
        : ProfileLoadSuccess(profile: initialProfile),
    termsResult: const LegalContentLoaded(
      document: LegalDocument(
        kind: LegalDocumentKind.terms,
        title: 'Terms',
        body:
            'Approved terms have not been supplied for this hackathon '
            'prototype.',
        isPlaceholder: true,
      ),
    ),
    privacyResult: const LegalContentLoaded(
      document: LegalDocument(
        kind: LegalDocumentKind.privacy,
        title: 'Privacy',
        body:
            'Approved privacy language has not been supplied for this '
            'hackathon prototype.',
        isPlaceholder: true,
      ),
    ),
    deletionRequestResult: const AccountDeletionFailure(
      reason: ProfileOperationFailureReason.serviceUnavailable,
    ),
  );
}
