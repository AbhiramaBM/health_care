class AlertModel {
  final String id;
  final String? patientId;
  final String? patientName;
  final String? patientPhone;
  final String title;
  final String? description;
  final String severity; // URGENT, WATCH, INFO / high, medium, low
  final String status; // PENDING, ACKNOWLEDGED, IGNORED
  final bool isAcknowledged;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  AlertModel({
    required this.id,
    this.patientId,
    this.patientName,
    this.patientPhone,
    required this.title,
    this.description,
    required this.severity,
    required this.status,
    this.isAcknowledged = false,
    required this.createdAt,
    this.data,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    final isAck = json['acknowledged'] == true ||
        (json['status']?.toString().toLowerCase() == 'acknowledged');

    final pat = json['patient'] is Map ? json['patient'] : null;

    return AlertModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? pat?['id']?.toString(),
      patientName: (json['patientName'] ?? pat?['name'])?.toString(),
      patientPhone: (json['patientPhone'] ?? pat?['phone'])?.toString(),
      title: (json['type'] ?? json['title'] ?? 'Clinical Alert').toString(),
      description: (json['message'] ?? json['description'])?.toString(),
      severity: (json['priority'] ?? json['severity'] ?? 'URGENT').toString(),
      status: isAck ? 'acknowledged' : (json['status'] ?? 'pending').toString().toLowerCase(),
      isAcknowledged: isAck,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      data: json['data'] is Map<String, dynamic> ? json['data'] : null,
    );
  }

  AlertModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? patientPhone,
    String? title,
    String? description,
    String? severity,
    String? status,
    bool? isAcknowledged,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return AlertModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'title': title,
      'description': description,
      'severity': severity,
      'status': status,
      'acknowledged': isAcknowledged,
      'createdAt': createdAt.toIso8601String(),
      if (data != null) 'data': data,
    };
  }
}
