import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/alert_model.dart';

class AlertService {
  final ApiClient _client = ApiClient();

  /// Get alerts list: GET /alerts
  Future<List<AlertModel>> getAlerts({
    bool acknowledged = false,
    String? priority,
    String? patientId,
    int page = 1,
    int limit = 50,
  }) async {
    final query = <String, dynamic>{
      'acknowledged': acknowledged.toString(),
      'page': page,
      'limit': limit,
    };
    if (priority != null && priority.isNotEmpty) query['priority'] = priority;
    if (patientId != null && patientId.isNotEmpty) query['patientId'] = patientId;

    final response = await _client.get(
      ApiEndpoints.alerts,
      queryParameters: query,
    );

    final dynamic data = response.data;
    List list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['alerts'] is List) {
      list = data['alerts'];
    } else if (data is Map && data['data'] is List) {
      list = data['data'];
    } else {
      list = [];
    }

    return list
        .map((a) => AlertModel.fromJson(Map<String, dynamic>.from(a)))
        .toList();
  }

  /// Get alert by ID: GET /alerts/:alertId
  Future<AlertModel> getAlertById(String alertId) async {
    final response = await _client.get(ApiEndpoints.alertById(alertId));
    final data = response.data['alert'] ?? response.data;
    return AlertModel.fromJson(Map<String, dynamic>.from(data));
  }

  /// Acknowledge alert — Ignore: POST /alerts/:id/acknowledge
  Future<AlertModel> ignoreAlert(String alertId, {String? noteContent}) async {
    final response = await _client.post(
      ApiEndpoints.alertAcknowledge(alertId),
      data: {
        'action': 'IGNORED',
        'noteContent': noteContent ?? 'Alert ignored / reviewed.',
      },
    );
    final data = response.data['alert'] ?? response.data;
    return AlertModel.fromJson(Map<String, dynamic>.from(data));
  }

  /// Acknowledge alert — Message patient via WhatsApp: POST /alerts/:id/acknowledge
  Future<AlertModel> messagePatientAlert(
    String alertId, {
    required String messageText,
  }) async {
    final response = await _client.post(
      ApiEndpoints.alertAcknowledge(alertId),
      data: {
        'action': 'MESSAGE_SENT',
        'messageText': messageText,
      },
    );
    final data = response.data['alert'] ?? response.data;
    return AlertModel.fromJson(Map<String, dynamic>.from(data));
  }

  /// Acknowledge alert — Change medication (DOCTOR only): POST /alerts/:id/acknowledge
  Future<AlertModel> changeMedicationAlert(
    String alertId, {
    required String noteContent,
    required List<Map<String, dynamic>> medications,
  }) async {
    final response = await _client.post(
      ApiEndpoints.alertAcknowledge(alertId),
      data: {
        'action': 'MEDICATION_CHANGED',
        'noteContent': noteContent,
        'medications': medications,
      },
    );
    final data = response.data['alert'] ?? response.data;
    return AlertModel.fromJson(Map<String, dynamic>.from(data));
  }

  /// Acknowledge alert generic: POST /alerts/:id/acknowledge
  Future<AlertModel> acknowledgeAlert(
    String alertId, {
    String? noteContent,
  }) async {
    final response = await _client.post(
      ApiEndpoints.alertAcknowledge(alertId),
      data: {
        'action': 'IGNORED',
        'noteContent': (noteContent != null && noteContent.trim().isNotEmpty)
            ? noteContent.trim()
            : 'Alert acknowledged by doctor.',
      },
    );
    final data = response.data['alert'] ?? response.data;
    return AlertModel.fromJson(Map<String, dynamic>.from(data));
  }
}
