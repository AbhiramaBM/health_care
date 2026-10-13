import '../core/utils/message_formatter.dart';

class CommunityModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int memberCount;
  final String? type;
  final String? status;
  final String? batchId;
  final String? batchCode;
  final String? creatorId;
  final DateTime createdAt;

  CommunityModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.memberCount = 0,
    this.type,
    this.status,
    this.batchId,
    this.batchCode,
    this.creatorId,
    required this.createdAt,
  });

  /// User-facing sentence-case status
  String get displayStatus {
    if (status == null || status!.isEmpty) return 'Active';
    final s = status!.toUpperCase();
    if (s == 'ACTIVE') return 'Active';
    if (s == 'UPCOMING') return 'Upcoming';
    if (s == 'COMPLETED') return 'Completed';
    return MessageFormatter.toSentenceCase(status!);
  }

  /// User-facing sentence-case type
  String get displayType {
    if (type == 'COMMUNITY_GLOBAL') return 'Global community';
    if (type == 'COMMUNITY_BATCH') return 'Batch community';
    return 'Community';
  }

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    // Parse name
    String parsedName = 'Community';
    if (json['name'] != null && json['name'].toString().isNotEmpty) {
      parsedName = json['name'].toString();
    } else if (json['batchCode'] != null && json['batchCode'].toString().isNotEmpty) {
      parsedName = 'Batch ${json['batchCode']}';
    } else if (json['title'] != null && json['title'].toString().isNotEmpty) {
      parsedName = json['title'].toString();
    }

    // Parse member count
    int count = 0;
    if (json['memberCount'] is int) {
      count = json['memberCount'] as int;
    } else if (json['totalEnrolments'] is int) {
      count = json['totalEnrolments'] as int;
    } else if (json['activeCount'] is int) {
      count = json['activeCount'] as int;
    }

    // Parse description/notes
    final desc = (json['description'] ?? json['notes'])?.toString();

    // Parse image
    final img = (json['imageUrl'] ?? json['avatarUrl'] ?? json['image'])?.toString();

    // Parse creation date
    DateTime date = DateTime.now();
    if (json['createdAt'] != null) {
      date = DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
    } else if (json['startDate'] != null) {
      date = DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now();
    }

    return CommunityModel(
      id: json['id']?.toString() ?? '',
      name: parsedName,
      description: desc,
      imageUrl: img,
      memberCount: count,
      type: json['type']?.toString() ?? 'COMMUNITY_BATCH',
      status: json['status']?.toString() ?? 'ACTIVE',
      batchId: json['batchId']?.toString(),
      batchCode: json['batchCode']?.toString(),
      creatorId: (json['createdBy'] ?? json['creatorId'] ?? json['authorId'])?.toString(),
      createdAt: date,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'memberCount': memberCount,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (batchId != null) 'batchId': batchId,
      if (batchCode != null) 'batchCode': batchCode,
      if (creatorId != null) 'createdBy': creatorId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  CommunityModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    int? memberCount,
    String? type,
    String? status,
    String? batchId,
    String? batchCode,
    String? creatorId,
    DateTime? createdAt,
  }) {
    return CommunityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      memberCount: memberCount ?? this.memberCount,
      type: type ?? this.type,
      status: status ?? this.status,
      batchId: batchId ?? this.batchId,
      batchCode: batchCode ?? this.batchCode,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
