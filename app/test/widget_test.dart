import 'package:flutter_test/flutter_test.dart';

import 'package:nephropredict_app/main.dart';

void main() {
  testWidgets('App title test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NephroPredictApp());

    // Verify that the title is displayed.
    expect(find.text('NephroPredict'), findsOneWidget);
  });
}
