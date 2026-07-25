import 'package:accessibility_frontend/design_system/app_colors.dart';
import 'package:accessibility_frontend/design_system/app_motion.dart';
import 'package:accessibility_frontend/design_system/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reduced motion uses a short duration and removes travel', (
    WidgetTester tester,
  ) async {
    late Duration duration;
    late Offset travel;
    final MediaQueryData mediaQuery = MediaQueryData.fromView(
      tester.view,
    ).copyWith(disableAnimations: true);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: mediaQuery,
          child: Builder(
            builder: (BuildContext context) {
              duration = AppMotion.resolveDuration(context);
              travel = AppMotion.resolveTravel(context, const Offset(24, 12));
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(duration, AppMotion.reducedTransition);
    expect(travel, Offset.zero);
  });

  test('form theme provides filled fields and accessible icon constraints', () {
    final InputDecorationThemeData inputTheme =
        AppTheme.light.inputDecorationTheme;

    expect(inputTheme.filled, isTrue);
    expect(inputTheme.fillColor, isNotNull);
    expect(inputTheme.border, isA<OutlineInputBorder>());
    expect(inputTheme.focusedBorder, isA<OutlineInputBorder>());
    expect(inputTheme.errorBorder, isA<OutlineInputBorder>());
    expect(inputTheme.errorMaxLines, 3);
    expect(inputTheme.helperMaxLines, 3);
    expect(
      inputTheme.prefixIconConstraints?.minWidth,
      greaterThanOrEqualTo(48),
    );
    expect(
      inputTheme.prefixIconConstraints?.minHeight,
      greaterThanOrEqualTo(48),
    );
    expect(
      inputTheme.suffixIconConstraints?.minWidth,
      greaterThanOrEqualTo(48),
    );
    expect(
      inputTheme.suffixIconConstraints?.minHeight,
      greaterThanOrEqualTo(48),
    );
  });

  test('outline keeps at least 3:1 contrast on shared light surfaces', () {
    expect(
      _contrastRatio(AppColors.outline, AppColors.surface),
      greaterThanOrEqualTo(3),
    );
    expect(
      _contrastRatio(AppColors.outline, AppColors.surfaceBlue),
      greaterThanOrEqualTo(3),
    );
  });
}

double _contrastRatio(Color first, Color second) {
  final double lighter = first.computeLuminance() > second.computeLuminance()
      ? first.computeLuminance()
      : second.computeLuminance();
  final double darker = first.computeLuminance() > second.computeLuminance()
      ? second.computeLuminance()
      : first.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
}
