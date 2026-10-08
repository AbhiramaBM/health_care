class ConversationModel {
  final String id;
  final String? title;
  final String? type; // DIRECT or GROUP
  final List<dynamic> participants;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String? avatarUrl;

  ConversationModel({
    required this.id,
    this.title,
    this.type,
    this.participants = const [],
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.avatarUrl,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    String? messageText;
    DateTime? messageDate;

    if (json['lastMessage'] is Map) {
      final lm = json['lastMessage'] as Map;
      messageText = lm['content']?.toString();
      if (lm['createdAt'] != null) {
        messageDate = DateTime.tryParse(lm['createdAt'].toString());
      }
    } else if (json['lastMessage'] != null) {
      messageText = json['lastMessage'].toString();
    }

    if (messageDate == null && json['lastMessageAt'] != null) {
      messageDate = DateTime.tryParse(json['lastMessageAt'].toString());
    } else if (messageDate == null && json['updatedAt'] != null) {
      messageDate = DateTime.tryParse(json['updatedAt'].toString());
    }

    // Participants / members
    final membersList = json['members'] is List
        ? json['members'] as List
        : (json['participants'] is List ? json['participants'] as List : []);

    return ConversationModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: (json['name'] ?? json['title'] ?? 'Team Chat').toString(),
      type: json['type']?.toString(),
      participants: membersList,
      lastMessage: messageText,
      lastMessageAt: messageDate,
      unreadCount: json['unreadCount'] is int ? json['unreadCount'] : 0,
      avatarUrl: (json['avatarUrl'] ?? json['avatar'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'unreadCount': unreadCount,
      'avatarUrl': avatarUrl,
    };
  }
}

class ChatMessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String? senderName;
  final String? senderRole;
  final String content;
  final String? mediaUrl;
  final DateTime createdAt;
  final bool isDelivered;
  final bool isRead;
  final bool isDeleted;

  ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    this.senderName,
    this.senderRole,
    required this.content,
    this.mediaUrl,
    required this.createdAt,
    this.isDelivered = false,
    this.isRead = false,
    this.isDeleted = false,
  });

  String get conversationId => roomId;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final senderObj = json['sender'] is Map ? json['sender'] as Map : null;

    return ChatMessageModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? json['conversationId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? senderObj?['id']?.toString() ?? '',
      senderName: (json['senderName'] ?? senderObj?['name'])?.toString(),
      senderRole: (json['senderRole'] ?? senderObj?['role'])?.toString(),
      content: (json['content'] ?? json['message'] ?? '').toString(),
      mediaUrl: (json['mediaUrl'] ?? json['attachmentUrl'])?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : (json['timestamp'] != null
              ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
              : DateTime.now()),
      isDelivered: json['isDelivered'] == true || json['deliveredAt'] != null,
      isRead: json['isRead'] == true,
      isDeleted: json['isDeleted'] == true,
    );
  }

  ChatMessageModel copyWith({
    bool? isDelivered,
    bool? isRead,
    bool? isDeleted,
    String? content,
  }) {
    return ChatMessageModel(
      id: id,
      roomId: roomId,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      content: content ?? this.content,
      mediaUrl: mediaUrl,
      createdAt: createdAt,
      isDelivered: isDelivered ?? this.isDelivered,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'content': content,
      'mediaUrl': mediaUrl,
      'createdAt': createdAt.toIso8601String(),
      'isDelivered': isDelivered,
      'isRead': isRead,
      'isDeleted': isDeleted,
    };
  }
}
