import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import 'user_service.dart';

class ChatService {
  final ApiClient _client = ApiClient();
  final UserService _userService = UserService();

  /// List my rooms: GET /chat/rooms
  Future<List<ConversationModel>> getConversations() async {
    final response = await _client.get(ApiEndpoints.chatRooms);

    final dynamic data = response.data;
    List list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['rooms'] is List) {
      list = data['rooms'];
    } else if (data is Map && data['conversations'] is List) {
      list = data['conversations'];
    } else if (data is Map && data['data'] is List) {
      list = data['data'];
    } else {
      list = [];
    }

    return list
        .map((c) => ConversationModel.fromJson(Map<String, dynamic>.from(c)))
        .toList();
  }

  /// Get or create DM room: POST /chat/rooms/direct
  Future<ConversationModel> getOrCreateDirectRoom(String userId) async {
    final response = await _client.post(
      ApiEndpoints.chatRoomsDirect,
      data: {
        'targetUserId': userId,
        'userId': userId,
      },
    );
    final data = response.data['room'] ?? response.data;
    return ConversationModel.fromJson(Map<String, dynamic>.from(data));
  }

  /// Get room detail: GET /chat/rooms/:roomId
  Future<ConversationModel> getConversationById(String roomId) async {
    final response = await _client.get(ApiEndpoints.chatRoomById(roomId));
    final data = response.data['room'] ?? response.data;
    return ConversationModel.fromJson(Map<String, dynamic>.from(data));
  }

  /// Get message history: GET /chat/rooms/:roomId/messages?page=1&limit=50
  Future<List<ChatMessageModel>> getMessages(
    String roomId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _client.get(
      ApiEndpoints.chatRoomMessages(roomId),
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    final dynamic data = response.data;
    List list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['messages'] is List) {
      list = data['messages'];
    } else if (data is Map && data['data'] is List) {
      list = data['data'];
    } else {
      list = [];
    }

    return list
        .map((m) => ChatMessageModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// Send message via REST: POST /chat/rooms/:roomId/messages
  Future<ChatMessageModel> sendMessage({
    required String roomId,
    required String content,
    List<Map<String, dynamic>> mentions = const [],
    List<Map<String, dynamic>> references = const [],
  }) async {
    final response = await _client.post(
      ApiEndpoints.chatRoomMessages(roomId),
      data: {
        'content': content,
        'mentions': mentions,
        'references': references,
      },
    );
    final data = response.data['message'] ?? response.data;
    return ChatMessageModel.fromJson(Map<String, dynamic>.from(data));
  }

  /// Get staff members available for chat: GET /admin/staff
  Future<List<UserModel>> getChatUsers() async {
    return _userService.getUsers();
  }

  /// Get batches: GET /batches
  Future<List<dynamic>> getChatBatches() async {
    final response = await _client.get(ApiEndpoints.batches);
    final dynamic data = response.data;
    if (data is List) return data;
    if (data is Map && data['batches'] is List) return data['batches'];
    return [];
  }
}
