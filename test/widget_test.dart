import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:demoapp/main.dart';

void main() {
  testWidgets('App starts without counter template assumptions', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());

    await tester.pump();

    expect(find.byType(MyApp), findsOneWidget);
  });
}
