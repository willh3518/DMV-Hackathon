import 'package:accessibility_frontend/app/main_app_shell.dart';
import 'package:accessibility_frontend/design_system/app_theme.dart';
import 'package:accessibility_frontend/domain/onboarding/onboarding_answers.dart';
import 'package:accessibility_frontend/domain/profile/profile_models.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/onboarding_entry_flow.dart';
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
