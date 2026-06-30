// ignore_for_file: use_null_aware_elements
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

final reportRepositoryProvider = Provider((ref) => ReportRepository(ref.read(apiClientProvider)));

class ReportRepository {
  final ApiClient _api;
  ReportRepository(this._api);

  Future<Map<String, dynamic>> getDaily({String? date}) async {
    final resp = await _api.get('/reports/daily', params: {
      if (date != null) 'date': date,
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getWeekly({String? startDate}) async {
    final resp = await _api.get('/reports/weekly', params: {
      if (startDate != null) 'start_date': startDate,
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMonthly({int? year, int? month}) async {
    final resp = await _api.get('/reports/monthly', params: {
      if (year != null) 'year': year,
      if (month != null) 'month': month,
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getYearly({int? year}) async {
    final resp = await _api.get('/reports/yearly', params: {
      if (year != null) 'year': year,
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCompare() async {
    final resp = await _api.get('/reports/compare');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getChartData({String? period}) async {
    final resp = await _api.get('/reports/chart', params: {
      if (period != null) 'period': period,
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCashierActivity({String? date}) async {
    final resp = await _api.get('/reports/cashier-activity', params: {
      if (date != null) 'date': date,
    });
    return resp.data as Map<String, dynamic>;
  }

  /// type: pdf | excel
  Future<List<int>> export(String type, {String? startDate, String? endDate}) async {
    final resp = await _api.get('/reports/export/$type', params: {
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    });
    return resp.data as List<int>;
  }
}
