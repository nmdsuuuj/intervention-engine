// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:intervention_engine_app/main.dart';

void main() {
  testWidgets('Arrangement View displays sections from Song', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const InterventionEngineApp());
    await tester.pump();

    expect(find.text('Project BPM: 96'), findsOneWidget);
    expect(find.text('A-Melo'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('B-Melo'),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('B-Melo'), findsOneWidget);
    expect(find.text('[Drums]'), findsWidgets);
    expect(find.text('[Melody]'), findsWidgets);
  });
}
