import 'package:accessibility_frontend/features/onboarding/presentation/landing_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/question_one_placeholder_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/widgets/bubble_backdrop.dart';
import 'package:flutter/material.dart';

class OnboardingEntryFlow extends StatefulWidget {
  const OnboardingEntryFlow({super.key});

  @override
  State<OnboardingEntryFlow> createState() => _OnboardingEntryFlowState();
}

class _OnboardingEntryFlowState extends State<OnboardingEntryFlow>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _transitionController;
  late final FocusNode _getStartedFocusNode;
  late final FocusNode _questionHeadingFocusNode;
  bool _questionIsActive = false;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _getStartedFocusNode = FocusNode(debugLabel: 'Get started');
    _questionHeadingFocusNode = FocusNode(debugLabel: 'Question 1 heading');
  }

  @override
  void didChangeAccessibilityFeatures() {
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _transitionController.dispose();
    _getStartedFocusNode.dispose();
    _questionHeadingFocusNode.dispose();
    super.dispose();
  }

  Future<void> _showQuestion() async {
    if (_isTransitioning || _questionIsActive) {
      return;
    }

    setState(() {
      _questionIsActive = true;
      _isTransitioning = true;
    });
    await _animateTo(1);
    if (mounted) {
      setState(() => _isTransitioning = false);
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) {
          _questionHeadingFocusNode.requestFocus();
        }
      });
    }
  }

  Future<void> _showLanding() async {
    if (_isTransitioning || !_questionIsActive) {
      return;
    }

    setState(() {
      _questionIsActive = false;
      _isTransitioning = true;
    });
    await _animateTo(0);
    if (mounted) {
      setState(() => _isTransitioning = false);
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) {
          _getStartedFocusNode.requestFocus();
        }
      });
    }
  }

  Future<void> _animateTo(double target) {
    final bool reduceMotion = prefersReducedMotion(context);
    return _transitionController.animateTo(
      target,
      duration: reduceMotion
          ? const Duration(milliseconds: 90)
          : const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _showSignInMessage(BuildContext scaffoldContext) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
      scaffoldContext,
    );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Sign in will be available in the next app build.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = prefersReducedMotion(context);

    return Scaffold(
      body: Builder(
        builder: (BuildContext scaffoldContext) {
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const BubbleBackdrop(),
              AnimatedBuilder(
                animation: _transitionController,
                builder: (BuildContext context, Widget? child) {
                  final double progress = _transitionController.value;
                  final double landingOffset = reduceMotion
                      ? 0
                      : -20 * progress;
                  final double questionOffset = reduceMotion
                      ? 0
                      : 28 * (1 - progress);

                  return Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Opacity(
                        opacity: 1 - progress,
                        alwaysIncludeSemantics: !_questionIsActive,
                        child: Transform.translate(
                          offset: Offset(0, landingOffset),
                          child: IgnorePointer(
                            ignoring: !_questionIsActive
                                ? _isTransitioning
                                : true,
                            child: ExcludeFocus(
                              excluding: _questionIsActive,
                              child: ExcludeSemantics(
                                excluding: _questionIsActive,
                                child: LandingScreen(
                                  getStartedFocusNode: _getStartedFocusNode,
                                  enabled:
                                      !_isTransitioning && !_questionIsActive,
                                  onGetStarted: _showQuestion,
                                  onSignIn: () =>
                                      _showSignInMessage(scaffoldContext),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: progress,
                        alwaysIncludeSemantics: _questionIsActive,
                        child: Transform.translate(
                          offset: Offset(0, questionOffset),
                          child: IgnorePointer(
                            ignoring: !_questionIsActive || _isTransitioning,
                            child: ExcludeFocus(
                              excluding: !_questionIsActive,
                              child: ExcludeSemantics(
                                excluding: !_questionIsActive,
                                child: QuestionOnePlaceholderScreen(
                                  headingFocusNode: _questionHeadingFocusNode,
                                  enabled:
                                      !_isTransitioning && _questionIsActive,
                                  onBack: _showLanding,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
