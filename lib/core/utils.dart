import 'package:intl/intl.dart';

final _moneyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');

String money(int cents) => _moneyFormat.format(cents / 100.0);
String displayDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final date = DateTime.tryParse(iso);
  return date == null ? iso : _dateFormat.format(date);
}
String todayIso() => DateFormat('yyyy-MM-dd').format(DateTime.now());
String monthKey([DateTime? date]) => DateFormat('yyyy-MM').format(date ?? DateTime.now());
String friendlyMonth(String yyyymm) {
  final date = DateTime.tryParse('$yyyymm-01');
  return date == null ? yyyymm : DateFormat('MMMM/yyyy', 'pt_BR').format(date);
}
int parseMoney(String raw) {
  var s = raw.trim().replaceAll(RegExp(r'[^0-9,.]'), '');
  if (s.isEmpty) return 0;
  if (s.contains(',')) {
    s = s.replaceAll('.', '').replaceAll(',', '.');
  } else if (s.split('.').length > 2) {
    s = s.replaceAll('.', '');
  }
  final value = double.tryParse(s) ?? 0;
  return (value * 100).round();
}
String editMoney(int cents) => (cents / 100).toStringAsFixed(2).replaceAll('.', ',');
int intValue(Object? v) => (v as num?)?.toInt() ?? 0;
String textValue(Object? v) => v?.toString() ?? '';
String invoiceStatus(Map<String, Object?> row) {
  final s = textValue(row['status']);
  if (s == 'cancelled') return 'Cancelada';
  if (s == 'waived') return 'Isenta';
  final total = intValue(row['amount_cents']) - intValue(row['discount_cents']);
  final paid = intValue(row['paid_cents']);
  if (paid >= total && total > 0) return 'Paga';
  if (paid > 0) return 'Parcial';
  final due = textValue(row['due_date']);
  if (due.isNotEmpty && due.compareTo(todayIso()) < 0) return 'Vencida';
  return 'Pendente';
}
