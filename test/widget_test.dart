import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juan_rocha_boxe/ui/style.dart';

void main() {
  testWidgets('Tema e nome Juan Rocha Boxe', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: jrTheme(),
      home: const Scaffold(body: Center(child: Text('Juan Rocha Boxe'))),
    ));
    expect(find.text('Juan Rocha Boxe'), findsOneWidget);
    expect(Theme.of(tester.element(find.text('Juan Rocha Boxe')))
        .colorScheme.primary, brandGold);
  });
}
