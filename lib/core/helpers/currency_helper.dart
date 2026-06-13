import 'package:intl/intl.dart';

/// Handles flexible Indonesian Rupiah input and formatting
abstract class CurrencyHelper {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  /// Format integer to "Rp50.000"
  static String format(int amount) => _formatter.format(amount);

  /// Format double to "Rp50.000"
  static String formatDouble(double amount) => _formatter.format(amount);

  /// Parse flexible input: "50000", "Rp50000", "Rp50.000", "50.000" → 50000
  static int parse(String input) {
    // Remove "Rp", spaces, then remove dots used as thousands separator
    final cleaned = input
        .replaceAll(RegExp(r'[Rr][Pp]'), '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();
    return int.tryParse(cleaned) ?? 0;
  }

  /// Check if a string is a valid price input
  static bool isValid(String input) => parse(input) > 0;
}
