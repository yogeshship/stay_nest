import 'package:flutter_test/flutter_test.dart';

import 'package:stay_nest/main.dart';
import 'package:stay_nest/screens/welcome_screen.dart';

void main() {
  testWidgets('StayNest opens welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const StayNestApp(home: WelcomeScreen()));

    expect(find.text('StayNest'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
