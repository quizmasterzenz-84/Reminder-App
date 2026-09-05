// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:reminder_demo/main.dart';

void main() {
  testWidgets('shows the reminders screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ReminderDemoApp());

    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('Your reminders'), findsOneWidget);
    expect(find.text('Next 14 days'), findsOneWidget);
  });

  testWidgets('shows audio controls in the reminder dialog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ReminderDemoApp());
    await tester.tap(find.text('Add reminder'));
    await tester.pumpAndSettle();

    expect(find.text('System tone'), findsOneWidget);
    expect(find.text('Record voice'), findsOneWidget);
    expect(find.text('Pick file'), findsOneWidget);
  });
}
