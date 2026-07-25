import 'package:accessibility_frontend/app/main_app_shell.dart';
import 'package:accessibility_frontend/design_system/app_theme.dart';
import 'package:accessibility_frontend/domain/onboarding/onboarding_answers.dart';
import 'package:accessibility_frontend/domain/profile/profile_models.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/onboarding_entry_flow.dart';
import 'package:accessibility_frontend/live/live_discovery_gateway.dart';
import 'package:accessibility_frontend/live/place_cache.dart';
import 'package:accessibility_frontend/live/prompt_loader.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _showMainApp = false;
  ProfileSnapshot? _completedProfile;

  // Shared so a future LivePlaceDetailGateway can reuse places found during
  // discovery instead of re-searching. One per app session.
  final PlaceCache _placeCache = PlaceCache();

  // Null until the system prompt asset finishes loading; MainAppShell falls
  // back to its synthetic discovery fixture until then (negligible in
  // practice — the prompt is a small local asset, and onboarding takes far
  // longer than the load).
  LiveDiscoveryGateway? _discoveryGateway;

  @override
  void initState() {
    super.initState();
    loadSystemPrompt().then((systemPrompt) {
      if (!mounted) return;
      setState(() {
        _discoveryGateway = LiveDiscoveryGateway(
          systemPrompt: systemPrompt,
          placeCache: _placeCache,
        );
      });
    });
  }

  void _openMainApp({OnboardingSubmission? responses}) {
    setState(() {
      if (responses != null) {
        _completedProfile = ProfileSnapshot(responses: responses);
      }
      _showMainApp = true;
    });
  }

  void _exitToLanding() {
    setState(() {
      _completedProfile = null;
      _showMainApp = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _showMainApp
          ? MainAppShell(
              initialProfile: _completedProfile,
              discoveryGateway: _discoveryGateway,
              onExitToLanding: _exitToLanding,
            )
          : OnboardingEntryFlow(
              onOpenChat: _openMainApp,
              onCompleteOnboarding: (OnboardingSubmission responses) =>
                  _openMainApp(responses: responses),
            ),
    );
  }
}
