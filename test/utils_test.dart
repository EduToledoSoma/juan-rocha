import 'package:flutter_test/flutter_test.dart';
import 'package:juan_rocha_boxe/core/utils.dart';

void main() {
  test('valores monetários brasileiros em centavos', () {
    expect(parseMoney('129,90'),12990);
    expect(parseMoney('1.299,99'),129999);
    expect(parseMoney('0'),0);
  });
  test('status de mensalidade parcialmente paga', () {
    expect(invoiceStatus({
      'status':'pending','amount_cents':15000,'discount_cents':0,
      'paid_cents':5000,'due_date':'2030-10-10',
    }),'Parcial');
  });
  test('status de mensalidade vencida', () {
    expect(invoiceStatus({
      'status':'pending','amount_cents':15000,'discount_cents':0,
      'paid_cents':0,'due_date':'2020-01-01',
    }),'Vencida');
  });
  test('status de mensalidade quitada', () {
    expect(invoiceStatus({
      'status':'pending','amount_cents':15000,'discount_cents':2000,
      'paid_cents':13000,'due_date':'2020-01-01',
    }),'Paga');
  });
}
