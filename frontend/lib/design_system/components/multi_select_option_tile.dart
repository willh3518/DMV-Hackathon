import 'package:accessibility_frontend/design_system/app_colors.dart';
import 'package:accessibility_frontend/design_system/app_motion.dart';
import 'package:flutter/material.dart';

/// A text-scaling-safe multi-select choice with explicit selected semantics.
class MultiSelectOptionTile extends StatefulWidget {
  const MultiSelectOptionTile({
    required this.label,
    required this.selected,
    required this.onChanged,
    this.description,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    super.key,
  });

  final String label;
  final String? description;
  final bool selected;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<bool> onChanged;

  @override
  State<MultiSelectOptionTile> createState() => _MultiSelectOptionTileState();
}

class _MultiSelectOptionTileState extends State<MultiSelectOptionTile> {
  bool _hasFocus = false;

  void _toggle() {
    widget.onChanged(!widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    final Color foreground = widget.enabled
        ? AppColors.textPrimary
        : AppColors.textSecondary;
    final Color borderColor = _hasFocus || widget.selected
        ? AppColors.primaryStrong
        : AppColors.outline;
    final Color background = widget.selected
        ? AppColors.surfaceBlue
        : AppColors.surface;
    final String semanticLabel = switch (widget.description) {
      final String description when description.isNotEmpty =>
        '${widget.label}. $description',
      _ => widget.label,
    };

    return Semantics(
      container: true,
      button: true,
      enabled: widget.enabled,
      selected: widget.selected,
      label: semanticLabel,
      onTap: widget.enabled ? _toggle : null,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: AppMotion.resolveDuration(
            context,
            duration: AppMotion.feedback,
          ),
          curve: AppMotion.feedbackCurve,
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: widget.enabled ? borderColor : AppColors.surfaceBlueStrong,
              width: _hasFocus ? 2 : 1,
            ),
            boxShadow: widget.selected && widget.enabled
                ? const <BoxShadow>[
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              excludeFromSemantics: true,
              focusNode: widget.focusNode,
              autofocus: widget.autofocus && widget.enabled,
              canRequestFocus: widget.enabled,
              onFocusChange: (bool hasFocus) {
                if (_hasFocus != hasFocus) {
                  setState(() => _hasFocus = hasFocus);
                }
              },
              onTap: widget.enabled ? _toggle : null,
              overlayColor: WidgetStateProperty.resolveWith<Color?>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.pressed)) {
                  return AppColors.primary.withValues(alpha: 0.12);
                }
                if (states.contains(WidgetState.focused)) {
                  return AppColors.primary.withValues(alpha: 0.08);
                }
                return null;
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.label,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: foreground,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                          ),
                          if (widget.description
                              case final String description) ...<Widget>[
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: foreground),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedSwitcher(
                      duration: AppMotion.resolveDuration(
                        context,
                        duration: AppMotion.feedback,
                      ),
                      child: Icon(
                        widget.selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        key: ValueKey<bool>(widget.selected),
                        color: widget.enabled
                            ? AppColors.primaryStrong
                            : AppColors.outline,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
