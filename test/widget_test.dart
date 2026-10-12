import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic sanity test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Platform Exam App'),
          ),
        ),
      ),
    );

    expect(find.text('Platform Exam App'), findsOneWidget);
  });
}
