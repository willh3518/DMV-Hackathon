import 'package:flutter/material.dart';

/// Shared motion values for the approved Version 1 visual system.
abstract final class AppMotion {
  static const Duration standard = Duration(milliseconds: 300);
  static const Duration feedback = Duration(milliseconds: 140);
  static const Duration reducedTransition = Duration(milliseconds: 90);

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve feedbackCurve = Curves.easeOut;

  static bool prefersReducedMotion(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context) ||
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .reduceMotion;
  }

  /// Resolves an animation duration to a settled reduced-motion crossfade.
  static Duration resolveDuration(
    BuildContext context, {
    Duration duration = standard,
  }) {
    return prefersReducedMotion(context) ? reducedTransition : duration;
  }

  /// Removes positional travel while preserving the settled visual state.
  static Offset resolveTravel(BuildContext context, Offset travel) {
    return prefersReducedMotion(context) ? Offset.zero : travel;
  }
}
