// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:reminder_demo/main.dart';

void main() {
  testWidgets('shows the reminders screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ReminderDemoApp());

    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('Your reminders'), findsOneWidget);
    expect(find.text('Next 14 days'), findsOneWidget);
  });

  testWidgets('opens reminder setup one step at a time', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ReminderDemoApp());
    await tester.tap(find.text('Add reminder'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(FilledButton, 'Continue'),
    ));
    await tester.pump();

    expect(find.text('Name your reminder'), findsOneWidget);
    expect(find.text('Step 1 of 6'), findsOneWidget);

    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Continue'),
      ),
      findsOneWidget,
    );
  });
}
