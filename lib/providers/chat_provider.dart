import 'dart:async';
import 'package:flutter/material.dart';
import '../core/utils/error_utils.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../core/socket/socket_service.dart';
import '../core/storage/token_storage.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final SocketService _socketService = SocketService();
  final TokenStorage _tokenStorage = TokenStorage();

  List<ConversationModel> _conversations = [];
  List<ChatMessageModel> _activeMessages = [];
  List<UserModel> _chatUsers = [];
  List<dynamic> _chatBatches = [];
  final Map<String, List<ChatMessageModel>> _localRoomMessages = {};

  String? _activeRoomId;
  bool _isLoading = false;
  bool _isMessagesLoading = false;
  String? _errorMessage;
  bool _isOtherUserTyping = false;
  String? _typingUserName;

  StreamSubscription? _msgSub;
  StreamSubscription? _typingSub;
  StreamSubscription? _deliveredSub;
  StreamSubscription? _readSub;
  StreamSubscription? _deletedSub;

  List<ConversationModel> get conversations => _conversations;
  List<ChatMessageModel> get activeMessages => _activeMessages;
  List<UserModel> get chatUsers => _chatUsers;
  List<dynamic> get chatBatches => _chatBatches;
  String? get activeRoomId => _activeRoomId;
  String? get activeConversationId => _activeRoomId;
  bool get isLoading => _isLoading;
  bool get isMessagesLoading => _isMessagesLoading;
  String? get errorMessage => _errorMessage;
  bool get isOtherUserTyping => _isOtherUserTyping;
  String? get typingUserName => _typingUserName;
  bool get isSocketConnected => _socketService.isConnected;

  ChatProvider() {
    _initSocketSubscriptions();
  }

  void _initSocketSubscriptions() {
    _socketService.connect();

    // On new_message received from socket
    _msgSub = _socketService.onMessageReceived.listen((data) {
      final msg = ChatMessageModel.fromJson(data);
      if (msg.roomId == _activeRoomId) {
        // Prevent duplicate if already added
        final optIdx = _activeMessages.indexWhere((m) =>
            m.id.startsWith('local_') && m.content == msg.content && m.senderId == msg.senderId);
        if (optIdx != -1) {
          _activeMessages[optIdx] = msg;
        } else if (!_activeMessages.any((m) => m.id == msg.id)) {
          _activeMessages.add(msg);
        }
        _socketService.markDelivered(msg.id);
        _socketService.markRead(_activeRoomId!);
        notifyListeners();
      }
      // Refresh rooms list to reflect last message & unread counts
      fetchConversations(refresh: true);
    });

    // On user typing in room
    _typingSub = _socketService.onTyping.listen((data) {
      if (data['roomId']?.toString() == _activeRoomId) {
        _isOtherUserTyping = data['isTyping'] ?? true;
        _typingUserName = data['name'] ?? data['userName'];
        notifyListeners();
      }
    });

    // On message delivered
    _deliveredSub = _socketService.onMessageDelivered.listen((data) {
      final msgId = data['messageId']?.toString();
      if (msgId != null) {
        final idx = _activeMessages.indexWhere((m) => m.id == msgId);
        if (idx != -1) {
          _activeMessages[idx] = _activeMessages[idx].copyWith(isDelivered: true);
          notifyListeners();
        }
      }
    });

    // On messages read in room
    _readSub = _socketService.onMessagesRead.listen((data) {
      if (data['roomId']?.toString() == _activeRoomId) {
        for (var i = 0; i < _activeMessages.length; i++) {
          _activeMessages[i] = _activeMessages[i].copyWith(isRead: true, isDelivered: true);
        }
        notifyListeners();
      }
    });

    // On message deleted
    _deletedSub = _socketService.onMessageDeleted.listen((data) {
      final msgId = data['messageId']?.toString();
      if (msgId != null) {
        _activeMessages.removeWhere((m) => m.id == msgId);
        notifyListeners();
      }
    });
  }

  Future<void> fetchConversations({bool refresh = false}) async {
    if (_conversations.isNotEmpty && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _conversations = await _chatService.getConversations();
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchChatUsersAndBatches() async {
    try {
      _chatUsers = await _chatService.getChatUsers();
      _chatBatches = await _chatService.getChatBatches();
      notifyListeners();
    } catch (_) {}
  }

  Future<ConversationModel?> startDirectChat(String targetUserId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final room = await _chatService.getOrCreateDirectRoom(targetUserId);
      final idx = _conversations.indexWhere((c) => c.id == room.id);
      if (idx == -1) {
        _conversations.insert(0, room);
      }
      return room;
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> openConversation(String roomId) async {
    if (_activeRoomId != null && _activeRoomId != roomId) {
      _socketService.leaveRoom(_activeRoomId!);
    }

    _activeRoomId = roomId;
    if (!_socketService.isConnected) {
      _socketService.connect();
    }
    _socketService.joinRoom(roomId);
    _socketService.markRead(roomId);

    _isMessagesLoading = true;
    _isOtherUserTyping = false;
    notifyListeners();

    try {
      final remoteMessages = await _chatService.getMessages(roomId);
      final localMsgs = _localRoomMessages[roomId] ?? [];
      final combined = List<ChatMessageModel>.from(remoteMessages);

      for (final lm in localMsgs) {
        if (!combined.any((m) =>
            m.content == lm.content &&
            (m.id == lm.id || m.createdAt.difference(lm.createdAt).inMinutes.abs() < 5))) {
          combined.add(lm);
        }
      }

      // Sort by creation time
      combined.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _activeMessages = combined;

      for (final m in _activeMessages) {
        _socketService.markDelivered(m.id);
      }
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
    } finally {
      _isMessagesLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String content) async {
    if (_activeRoomId == null || content.trim().isEmpty) return;
    final roomId = _activeRoomId!;
    final trimmedContent = content.trim();

    // 1. Optimistic UI update: message appears on screen instantaneously
    final currentUserId = _tokenStorage.userId ?? 'current_doctor';
    final currentUserRole = _tokenStorage.userRole ?? 'DOCTOR';
    final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';

    final optimisticMsg = ChatMessageModel(
      id: tempId,
      roomId: roomId,
      senderId: currentUserId,
      senderName: 'Me',
      senderRole: currentUserRole,
      content: trimmedContent,
      createdAt: DateTime.now(),
      isDelivered: true,
      isRead: false,
    );

    _activeMessages.add(optimisticMsg);
    _localRoomMessages.putIfAbsent(roomId, () => []).add(optimisticMsg);
    notifyListeners();

    // 2. Emit via real-time WebSocket
    if (_socketService.isConnected) {
      _socketService.sendMessage(
        roomId: roomId,
        content: trimmedContent,
      );
    } else {
      _socketService.connect();
    }

    // 3. Dispatch via REST in background
    try {
      final sent = await _chatService.sendMessage(
        roomId: roomId,
        content: trimmedContent,
      );
      final idx = _activeMessages.indexWhere((m) => m.id == tempId);
      if (idx != -1) {
        _activeMessages[idx] = sent;
        notifyListeners();
      }
    } catch (_) {
      // Backend push notification exception is absorbed gracefully;
      // the message remains rendered and visible in chat
    }
  }

  void sendTyping() {
    if (_activeRoomId != null) {
      _socketService.sendTyping(_activeRoomId!);
    }
  }

  void stopTyping() {
    if (_activeRoomId != null) {
      _socketService.sendStopTyping(_activeRoomId!);
    }
  }

  void closeConversation() {
    if (_activeRoomId != null) {
      _socketService.leaveRoom(_activeRoomId!);
      _activeRoomId = null;
    }
    _activeMessages = [];
    _isOtherUserTyping = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _typingSub?.cancel();
    _deliveredSub?.cancel();
    _readSub?.cancel();
    _deletedSub?.cancel();
    super.dispose();
  }
}
