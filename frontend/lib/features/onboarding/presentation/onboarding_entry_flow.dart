import 'dart:async';

import 'package:accessibility_frontend/contracts/authentication_gateway.dart';
import 'package:accessibility_frontend/contracts/onboarding_completion_gateway.dart';
import 'package:accessibility_frontend/design_system/app_motion.dart';
import 'package:accessibility_frontend/domain/authentication/authentication_models.dart';
import 'package:accessibility_frontend/domain/onboarding/onboarding_answers.dart';
import 'package:accessibility_frontend/domain/onboarding/onboarding_completion_models.dart';
import 'package:accessibility_frontend/features/authentication/presentation/authentication_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/landing_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/onboarding_completion_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/questions/question_five_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/questions/question_four_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/questions/question_one_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/questions/question_three_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/questions/question_two_screen.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/widgets/bubble_backdrop.dart';
import 'package:accessibility_frontend/fixtures/synthetic_authentication_gateway.dart';
import 'package:accessibility_frontend/fixtures/synthetic_onboarding_completion_gateway.dart';
import 'package:flutter/material.dart';

class OnboardingEntryFlow extends StatefulWidget {
  const OnboardingEntryFlow({
    this.authenticationGateway,
    this.completionGateway,
    super.key,
  });

  final AuthenticationGateway? authenticationGateway;
  final OnboardingCompletionGateway? completionGateway;

  @override
  State<OnboardingEntryFlow> createState() => _OnboardingEntryFlowState();
}

enum _LandingCta { getStarted, signIn }

class _OnboardingEntryFlowState extends State<OnboardingEntryFlow>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _transitionController;
  late final AnimationController _questionTransitionController;
  late final FocusNode _getStartedFocusNode;
  late final FocusNode _signInFocusNode;
  late final List<FocusNode> _questionHeadingFocusNodes;
  late final AuthenticationGateway _authenticationGateway;
  late final OnboardingCompletionGateway _completionGateway;
  AccommodationsDraft _accommodationsDraft = const AccommodationsDraft();
  ExperiencePreferencesDraft _experiencePreferencesDraft =
      const ExperiencePreferencesDraft();
  TravelComfortDraft _travelComfortDraft = const TravelComfortDraft();
  InterestsDraft _interestsDraft = const InterestsDraft();
  PlanningSituationsDraft _planningSituationsDraft =
      const PlanningSituationsDraft();
  OnboardingCompletionStage _completionStage = OnboardingCompletionStage.ready;
  OnboardingCompletionFailureReason? _completionFailureReason;
  _LandingCta _questionOrigin = _LandingCta.getStarted;
  int _activeQuestionIndex = 0;
  int _outgoingQuestionIndex = 0;
  bool _questionIsActive = false;
  bool _isTransitioning = false;
  bool _isQuestionTransitioning = false;
  bool _questionTransitionForward = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _questionTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _getStartedFocusNode = FocusNode(debugLabel: 'Get started');
    _signInFocusNode = FocusNode(debugLabel: 'Sign in');
    _questionHeadingFocusNodes = List<FocusNode>.generate(
      6,
      (int index) => FocusNode(
        debugLabel: index < 5
            ? 'Question ${index + 1} heading'
            : 'Onboarding completion heading',
      ),
    );
    _authenticationGateway =
        widget.authenticationGateway ??
        SyntheticAuthenticationGateway(
          signInResult: AuthenticationSuccess(
            nextStep: ResumeOnboardingNextStep(stepIndex: 0),
          ),
        );
    _completionGateway =
        widget.completionGateway ?? SyntheticOnboardingCompletionGateway();
  }

  @override
  void didChangeAccessibilityFeatures() {
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _transitionController.dispose();
    _questionTransitionController.dispose();
    _getStartedFocusNode.dispose();
    _signInFocusNode.dispose();
    for (final FocusNode focusNode in _questionHeadingFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _showQuestion({int initialIndex = 0}) async {
    if (_isTransitioning || _questionIsActive) {
      return;
    }

    setState(() {
      _activeQuestionIndex = initialIndex.clamp(0, 4);
      _outgoingQuestionIndex = _activeQuestionIndex;
      _questionIsActive = true;
      _isTransitioning = true;
    });
    await _animateTo(1);
    if (mounted) {
      setState(() => _isTransitioning = false);
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) {
          _questionHeadingFocusNodes[_activeQuestionIndex].requestFocus();
        }
      });
    }
  }

  Future<void> _goToQuestion(int targetIndex) async {
    if (_isTransitioning ||
        _isQuestionTransitioning ||
        !_questionIsActive ||
        targetIndex == _activeQuestionIndex ||
        targetIndex < 0 ||
        targetIndex > 5) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _outgoingQuestionIndex = _activeQuestionIndex;
      _questionTransitionForward = targetIndex > _activeQuestionIndex;
      _activeQuestionIndex = targetIndex;
      _isQuestionTransitioning = true;
    });
    _questionTransitionController.value = 0;
    await _questionTransitionController.animateTo(
      1,
      duration: AppMotion.resolveDuration(context),
      curve: AppMotion.standardCurve,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isQuestionTransitioning = false;
      _outgoingQuestionIndex = _activeQuestionIndex;
    });
    _questionTransitionController.value = 0;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) {
        _questionHeadingFocusNodes[_activeQuestionIndex].requestFocus();
      }
    });
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
        final int availableIndex = resume.stepIndex.clamp(0, 4);
        await _showQuestion(initialIndex: availableIndex);
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

  Future<void> _showCompletion() async {
    setState(() {
      _completionStage = OnboardingCompletionStage.ready;
      _completionFailureReason = null;
    });
    await _goToQuestion(5);
  }

  Future<void> _submitOnboarding() async {
    if (_completionStage == OnboardingCompletionStage.submitting) {
      return;
    }

    setState(() {
      _completionStage = OnboardingCompletionStage.submitting;
      _completionFailureReason = null;
    });

    final OnboardingCompletionRequest request = OnboardingCompletionRequest(
      submission: OnboardingSubmission(
        accommodations: _accommodationsDraft,
        experiencePreferences: _experiencePreferencesDraft,
        travelComfort: _travelComfortDraft,
        interests: _interestsDraft,
        planningSituations: _planningSituationsDraft,
      ),
    );

    OnboardingCompletionResult result;
    try {
      result = await _completionGateway.completeOnboarding(request);
    } catch (_) {
      result = const OnboardingCompletionFailure(
        reason: OnboardingCompletionFailureReason.unknown,
      );
    }
    if (!mounted) {
      return;
    }

    switch (result) {
      case OnboardingCompletionSuccess():
        setState(() {
          _completionStage = OnboardingCompletionStage.confirmed;
          _completionFailureReason = null;
        });
      case OnboardingCompletionFailure failure:
        setState(() {
          _completionStage = OnboardingCompletionStage.failure;
          _completionFailureReason = failure.reason;
        });
    }
  }

  Widget _buildQuestionScreen({
    required int index,
    required BuildContext scaffoldContext,
    required bool enabled,
  }) {
    return switch (index) {
      0 => QuestionOneScreen(
        key: const ValueKey<String>('question_one_screen'),
        draft: _accommodationsDraft,
        onChanged: (AccommodationsDraft draft) {
          setState(() => _accommodationsDraft = draft);
        },
        headingFocusNode: _questionHeadingFocusNodes[0],
        enabled: enabled,
        onBack: _showLanding,
        onSkip: () => _goToQuestion(1),
        onContinue: () => _goToQuestion(1),
      ),
      1 => QuestionTwoScreen(
        key: const ValueKey<String>('question_two_screen'),
        draft: _experiencePreferencesDraft,
        onChanged: (ExperiencePreferencesDraft draft) {
          setState(() => _experiencePreferencesDraft = draft);
        },
        headingFocusNode: _questionHeadingFocusNodes[1],
        enabled: enabled,
        onBack: () => _goToQuestion(0),
        onSkip: () => _goToQuestion(2),
        onContinue: () => _goToQuestion(2),
      ),
      2 => QuestionThreeScreen(
        key: const ValueKey<String>('question_three_screen'),
        draft: _travelComfortDraft,
        onChanged: (TravelComfortDraft draft) {
          setState(() => _travelComfortDraft = draft);
        },
        headingFocusNode: _questionHeadingFocusNodes[2],
        enabled: enabled,
        onBack: () => _goToQuestion(1),
        onSkip: () => _goToQuestion(3),
        onContinue: () => _goToQuestion(3),
      ),
      3 => QuestionFourScreen(
        key: const ValueKey<String>('question_four_screen'),
        draft: _interestsDraft,
        onChanged: (InterestsDraft draft) {
          setState(() => _interestsDraft = draft);
        },
        headingFocusNode: _questionHeadingFocusNodes[3],
        enabled: enabled,
        onBack: () => _goToQuestion(2),
        onSkip: () => _goToQuestion(4),
        onContinue: () => _goToQuestion(4),
      ),
      4 => QuestionFiveScreen(
        key: const ValueKey<String>('question_five_screen'),
        draft: _planningSituationsDraft,
        onChanged: (PlanningSituationsDraft draft) {
          setState(() => _planningSituationsDraft = draft);
        },
        headingFocusNode: _questionHeadingFocusNodes[4],
        enabled: enabled,
        onBack: () => _goToQuestion(3),
        onSkip: _showCompletion,
        onContinue: _showCompletion,
      ),
      5 => IgnorePointer(
        ignoring: !enabled,
        child: OnboardingCompletionScreen(
          key: const ValueKey<String>('onboarding_completion_screen'),
          stage: _completionStage,
          failureReason: _completionFailureReason,
          headingFocusNode: _questionHeadingFocusNodes[5],
          onBack: () => _goToQuestion(4),
          onSubmit: _submitOnboarding,
          onRetry: _submitOnboarding,
          onContinue: () => _showMessage(
            scaffoldContext,
            'Your profile setup is confirmed in this frontend build. Chat is '
            'coming in the next stage.',
          ),
        ),
      ),
      _ => throw StateError('Unsupported onboarding question index: $index'),
    };
  }

  Widget _buildActiveQuestionLayer({
    required BuildContext scaffoldContext,
    required bool reduceMotion,
  }) {
    final bool questionsEnabled =
        !_isTransitioning && !_isQuestionTransitioning && _questionIsActive;
    if (!_isQuestionTransitioning) {
      return _buildQuestionScreen(
        index: _activeQuestionIndex,
        scaffoldContext: scaffoldContext,
        enabled: questionsEnabled,
      );
    }

    return AnimatedBuilder(
      animation: _questionTransitionController,
      builder: (BuildContext context, Widget? child) {
        final double progress = _questionTransitionController.value;
        final double direction = _questionTransitionForward ? 1 : -1;
        final double travel = reduceMotion ? 0 : 24;

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Opacity(
              opacity: 1 - progress,
              child: Transform.translate(
                offset: Offset(-direction * travel * progress, 0),
                child: TickerMode(
                  enabled: false,
                  child: IgnorePointer(
                    child: ExcludeFocus(
                      child: ExcludeSemantics(
                        child: _buildQuestionScreen(
                          index: _outgoingQuestionIndex,
                          scaffoldContext: scaffoldContext,
                          enabled: false,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Opacity(
              opacity: progress,
              alwaysIncludeSemantics: true,
              child: Transform.translate(
                offset: Offset(direction * travel * (1 - progress), 0),
                child: ExcludeFocus(
                  excluding: true,
                  child: _buildQuestionScreen(
                    index: _activeQuestionIndex,
                    scaffoldContext: scaffoldContext,
                    enabled: false,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
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
                                  child: _buildActiveQuestionLayer(
                                    scaffoldContext: scaffoldContext,
                                    reduceMotion: reduceMotion,
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
