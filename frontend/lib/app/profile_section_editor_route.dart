import 'package:accessibility_frontend/domain/onboarding/onboarding_answers.dart';
import 'package:accessibility_frontend/domain/profile/profile_models.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/questions/question_five_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/questions/question_four_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/questions/question_one_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/questions/question_three_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/questions/question_two_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/widgets/bubble_backdrop.dart';
import 'package:flutter/material.dart';

/// Reuses one onboarding question to edit its matching in-memory profile slice.
class ProfileSectionEditorRoute extends StatefulWidget {
  const ProfileSectionEditorRoute({
    required this.section,
    required this.profile,
    required this.onCancel,
    required this.onSave,
    super.key,
  });

  final ProfileSectionId section;
  final ProfileSnapshot profile;
  final VoidCallback onCancel;
  final ValueChanged<ProfileSnapshot> onSave;

  @override
  State<ProfileSectionEditorRoute> createState() =>
      _ProfileSectionEditorRouteState();
}

class _ProfileSectionEditorRouteState extends State<ProfileSectionEditorRoute> {
  late final FocusNode _headingFocusNode;
  late OnboardingSubmission _responses;

  @override
  void initState() {
    super.initState();
    _headingFocusNode = FocusNode(debugLabel: 'Profile section edit heading');
    _responses = widget.profile.responses;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted && _headingFocusNode.canRequestFocus) {
        _headingFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _headingFocusNode.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave(ProfileSnapshot(responses: _responses));
  }

  void _update({
    AccommodationsDraft? accommodations,
    ExperiencePreferencesDraft? experiencePreferences,
    TravelComfortDraft? travelComfort,
    InterestsDraft? interests,
    PlanningSituationsDraft? planningSituations,
  }) {
    setState(() {
      _responses = OnboardingSubmission(
        accommodations: accommodations ?? _responses.accommodations,
        experiencePreferences:
            experiencePreferences ?? _responses.experiencePreferences,
        travelComfort: travelComfort ?? _responses.travelComfort,
        interests: interests ?? _responses.interests,
        planningSituations: planningSituations ?? _responses.planningSituations,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const BubbleBackdrop(),
          switch (widget.section) {
            ProfileSectionId.accommodations => QuestionOneScreen(
              draft: _responses.accommodations,
              onChanged: (AccommodationsDraft draft) {
                _update(accommodations: draft);
              },
              headingFocusNode: _headingFocusNode,
              onBack: widget.onCancel,
              onSkip: _save,
              onContinue: _save,
            ),
            ProfileSectionId.experiencePreferences => QuestionTwoScreen(
              draft: _responses.experiencePreferences,
              onChanged: (ExperiencePreferencesDraft draft) {
                _update(experiencePreferences: draft);
              },
              headingFocusNode: _headingFocusNode,
              onBack: widget.onCancel,
              onSkip: _save,
              onContinue: _save,
            ),
            ProfileSectionId.travelComfort => QuestionThreeScreen(
              draft: _responses.travelComfort,
              onChanged: (TravelComfortDraft draft) {
                _update(travelComfort: draft);
              },
              headingFocusNode: _headingFocusNode,
              onBack: widget.onCancel,
              onSkip: _save,
              onContinue: _save,
            ),
            ProfileSectionId.interests => QuestionFourScreen(
              draft: _responses.interests,
              onChanged: (InterestsDraft draft) {
                _update(interests: draft);
              },
              headingFocusNode: _headingFocusNode,
              onBack: widget.onCancel,
              onSkip: _save,
              onContinue: _save,
            ),
            ProfileSectionId.planningSituations => QuestionFiveScreen(
              draft: _responses.planningSituations,
              onChanged: (PlanningSituationsDraft draft) {
                _update(planningSituations: draft);
              },
              headingFocusNode: _headingFocusNode,
              onBack: widget.onCancel,
              onSkip: _save,
              onContinue: _save,
            ),
          },
        ],
      ),
    );
  }
}
