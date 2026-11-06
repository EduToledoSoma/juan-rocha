import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juan_rocha_boxe/ui/style.dart';

void main() {
  testWidgets('Cartão mostra nome, valor e abre a área responsável', (tester) async {
    var pressed = false;
    await tester.pumpWidget(MaterialApp(
      theme: jrTheme(),
      home: Scaffold(body: Center(child: SizedBox(width: 150,
        child: JrStat(
          label: 'Mensalidades vencidas',
          value: 'R\$ 9.999,99',
          icon: Icons.payments_outlined,
          onTap: () => pressed = true,
        ),
      ))),
    ));
    expect(find.text('Mensalidades vencidas'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(JrStat));
    expect(pressed, isTrue);
  });
}
