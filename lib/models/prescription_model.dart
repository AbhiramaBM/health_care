class PrescriptionModel {
  final String id;
  final String patientId;
  final String? doctorName;
  final String? doctorId;
  final String? diagnosis;
  final List<MedicationModel> medications;
  final String? notes;
  final DateTime createdAt;
  final String? status;

  PrescriptionModel({
    required this.id,
    required this.patientId,
    this.doctorName,
    this.doctorId,
    this.diagnosis,
    required this.medications,
    this.notes,
    required this.createdAt,
    this.status,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    var medsList = <MedicationModel>[];
    if (json['medications'] is List) {
      medsList = (json['medications'] as List)
          .map((m) => MedicationModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } else if (json['name'] != null || json['medicationName'] != null) {
      // Single medication object formatted as prescription
      medsList.add(MedicationModel.fromJson(json));
    }

    return PrescriptionModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      doctorName: (json['doctorName'] ?? json['doctor']?['name'])?.toString(),
      doctorId: json['doctorId']?.toString(),
      diagnosis: json['diagnosis']?.toString(),
      medications: medsList,
      notes: (json['notes'] ?? json['instructions'])?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: (json['status'] ?? 'Active').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorName': doctorName,
      'doctorId': doctorId,
      'diagnosis': diagnosis,
      'medications': medications.map((m) => m.toJson()).toList(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }
}

class MedicationModel {
  final String id;
  final String name;
  final String? dosage;
  final String? frequency; // e.g. "Twice a day", "After meals"
  final String? instructions;
  final String? duration;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;

  MedicationModel({
    required this.id,
    required this.name,
    this.dosage,
    this.frequency,
    this.instructions,
    this.duration,
    this.startDate,
    this.endDate,
    this.isActive = true,
  });

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: (json['medicineName'] ?? json['name'] ?? json['medicationName'] ?? 'Medication').toString(),
      dosage: json['dose']?.toString() ?? json['dosage']?.toString(),
      frequency: json['frequency']?.toString(),
      instructions: (json['instructions'] ?? json['notes'])?.toString(),
      duration: json['duration']?.toString(),
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'instructions': instructions,
      'duration': duration,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
    };
  }
}
