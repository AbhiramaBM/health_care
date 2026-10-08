import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/patient_model.dart';

class PatientService {
  final ApiClient _client = ApiClient();

  /// Get list of patients: GET /patients?page=1&limit=20&search=...
  Future<List<PatientModel>> getPatients({
    int page = 1,
    int limit = 50,
    String? search,
    String? batch,
    bool? onboardingComplete,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (batch != null && batch.isNotEmpty) query['batch'] = batch;
    if (onboardingComplete != null) {
      query['onboardingComplete'] = onboardingComplete.toString();
    }

    final response = await _client.get(
      ApiEndpoints.patients,
      queryParameters: query,
    );

    final dynamic data = response.data;
    List list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['patients'] is List) {
      list = data['patients'];
    } else if (data is Map && data['data'] is List) {
      list = data['data'];
    } else {
      list = [];
    }

    return list
        .map((p) => PatientModel.fromJson(Map<String, dynamic>.from(p)))
        .toList();
  }

  /// Get patient profile: GET /patients/:patientId/profile
  Future<PatientModel> getPatientById(String patientId) async {
    final response = await _client.get(ApiEndpoints.patientProfile(patientId));
    final dynamic data = response.data;
    final Map<String, dynamic> patientJson = (data is Map && data['profile'] != null)
        ? Map<String, dynamic>.from(data['profile'])
        : (data is Map && data['patient'] != null)
            ? Map<String, dynamic>.from(data['patient'])
            : (data is Map ? Map<String, dynamic>.from(data) : {});
    return PatientModel.fromJson(patientJson);
  }

  /// Search patients: GET /patients?search=...
  Future<List<PatientModel>> searchPatients(String query) async {
    return getPatients(search: query);
  }

  /// List batches: GET /batches
  Future<List<dynamic>> getPatientBatches() async {
    final response = await _client.get(ApiEndpoints.batches);
    final dynamic data = response.data;
    if (data is List) {
      return data;
    } else if (data is Map && data['batches'] is List) {
      return data['batches'];
    } else if (data is Map && data['data'] is List) {
      return data['data'];
    }
    return [];
  }

  /// Get batch by ID: GET /batches/:batchId
  Future<Map<String, dynamic>> getBatchById(String batchId) async {
    final response = await _client.get(ApiEndpoints.batchById(batchId));
    final data = response.data['batch'] ?? response.data;
    return Map<String, dynamic>.from(data);
  }
}
