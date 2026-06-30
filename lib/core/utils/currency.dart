import 'package:intl/intl.dart';

final _fmt = NumberFormat('#,###', 'id_ID');

String formatRupiah(double amount) => 'Rp ${_fmt.format(amount.toInt())}';

String formatRupiahCompact(double amount) {
  if (amount >= 1000000) {
    return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
  } else if (amount >= 1000) {
    return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
  }
  return formatRupiah(amount);
}

double parseRupiah(String input) {
  final cleaned = input
      .replaceAll('Rp', '')
      .replaceAll('.', '')
      .replaceAll(',', '')
      .trim();
  return double.tryParse(cleaned) ?? 0;
}
