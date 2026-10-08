import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/clinical_note_model.dart';

class ClinicalNoteService {
  final ApiClient _client = ApiClient();

  /// Add a clinical note: POST /notes
  Future<ClinicalNoteModel> addNote({
    required String targetType, // PATIENT_PROFILE | DAILY_LOG | WEEKLY_LOG | ALERT
    required String targetId,
    required String patientId,
    required String content,
    String noteType = 'GENERAL',
    String urgency = 'NORMAL',
  }) async {
    // Backend strictly accepts: DIETARY, MEDICATION, LIFESTYLE, GENERAL
    String mappedNoteType = noteType.trim().toUpperCase();
    if (mappedNoteType == 'CLINICAL' || mappedNoteType.isEmpty) {
      mappedNoteType = 'GENERAL';
    } else if (mappedNoteType != 'DIETARY' &&
        mappedNoteType != 'MEDICATION' &&
        mappedNoteType != 'LIFESTYLE' &&
        mappedNoteType != 'GENERAL') {
      mappedNoteType = 'GENERAL';
    }

    final resolvedPatientId = patientId.isNotEmpty
        ? patientId
        : (targetType == 'PATIENT_PROFILE' ? targetId : patientId);

    final response = await _client.post(
      ApiEndpoints.notes,
      data: {
        'targetType': targetType,
        'targetId': targetId,
        'patientId': resolvedPatientId,
        'content': content,
        'noteType': mappedNoteType,
        'urgency': urgency,
      },
    );
    final data = response.data['note'] ?? response.data;
    return ClinicalNoteModel.fromJson(Map<String, dynamic>.from(data));
  }

  /// Get all notes for a patient: GET /notes/patient/:patientId
  Future<List<ClinicalNoteModel>> getPatientNotes(String patientId) async {
    final response = await _client.get(ApiEndpoints.notesByPatient(patientId));
    return _parseNotesList(response.data);
  }

  /// Add note for a patient profile: helper for POST /notes
  Future<ClinicalNoteModel> addPatientNote({
    required String patientId,
    required String content,
    String? category,
  }) async {
    return addNote(
      targetType: 'PATIENT_PROFILE',
      targetId: patientId,
      patientId: patientId,
      content: content,
      noteType: category ?? 'GENERAL',
    );
  }

  /// Get notes for a daily log: GET /notes/DAILY_LOG/:logId
  Future<List<ClinicalNoteModel>> getLogNotes(String logId) async {
    final response = await _client.get(ApiEndpoints.notesByDailyLog(logId));
    return _parseNotesList(response.data);
  }

  /// Add a note to a daily log: POST /notes
  Future<ClinicalNoteModel> addLogNote({
    required String logId,
    required String patientId,
    required String content,
  }) async {
    return addNote(
      targetType: 'DAILY_LOG',
      targetId: logId,
      patientId: patientId,
      content: content,
    );
  }

  /// Get notes for an alert: GET /notes/ALERT/:alertId
  Future<List<ClinicalNoteModel>> getAlertNotes(String alertId) async {
    final response = await _client.get(ApiEndpoints.notesByAlert(alertId));
    return _parseNotesList(response.data);
  }

  /// Add a note to an alert: POST /notes
  Future<ClinicalNoteModel> addAlertNote({
    required String alertId,
    required String patientId,
    required String content,
  }) async {
    return addNote(
      targetType: 'ALERT',
      targetId: alertId,
      patientId: patientId,
      content: content,
    );
  }

  List<ClinicalNoteModel> _parseNotesList(dynamic data) {
    List list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['notes'] is List) {
      list = data['notes'];
    } else if (data is Map && data['data'] is List) {
      list = data['data'];
    } else {
      list = [];
    }

    return list
        .map((n) => ClinicalNoteModel.fromJson(Map<String, dynamic>.from(n)))
        .toList();
  }
}
