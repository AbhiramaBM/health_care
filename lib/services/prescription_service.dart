import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/prescription_model.dart';

class PrescriptionService {
  final ApiClient _client = ApiClient();

  /// Get all prescriptions for a patient: GET /prescriptions/patient/:patientId
  Future<List<PrescriptionModel>> getPrescriptions(String patientId) async {
    final response = await _client.get(
      ApiEndpoints.prescriptionsByPatient(patientId),
    );

    final dynamic data = response.data;
    List list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['prescriptions'] is List) {
      list = data['prescriptions'];
    } else if (data is Map && data['data'] is List) {
      list = data['data'];
    } else {
      list = [];
    }

    return list
        .map((p) => PrescriptionModel.fromJson(Map<String, dynamic>.from(p)))
        .toList();
  }

  /// Get specific prescription: GET /prescriptions/:prescriptionId
  Future<PrescriptionModel> getPrescriptionById(String prescriptionId) async {
    final response = await _client.get(
      ApiEndpoints.prescriptionById(prescriptionId),
    );
    final data = response.data['prescription'] ?? response.data;
    return PrescriptionModel.fromJson(Map<String, dynamic>.from(data));
  }

  /// Create prescription DRAFT (DOCTOR only): POST /prescriptions
  Future<PrescriptionModel> createPrescription({
    required String patientId,
    required List<Map<String, dynamic>> medications,
    String? advice,
    String? internalNotes,
  }) async {
    final response = await _client.post(
      ApiEndpoints.prescriptions,
      data: {
        'patientId': patientId,
        'medications': medications,
        if (advice != null) 'advice': advice,
        if (internalNotes != null) 'internalNotes': internalNotes,
      },
    );
    final data = response.data['prescription'] ?? response.data;
    return PrescriptionModel.fromJson(Map<String, dynamic>.from(data));
  }

  /// Send prescription DRAFT -> SENT: POST /prescriptions/:prescriptionId/send
  Future<Map<String, dynamic>> sendPrescription(String prescriptionId) async {
    final response = await _client.post(
      ApiEndpoints.prescriptionSend(prescriptionId),
    );
    return response.data is Map<String, dynamic>
        ? response.data
        : {'message': response.data.toString()};
  }

  /// Extract active medications from patient prescriptions
  Future<List<MedicationModel>> getMedications(String patientId) async {
    final prescriptions = await getPrescriptions(patientId);
    final allMeds = <MedicationModel>[];
    for (final rx in prescriptions) {
      allMeds.addAll(rx.medications);
    }
    return allMeds;
  }
}
