import 'package:flutter_test/flutter_test.dart';
import 'package:bobkasir/features/report/data/report_provider.dart';

/// Pins the period→date-range mapping that drives the report queries.
void main() {
  test('daily range starts at midnight today', () {
    final (start, end) = ReportApiService.rangeFor('daily');
    final now = DateTime.now();
    expect(start.year, now.year);
    expect(start.month, now.month);
    expect(start.day, now.day);
    expect(start.hour, 0);
    expect(end.isAfter(start) || end.isAtSameMomentAs(start), isTrue);
  });

  test('monthly range starts on the first of the month', () {
    final (start, _) = ReportApiService.rangeFor('monthly');
    expect(start.day, 1);
  });

  test('yearly range starts on Jan 1', () {
    final (start, _) = ReportApiService.rangeFor('yearly');
    expect(start.month, 1);
    expect(start.day, 1);
  });

  test('custom range uses the provided dates', () {
    final from = DateTime(2026, 1, 1);
    final to = DateTime(2026, 1, 31);
    final (start, end) = ReportApiService.rangeFor('custom', from: from, to: to);
    expect(start, from);
    expect(end, to);
  });

  test('label maps period codes to Indonesian labels', () {
    expect(ReportApiService.label('daily'), 'Harian');
    expect(ReportApiService.label('weekly'), 'Mingguan');
    expect(ReportApiService.label('monthly'), 'Bulanan');
    expect(ReportApiService.label('yearly'), 'Tahunan');
    expect(ReportApiService.label('custom'), 'Custom');
  });
}
