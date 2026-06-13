import 'package:intl/intl.dart';

abstract class DateHelper {
  static String formatDateTime(DateTime dt) =>
      DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);

  static String formatDate(DateTime dt) =>
      DateFormat('dd MMM yyyy', 'id_ID').format(dt);

  static String formatTime(DateTime dt) =>
      DateFormat('HH:mm', 'id_ID').format(dt);

  static String formatOrderDate(DateTime dt) =>
      DateFormat('yyyyMMdd').format(dt);

  /// Generate offline order number: BK-OFFLINE-{deviceId}-{timestamp}
  static String offlineOrderNumber(String deviceId) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'BK-OFFLINE-$deviceId-$ts';
  }

  /// Format for display in receipts: "10 Jun 2026, 14:30"
  static String receiptDate(DateTime dt) =>
      DateFormat('dd MMM yyyy, HH:mm').format(dt);
}
