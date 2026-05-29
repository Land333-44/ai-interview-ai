import 'package:flutter_test/flutter_test.dart';
import 'package:smart_coach_ai/main.dart';

void main() {
  testWidgets('renders Smart Coach onboarding', (tester) async {
    await tester.pumpWidget(const SmartCoachApp());

    expect(find.text('Smart Coach AI'), findsOneWidget);
    expect(find.textContaining('Unlock Your'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
