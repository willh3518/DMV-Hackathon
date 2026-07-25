import 'package:accessibility_frontend/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('landing screen renders the approved core content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MainApp());

    expect(find.text('Find places that fit you.'), findsOneWidget);
    expect(
      find.text(
        'Discover restaurants and activities matched to your needs, '
        'preferences, and comfort.',
      ),
      findsOneWidget,
    );
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Already have an account? Sign in'), findsOneWidget);
    expect(
      find.text(
        'You control what you share and can update your answers anytime.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('landing screen meets automated accessibility guidelines', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MainApp());

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
