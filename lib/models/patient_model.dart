class PatientModel {
  final String id;
  final String name;
  final String? patientDisplayId;
  final int? age;
  final String? gender;
  final String? phone;
  final String? batch;
  final String? condition;
  final String? status;
  final double? hba1c;
  final double? bmi;
  final DateTime? admittedAt;
  final String? roomNumber;
  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? extra;
  final DateTime? lastLogDate;
  final String? glucoseStatus;
  final bool hasAlert;

  PatientModel({
    required this.id,
    required this.name,
    this.patientDisplayId,
    this.age,
    this.gender,
    this.phone,
    this.batch,
    this.condition,
    this.status,
    this.hba1c,
    this.bmi,
    this.admittedAt,
    this.roomNumber,
    this.profile,
    this.extra,
    this.lastLogDate,
    this.glucoseStatus,
    this.hasAlert = false,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    final profileData = json['profile'] is Map<String, dynamic>
        ? json['profile'] as Map<String, dynamic>
        : (json['profile'] is Map ? Map<String, dynamic>.from(json['profile']) : null);

    final userData = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : (profileData?['user'] is Map ? Map<String, dynamic>.from(profileData!['user']) : null);

    final rawAge = json['age'] ?? profileData?['age'];
    final int? parsedAge = rawAge is int
        ? rawAge
        : int.tryParse(rawAge?.toString() ?? '');

    final rawHba1c = profileData?['hba1c'] ?? json['hba1c'];
    final double? parsedHba1c = rawHba1c is num
        ? rawHba1c.toDouble()
        : double.tryParse(rawHba1c?.toString() ?? '');

    final rawBmi = profileData?['bmi'] ?? json['bmi'];
    final double? parsedBmi = rawBmi is num
        ? rawBmi.toDouble()
        : double.tryParse(rawBmi?.toString() ?? '');

    final String resolvedId = (json['userId'] ?? json['id'] ?? json['_id'] ?? profileData?['userId'] ?? profileData?['id'] ?? '')?.toString() ?? '';
    final String resolvedName = (json['name'] ?? userData?['name'] ?? json['fullName'] ?? 'Patient').toString();
    final String? resolvedPhone = (json['phone'] ?? userData?['phone'] ?? json['contactNumber'])?.toString();
    final String? resolvedDisplayId = json['patientDisplayId']?.toString() ?? profileData?['patientDisplayId']?.toString();

    final lastLogJson = json['lastLog'] is Map ? json['lastLog'] : null;
    final rawLastLogDate = lastLogJson?['logDate'] ?? json['lastLogDate'] ?? profileData?['lastLogDate'];
    final DateTime? parsedLastLogDate = rawLastLogDate != null
        ? DateTime.tryParse(rawLastLogDate.toString())
        : null;

    final String? resolvedGlucoseStatus = json['glucoseStatus']?.toString() ??
        lastLogJson?['glucoseStatus']?.toString() ??
        profileData?['glucoseStatus']?.toString() ??
        (parsedHba1c != null
            ? (parsedHba1c > 8.0
                ? 'CRITICAL'
                : (parsedHba1c > 7.0 ? 'WARNING' : 'NORMAL'))
            : null);

    final bool resolvedHasAlert = json['hasAlert'] == true ||
        (json['alertCount'] is num && (json['alertCount'] as num) > 0) ||
        (json['alerts'] is List && (json['alerts'] as List).isNotEmpty);

    return PatientModel(
      id: resolvedId,
      name: resolvedName,
      patientDisplayId: resolvedDisplayId,
      age: parsedAge,
      gender: (json['gender'] ?? profileData?['gender'])?.toString(),
      phone: resolvedPhone,
      batch: (json['batch'] ?? json['batchId'] ?? json['batchCode'])?.toString(),
      condition: (json['condition'] ?? profileData?['condition'] ?? json['diagnosis'])?.toString(),
      status: (json['status'] ?? 'Active').toString(),
      hba1c: parsedHba1c,
      bmi: parsedBmi,
      admittedAt: json['admittedAt'] != null
          ? DateTime.tryParse(json['admittedAt'].toString())
          : null,
      roomNumber: json['roomNumber']?.toString(),
      profile: profileData,
      extra: json,
      lastLogDate: parsedLastLogDate,
      glucoseStatus: resolvedGlucoseStatus,
      hasAlert: resolvedHasAlert,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (patientDisplayId != null) 'patientDisplayId': patientDisplayId,
      'age': age,
      'gender': gender,
      'phone': phone,
      'batch': batch,
      'condition': condition,
      'status': status,
      if (hba1c != null) 'hba1c': hba1c,
      if (bmi != null) 'bmi': bmi,
      'admittedAt': admittedAt?.toIso8601String(),
      'roomNumber': roomNumber,
      if (profile != null) 'profile': profile,
    };
  }
}
