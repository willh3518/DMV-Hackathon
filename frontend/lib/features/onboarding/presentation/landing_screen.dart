import 'dart:math' as math;

import 'package:accessibility_frontend/design_system/app_colors.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/widgets/bubble_backdrop.dart';
import 'package:flutter/material.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({
    required this.getStartedFocusNode,
    required this.onGetStarted,
    required this.onSignIn,
    this.enabled = true,
    super.key,
  });

  final FocusNode getStartedFocusNode;
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;
  final bool enabled;

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(LandingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _syncMotion();
    }
  }

  @override
  void didChangeAccessibilityFeatures() {
    setState(() {});
    _syncMotion();
  }

  void _syncMotion() {
    if (!widget.enabled || prefersReducedMotion(context)) {
      _floatController
        ..stop()
        ..value = 0;
      return;
    }

    if (!_floatController.isAnimating) {
      _floatController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = prefersReducedMotion(context);

    return SafeArea(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 40,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: _PlaceholderMark(),
                    ),
                    const SizedBox(height: 24),
                    ExcludeSemantics(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _floatController,
                          builder: (BuildContext context, Widget? child) {
                            final double offset = reduceMotion
                                ? 0
                                : math.sin(_floatController.value * math.pi) *
                                      6;
                            return Transform.translate(
                              offset: Offset(0, offset),
                              child: child,
                            );
                          },
                          child: const _HeroArtwork(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Semantics(
                      header: true,
                      child: Text(
                        'Find places that fit you.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Discover restaurants and activities matched to your '
                      'needs, preferences, and comfort.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const Spacer(),
                    const SizedBox(height: 32),
                    FilledButton(
                      key: const Key('get_started_button'),
                      focusNode: widget.getStartedFocusNode,
                      onPressed: widget.enabled ? widget.onGetStarted : null,
                      child: const Text('Get started'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      key: const Key('sign_in_button'),
                      onPressed: widget.enabled ? widget.onSignIn : null,
                      child: const Text('Already have an account? Sign in'),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label:
                          'Privacy note. Your needs stay private and can be '
                          'changed anytime.',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: ExcludeSemantics(
                              child: Text(
                                'Your needs stay private and can be changed '
                                'anytime.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlaceholderMark extends StatelessWidget {
  const _PlaceholderMark();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.near_me_rounded,
          color: AppColors.primaryStrong,
          size: 26,
        ),
      ),
    );
  }
}

class _HeroArtwork extends StatelessWidget {
  const _HeroArtwork();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 230,
        height: 210,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.surfaceBlue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 8),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 36,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
            ),
            Container(
              width: 112,
              height: 132,
              decoration: BoxDecoration(
                color: AppColors.primaryStrong,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(56),
                  topRight: Radius.circular(56),
                  bottomLeft: Radius.circular(56),
                  bottomRight: Radius.circular(18),
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x332474C6),
                    blurRadius: 22,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.accessible_forward_rounded,
                color: Colors.white,
                size: 58,
              ),
            ),
            const Positioned(top: 22, right: 22, child: _Sparkle(size: 30)),
            const Positioned(left: 12, bottom: 30, child: _Sparkle(size: 22)),
            Positioned(
              right: 8,
              bottom: 18,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.surfaceBlueStrong,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome_rounded,
      color: AppColors.primary,
      size: size,
    );
  }
}
