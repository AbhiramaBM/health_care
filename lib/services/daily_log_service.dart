import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/daily_log_model.dart';

class DailyLogService {
  final ApiClient _client = ApiClient();

  /// List daily logs for patient: GET /logs/daily/:patientId?page=1&limit=30
  Future<List<DailyLogModel>> getDailyLogs(
    String patientId, {
    int page = 1,
    int limit = 30,
  }) async {
    final response = await _client.get(
      ApiEndpoints.logsDaily(patientId),
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    final dynamic data = response.data;
    List list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['logs'] is List) {
      list = data['logs'];
    } else if (data is Map && data['dailyLogs'] is List) {
      list = data['dailyLogs'];
    } else if (data is Map && data['data'] is List) {
      list = data['data'];
    } else {
      list = [];
    }

    return list
        .map((log) => DailyLogModel.fromJson(Map<String, dynamic>.from(log)))
        .toList();
  }

  /// Get daily log by UUID: GET /logs/daily/id/:logId
  Future<DailyLogModel> getDailyLogById(String logId) async {
    final response = await _client.get(ApiEndpoints.logDailyById(logId));
    final data = response.data['log'] ?? response.data;
    return DailyLogModel.fromJson(Map<String, dynamic>.from(data));
  }

  /// Get daily log by date: GET /logs/daily/:patientId/:date
  Future<DailyLogModel?> getDailyLogByDate(String patientId, String date) async {
    try {
      final response = await _client.get(ApiEndpoints.logsDailyByDate(patientId, date));
      final data = response.data['log'] ?? response.data;
      return DailyLogModel.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }

  /// Get weekly logs for patient: GET /logs/weekly/:patientId
  Future<List<dynamic>> getWeeklyLogs(String patientId) async {
    final response = await _client.get(ApiEndpoints.logsWeekly(patientId));
    final data = response.data;
    if (data is List) return data;
    if (data is Map && data['logs'] is List) return data['logs'];
    return [];
  }

  /// Get missed logs for patient: GET /logs/missed/:patientId
  Future<Map<String, dynamic>> getMissedLogs(String patientId) async {
    final response = await _client.get(ApiEndpoints.logsMissed(patientId));
    return response.data is Map<String, dynamic>
        ? response.data
        : <String, dynamic>{};
  }
}
