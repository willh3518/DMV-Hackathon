import 'package:accessibility_frontend/design_system/app_theme.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/onboarding_entry_flow.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Accessibility discovery',
      theme: AppTheme.light,
      home: const OnboardingEntryFlow(),
    );
  }
}
