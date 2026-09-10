import 'package:flutter_test/flutter_test.dart';

import 'package:ev_mobility_mobile/main.dart';

void main() {
  testWidgets('App boots to the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const EvMobilityApp());
    // The app checks secure storage for a saved session before deciding
    // which screen to open on -- let that resolve before asserting.
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
