import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juan_rocha_boxe/ui/style.dart';

void main() {
  testWidgets('Tema Juan Rocha Boxe e aplicado', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: jrTheme(),
        home: const Scaffold(
          body: Center(child: Text('Juan Rocha Boxe')),
        ),
      ),
    );

    expect(find.text('Juan Rocha Boxe'), findsOneWidget);
    final context = tester.element(find.text('Juan Rocha Boxe'));
    expect(Theme.of(context).colorScheme.primary, brandGold);
  });
}
