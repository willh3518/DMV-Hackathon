import 'dart:math' as math;

import 'package:accessibility_frontend/design_system/app_colors.dart';
import 'package:flutter/material.dart';

bool prefersReducedMotion(BuildContext context) {
  return MediaQuery.disableAnimationsOf(context) ||
      WidgetsBinding
          .instance
          .platformDispatcher
          .accessibilityFeatures
          .reduceMotion;
}

class BubbleBackdrop extends StatefulWidget {
  const BubbleBackdrop({super.key});

  @override
  State<BubbleBackdrop> createState() => _BubbleBackdropState();
}

class _BubbleBackdropState extends State<BubbleBackdrop>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didChangeAccessibilityFeatures() {
    setState(() {});
    _syncMotion();
  }

  void _syncMotion() {
    if (prefersReducedMotion(context)) {
      _controller
        ..stop()
        ..value = 0;
      return;
    }

    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = prefersReducedMotion(context);

    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final double phase = reduceMotion ? 0 : _controller.value;
            final double drift = math.sin(phase * math.pi * 2);

            return DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[AppColors.canvasTop, AppColors.canvasBottom],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Positioned(
                    top: -72 + (drift * 6),
                    right: -54,
                    child: const _Bubble(
                      size: 190,
                      color: AppColors.surfaceBlueStrong,
                      opacity: 0.45,
                    ),
                  ),
                  Positioned(
                    top: 118 - (drift * 4),
                    left: -46,
                    child: const _Bubble(
                      size: 116,
                      color: AppColors.bubbleLavender,
                      opacity: 0.34,
                    ),
                  ),
                  Positioned(
                    bottom: 118 + (drift * 5),
                    right: -34,
                    child: const _Bubble(
                      size: 104,
                      color: AppColors.bubbleBlue,
                      opacity: 0.32,
                    ),
                  ),
                  Positioned(
                    bottom: -145,
                    left: -70,
                    right: -70,
                    child: Container(
                      height: 260,
                      decoration: const BoxDecoration(
                        color: Color(0x4DFFFFFF),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.elliptical(320, 140),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }
}
