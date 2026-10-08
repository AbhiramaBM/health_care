class ClinicalNoteModel {
  final String id;
  final String? patientId;
  final String? logId;
  final String? alertId;
  final String content;
  final String? authorId;
  final String? authorName;
  final DateTime createdAt;
  final String? category;

  ClinicalNoteModel({
    required this.id,
    this.patientId,
    this.logId,
    this.alertId,
    required this.content,
    this.authorId,
    this.authorName,
    required this.createdAt,
    this.category,
  });

  factory ClinicalNoteModel.fromJson(Map<String, dynamic> json) {
    final authorMap = json['author'] is Map ? json['author'] as Map : null;
    final parsedAuthorName = (json['authorName'] ?? json['userName'] ?? authorMap?['name'])?.toString();
    final parsedAuthorId = (json['authorId'] ?? json['userId'] ?? authorMap?['id'])?.toString();

    return ClinicalNoteModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      patientId: json['patientId']?.toString(),
      logId: json['logId']?.toString(),
      alertId: json['alertId']?.toString(),
      content: (json['content'] ?? json['note'] ?? json['text'] ?? '').toString(),
      authorId: parsedAuthorId,
      authorName: parsedAuthorName,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      category: (json['category'] ?? json['noteType'] ?? json['type'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (patientId != null) 'patientId': patientId,
      if (logId != null) 'logId': logId,
      if (alertId != null) 'alertId': alertId,
      'content': content,
      if (authorId != null) 'authorId': authorId,
      if (authorName != null) 'authorName': authorName,
      'createdAt': createdAt.toIso8601String(),
      if (category != null) 'category': category,
    };
  }
}
