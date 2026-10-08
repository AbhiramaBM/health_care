class DailyLogModel {
  final String id;
  final String patientId;
  final DateTime date;
  final double? bloodPressureSystolic;
  final double? bloodPressureDiastolic;
  final double? heartRate;
  final double? bloodSugar;
  final double? fbs;
  final double? ppbs;
  final double? temperature;
  final double? weight;
  final List<String> symptoms;
  final String? notes;
  final String? recordedBy;

  // Meal photos
  final String? breakfastPhoto;
  final String? lunchPhoto;
  final String? dinnerPhoto;
  final String? snackPhoto;
  final String? juicePhoto;

  DailyLogModel({
    required this.id,
    required this.patientId,
    required this.date,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.heartRate,
    this.bloodSugar,
    this.fbs,
    this.ppbs,
    this.temperature,
    this.weight,
    this.symptoms = const [],
    this.notes,
    this.recordedBy,
    this.breakfastPhoto,
    this.lunchPhoto,
    this.dinnerPhoto,
    this.snackPhoto,
    this.juicePhoto,
  });

  factory DailyLogModel.fromJson(Map<String, dynamic> json) {
    return DailyLogModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
      bloodPressureSystolic: _toDouble(json['bloodPressureSystolic'] ?? json['systolic']),
      bloodPressureDiastolic: _toDouble(json['bloodPressureDiastolic'] ?? json['diastolic']),
      heartRate: _toDouble(json['heartRate'] ?? json['pulse']),
      bloodSugar: _toDouble(json['bloodSugar'] ?? json['glucose'] ?? json['fbs']),
      fbs: _toDouble(json['fbs'] ?? json['fastingSugar'] ?? json['fastingBloodSugar']),
      ppbs: _toDouble(json['ppbs'] ?? json['postPrandialSugar']),
      temperature: _toDouble(json['temperature'] ?? json['temp']),
      weight: _toDouble(json['weight']),
      symptoms: (json['symptoms'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      notes: (json['notes'] ?? json['remarks'])?.toString(),
      recordedBy: (json['recordedBy'] ?? json['staffName'])?.toString(),
      breakfastPhoto: json['breakfastPhoto']?.toString(),
      lunchPhoto: json['lunchPhoto']?.toString(),
      dinnerPhoto: json['dinnerPhoto']?.toString(),
      snackPhoto: json['snackPhoto']?.toString(),
      juicePhoto: json['juicePhoto']?.toString(),
    );
  }

  static double? _toDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'date': date.toIso8601String(),
      'bloodPressureSystolic': bloodPressureSystolic,
      'bloodPressureDiastolic': bloodPressureDiastolic,
      'heartRate': heartRate,
      'bloodSugar': bloodSugar,
      'fbs': fbs,
      'ppbs': ppbs,
      'temperature': temperature,
      'weight': weight,
      'symptoms': symptoms,
      'notes': notes,
      'recordedBy': recordedBy,
      'breakfastPhoto': breakfastPhoto,
      'lunchPhoto': lunchPhoto,
      'dinnerPhoto': dinnerPhoto,
      'snackPhoto': snackPhoto,
      'juicePhoto': juicePhoto,
    };
  }
}
