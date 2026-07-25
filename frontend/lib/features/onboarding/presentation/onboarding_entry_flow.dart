import 'dart:async';

import 'package:accessibility_frontend/contracts/authentication_gateway.dart';
import 'package:accessibility_frontend/design_system/app_motion.dart';
import 'package:accessibility_frontend/domain/authentication/authentication_models.dart';
import 'package:accessibility_frontend/features/authentication/presentation/authentication_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/landing_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/question_one_placeholder_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/widgets/bubble_backdrop.dart';
import 'package:accessibility_frontend/fixtures/synthetic_authentication_gateway.dart';
import 'package:flutter/material.dart';

class OnboardingEntryFlow extends StatefulWidget {
  const OnboardingEntryFlow({this.authenticationGateway, super.key});

  final AuthenticationGateway? authenticationGateway;

  @override
  State<OnboardingEntryFlow> createState() => _OnboardingEntryFlowState();
}

enum _LandingCta { getStarted, signIn }

class _OnboardingEntryFlowState extends State<OnboardingEntryFlow>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _transitionController;
  late final FocusNode _getStartedFocusNode;
  late final FocusNode _signInFocusNode;
  late final FocusNode _questionHeadingFocusNode;
  late final AuthenticationGateway _authenticationGateway;
  _LandingCta _questionOrigin = _LandingCta.getStarted;
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
    _signInFocusNode = FocusNode(debugLabel: 'Sign in');
    _questionHeadingFocusNode = FocusNode(debugLabel: 'Question 1 heading');
    _authenticationGateway =
        widget.authenticationGateway ??
        SyntheticAuthenticationGateway(
          signInResult: AuthenticationSuccess(
            nextStep: ResumeOnboardingNextStep(stepIndex: 0),
          ),
        );
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
    _signInFocusNode.dispose();
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
          _landingFocusNodeFor(_questionOrigin).requestFocus();
        }
      });
    }
  }

  Future<void> _animateTo(double target) {
    return _transitionController.animateTo(
      target,
      duration: AppMotion.resolveDuration(context),
      curve: AppMotion.standardCurve,
    );
  }

  FocusNode _landingFocusNodeFor(_LandingCta cta) {
    return switch (cta) {
      _LandingCta.getStarted => _getStartedFocusNode,
      _LandingCta.signIn => _signInFocusNode,
    };
  }

  void _restoreLandingFocus(FocusNode focusNode) {
    focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) {
        focusNode.requestFocus();
      }
    });
  }

  Widget _buildAuthenticationScreen({
    required BuildContext routeContext,
    required AuthenticationOperation initialOperation,
  }) {
    return AuthenticationScreen(
      gateway: _authenticationGateway,
      initialOperation: initialOperation,
      onBack: () => Navigator.of(routeContext).pop(),
      onAuthenticated: (AuthenticationNextStep nextStep) {
        Navigator.of(routeContext).pop(nextStep);
      },
      onTerms: () => _showMessage(
        routeContext,
        'Terms will be available after approved legal copy is supplied.',
      ),
      onPrivacy: () => _showMessage(
        routeContext,
        'Privacy details will be available after approved copy is supplied.',
      ),
    );
  }

  void _openAuthentication({
    required BuildContext scaffoldContext,
    required AuthenticationOperation initialOperation,
    required _LandingCta originCta,
  }) {
    final FocusNode originFocusNode = _landingFocusNodeFor(originCta);
    final ScaffoldMessengerState rootMessenger = ScaffoldMessenger.of(
      scaffoldContext,
    );
    final Duration transitionDuration = AppMotion.resolveDuration(context);
    final PageRouteBuilder<AuthenticationNextStep> route =
        PageRouteBuilder<AuthenticationNextStep>(
          settings: const RouteSettings(name: 'authentication'),
          transitionDuration: transitionDuration,
          reverseTransitionDuration: transitionDuration,
          pageBuilder:
              (
                BuildContext routeContext,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
              ) {
                return _buildAuthenticationScreen(
                  routeContext: routeContext,
                  initialOperation: initialOperation,
                );
              },
          transitionsBuilder:
              (
                BuildContext routeContext,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
                Widget child,
              ) {
                final Animation<double> curved = CurvedAnimation(
                  parent: animation,
                  curve: AppMotion.standardCurve,
                  reverseCurve: AppMotion.standardCurve,
                );
                final Offset begin = AppMotion.resolveTravel(
                  routeContext,
                  const Offset(0, 0.04),
                );
                return FadeTransition(
                  opacity: curved,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: begin,
                      end: Offset.zero,
                    ).animate(curved),
                    child: child,
                  ),
                );
              },
        );

    unawaited(
      _presentAuthentication(
        navigator: Navigator.of(context),
        route: route,
        originCta: originCta,
        originFocusNode: originFocusNode,
        rootMessenger: rootMessenger,
      ),
    );
  }

  Future<void> _presentAuthentication({
    required NavigatorState navigator,
    required PageRouteBuilder<AuthenticationNextStep> route,
    required _LandingCta originCta,
    required FocusNode originFocusNode,
    required ScaffoldMessengerState rootMessenger,
  }) async {
    final AuthenticationNextStep? nextStep = await navigator.push(route);
    await route.completed;
    if (!mounted) {
      return;
    }

    switch (nextStep) {
      case null:
        _restoreLandingFocus(originFocusNode);
      case StartOnboardingNextStep():
        _questionOrigin = originCta;
        await _showQuestion();
      case ResumeOnboardingNextStep resume:
        _questionOrigin = originCta;
        await _showQuestion();
        if (mounted) {
          _showMessageWithMessenger(
            rootMessenger,
            'We saved your place at question ${resume.stepIndex + 1}. '
            'This build reopens Question 1 while the rest of onboarding is '
            'still being connected.',
          );
        }
      case OpenChatNextStep():
        _showMessageWithMessenger(
          rootMessenger,
          'Your account is ready. Chat will connect from the home screen in '
          'a later build.',
        );
        _restoreLandingFocus(originFocusNode);
    }
  }

  void _showMessage(BuildContext scaffoldContext, String message) {
    _showMessageWithMessenger(ScaffoldMessenger.of(scaffoldContext), message);
  }

  void _showMessageWithMessenger(
    ScaffoldMessengerState messenger,
    String message,
  ) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = AppMotion.prefersReducedMotion(context);

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
                          child: TickerMode(
                            enabled: !_questionIsActive,
                            child: IgnorePointer(
                              ignoring: !_questionIsActive
                                  ? _isTransitioning
                                  : true,
                              child: ExcludeFocus(
                                excluding: _questionIsActive,
                                child: ExcludeSemantics(
                                  key: const Key('landing_semantics_gate'),
                                  excluding: _questionIsActive,
                                  child: LandingScreen(
                                    getStartedFocusNode: _getStartedFocusNode,
                                    signInFocusNode: _signInFocusNode,
                                    enabled:
                                        !_isTransitioning && !_questionIsActive,
                                    onGetStarted: () => _openAuthentication(
                                      scaffoldContext: scaffoldContext,
                                      initialOperation:
                                          AuthenticationOperation.signUp,
                                      originCta: _LandingCta.getStarted,
                                    ),
                                    onSignIn: () => _openAuthentication(
                                      scaffoldContext: scaffoldContext,
                                      initialOperation:
                                          AuthenticationOperation.signIn,
                                      originCta: _LandingCta.signIn,
                                    ),
                                  ),
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
                          child: TickerMode(
                            enabled: _questionIsActive,
                            child: IgnorePointer(
                              ignoring: !_questionIsActive || _isTransitioning,
                              child: ExcludeFocus(
                                excluding: !_questionIsActive,
                                child: ExcludeSemantics(
                                  key: const Key('question_semantics_gate'),
                                  excluding: !_questionIsActive,
                                  child: QuestionOnePlaceholderScreen(
                                    headingFocusNode: _questionHeadingFocusNode,
                                    enabled:
                                        !_isTransitioning && _questionIsActive,
                                    onBack: _showLanding,
                                    onSkip: () => _showMessage(
                                      scaffoldContext,
                                      'Question choices and Skip behavior arrive in the next onboarding build.',
                                    ),
                                  ),
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
