import '../core/utils/message_formatter.dart';

class AlertModel {
  final String id;
  final String? patientId;
  final String? patientName;
  final String? patientPhone;
  final String? type;
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
    this.type,
    required this.title,
    this.description,
    required this.severity,
    required this.status,
    this.isAcknowledged = false,
    required this.createdAt,
    this.data,
  });

  /// User-facing sentence-case title without technical codes
  String get displayTitle => MessageFormatter.formatAlertTitle(type ?? title, title);

  /// User-facing complete sentence description
  String get displayDescription => MessageFormatter.formatAlertDescription(type ?? title, description);

  /// User-facing sentence-case severity (e.g. Critical, Urgent, Watch, Info)
  String get displaySeverity => MessageFormatter.formatSeverity(severity);

  /// User-facing sentence-case status (e.g. Acknowledged, Pending)
  String get displayStatus => MessageFormatter.formatAlertStatus(status, isAcknowledged: isAcknowledged);

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    final isAck = json['acknowledged'] == true ||
        (json['status']?.toString().toLowerCase() == 'acknowledged');

    final pat = json['patient'] is Map ? json['patient'] : null;
    final rawType = json['type']?.toString();
    final rawTitle = (json['title'] ?? rawType ?? 'Clinical Alert').toString();
    final rawDesc = (json['message'] ?? json['description'])?.toString();

    return AlertModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? pat?['id']?.toString(),
      patientName: (json['patientName'] ?? pat?['name'])?.toString(),
      patientPhone: (json['patientPhone'] ?? pat?['phone'])?.toString(),
      type: rawType,
      title: rawTitle,
      description: rawDesc,
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
    String? type,
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
      type: type ?? this.type,
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
      if (type != null) 'type': type,
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
