import 'package:accessibility_frontend/design_system/app_colors.dart';
import 'package:flutter/material.dart';

/// Presentation-only status types. Domain assessment remains contract supplied.
enum AppStatusKind { strength, concern, unknown }

/// A compact icon-and-text treatment that never relies on color alone.
class AppStatusIndicator extends StatelessWidget {
  const AppStatusIndicator({
    required this.kind,
    required this.label,
    super.key,
  });

  final AppStatusKind kind;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (
      String statusLabel,
      IconData icon,
      Color background,
    ) = switch (kind) {
      AppStatusKind.strength => (
        'Strength',
        Icons.check_circle_rounded,
        AppColors.surfaceBlue,
      ),
      AppStatusKind.concern => (
        'Concern',
        Icons.error_outline_rounded,
        AppColors.bubbleLavender,
      ),
      AppStatusKind.unknown => (
        'Unknown',
        Icons.help_outline_rounded,
        AppColors.canvasTop,
      ),
    };
    final String visibleLabel = '$statusLabel: $label';

    return Semantics(
      container: true,
      label: visibleLabel,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.surfaceBlueStrong),
          ),
          child: Wrap(
            spacing: 7,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Icon(icon, color: AppColors.textPrimary, size: 20),
              Text(
                visibleLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
