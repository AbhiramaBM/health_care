import 'dart:async';
import 'package:flutter/material.dart';
import '../core/utils/error_utils.dart';
import '../models/chat_model.dart';
import '../models/patient_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/clinical_note_service.dart';
import '../services/patient_service.dart';
import '../core/socket/socket_service.dart';
import '../core/storage/token_storage.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/top_notification_banner.dart';
import '../screens/chat/conversation_screen.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final ClinicalNoteService _clinicalNoteService = ClinicalNoteService();
  final PatientService _patientService = PatientService();
  final SocketService _socketService = SocketService();
  final TokenStorage _tokenStorage = TokenStorage();

  List<ConversationModel> _conversations = [];
  List<PatientModel> _assignedPatients = [];
  List<ChatMessageModel> _activeMessages = [];
  List<UserModel> _chatUsers = [];
  List<dynamic> _chatBatches = [];

  String? _activeRoomId;
  bool _isPatientChat = false;
  String? _activePatientName;
  bool _isLoading = false;
  bool _isPatientsLoading = false;
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
  List<PatientModel> get assignedPatients => _assignedPatients;
  List<ChatMessageModel> get activeMessages => _activeMessages;
  List<UserModel> get chatUsers => _chatUsers;
  List<dynamic> get chatBatches => _chatBatches;
  String? get activeRoomId => _activeRoomId;
  String? get activeConversationId => _activeRoomId;
  bool get isPatientChat => _isPatientChat;
  String? get activePatientName => _activePatientName;
  bool get isLoading => _isLoading;
  bool get isPatientsLoading => _isPatientsLoading;
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
        final optIdx = _activeMessages.indexWhere((m) =>
            m.id == msg.id ||
            (m.id.startsWith('temp_') && m.content == msg.content));
        if (optIdx != -1) {
          _activeMessages[optIdx] = msg;
        } else if (!_activeMessages.any((m) => m.id == msg.id)) {
          _activeMessages.add(msg);
        }
        _socketService.markDelivered(msg.id);
        _socketService.markRead(_activeRoomId!);
        notifyListeners();
      } else {
        // Show WhatsApp-style top notification banner if not currently in this room
        final currentUserId = _tokenStorage.userId;
        if (currentUserId == null || msg.senderId != currentUserId) {
          TopNotificationBanner.show(
            title: msg.senderName != null && msg.senderName!.isNotEmpty
                ? msg.senderName!
                : 'New message',
            message: msg.content.isNotEmpty
                ? msg.content
                : 'You have received a new message.',
            timestamp: 'Just now',
            accentColor: AppTheme.primaryColor,
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppTheme.primaryColor,
                size: 18,
              ),
            ),
            onTap: () {
              final nav = rootNavigatorKey.currentState;
              nav?.push(
                MaterialPageRoute(
                  builder: (_) => ConversationScreen(
                    conversationId: msg.roomId,
                    title: msg.senderName ?? 'Chat',
                    isPatient: false,
                  ),
                ),
              );
            },
          );
        }
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

  /// Fetch assigned patients for the doctor from the real API
  Future<void> fetchAssignedPatients({bool refresh = false, String? search}) async {
    if (_assignedPatients.isNotEmpty && !refresh && (search == null || search.isEmpty)) return;

    _isPatientsLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _assignedPatients = await _patientService.getPatients(
        search: search,
        limit: 100,
      );
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
    } finally {
      _isPatientsLoading = false;
      notifyListeners();
    }
  }

  /// List team rooms: GET /chat/rooms
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

  /// Open a conversation with either an assigned patient or a team room
  Future<void> openConversation(
    String id, {
    bool isPatient = false,
    String? title,
  }) async {
    if (_activeRoomId != null && _activeRoomId != id && !_isPatientChat) {
      _socketService.leaveRoom(_activeRoomId!);
    }

    _activeRoomId = id;
    _isPatientChat = isPatient;
    _activePatientName = title;
    _isMessagesLoading = true;
    _errorMessage = null;
    _isOtherUserTyping = false;
    _activeMessages = [];
    notifyListeners();

    if (isPatient) {
      // Load real messages/clinical notes from backend database: GET /notes/patient/:patientId
      try {
        final notes = await _clinicalNoteService.getPatientNotes(id);
        final currentUserId = _tokenStorage.userId ?? '';

        final loadedMessages = notes.map((note) {
          final isAuthorMe = (note.authorId != null && note.authorId == currentUserId) ||
              (note.authorName != null && note.authorName!.toLowerCase().contains('doctor')) ||
              (note.authorName != null && note.authorName == _tokenStorage.userName);

          return ChatMessageModel(
            id: note.id,
            roomId: id,
            senderId: note.authorId ?? (isAuthorMe ? currentUserId : 'patient_$id'),
            senderName: note.authorName ?? (isAuthorMe ? (_tokenStorage.userName ?? 'Doctor') : (title ?? 'Patient')),
            senderRole: isAuthorMe ? 'DOCTOR' : 'PATIENT',
            content: note.content,
            createdAt: note.createdAt,
            isDelivered: true,
            isRead: true,
          );
        }).toList();

        // Sort chronologically (oldest to newest)
        loadedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        _activeMessages = loadedMessages;
      } catch (e) {
        _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
      } finally {
        _isMessagesLoading = false;
        notifyListeners();
      }
    } else {
      // Team room: connect socket & fetch history from GET /chat/rooms/:id/messages
      if (!_socketService.isConnected) {
        _socketService.connect();
      }
      _socketService.joinRoom(id);
      _socketService.markRead(id);

      try {
        final remoteMessages = await _chatService.getMessages(id);
        remoteMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        _activeMessages = remoteMessages;

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
  }

  /// Send message in active conversation (Patient or Team Room)
  Future<void> sendMessage(String content) async {
    if (_activeRoomId == null || content.trim().isEmpty) return;
    final id = _activeRoomId!;
    final trimmedContent = content.trim();

    final currentUserId = _tokenStorage.userId ?? 'doctor';
    final currentUserName = _tokenStorage.userName ?? 'Doctor';

    if (_isPatientChat) {
      // 1. Send via real backend API: POST /notes with targetType: PATIENT_PROFILE
      _errorMessage = null;
      try {
        final savedNote = await _clinicalNoteService.addPatientNote(
          patientId: id,
          content: trimmedContent,
          category: 'GENERAL',
        );

        final savedMsg = ChatMessageModel(
          id: savedNote.id,
          roomId: id,
          senderId: savedNote.authorId ?? currentUserId,
          senderName: savedNote.authorName ?? currentUserName,
          senderRole: 'DOCTOR',
          content: savedNote.content,
          createdAt: savedNote.createdAt,
          isDelivered: true,
          isRead: true,
        );

        _activeMessages.add(savedMsg);
        notifyListeners();
      } catch (e) {
        _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
        notifyListeners();
      }
    } else {
      // Team room
      if (_socketService.isConnected) {
        _socketService.sendMessage(
          roomId: id,
          content: trimmedContent,
        );
      } else {
        _socketService.connect();
      }

      try {
        final sent = await _chatService.sendMessage(
          roomId: id,
          content: trimmedContent,
        );
        _activeMessages.add(sent);
        notifyListeners();
      } catch (e) {
        _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
        notifyListeners();
      }
    }
  }

  void sendTyping() {
    if (_activeRoomId != null && !_isPatientChat) {
      _socketService.sendTyping(_activeRoomId!);
    }
  }

  void stopTyping() {
    if (_activeRoomId != null && !_isPatientChat) {
      _socketService.sendStopTyping(_activeRoomId!);
    }
  }

  void closeConversation() {
    if (_activeRoomId != null && !_isPatientChat) {
      _socketService.leaveRoom(_activeRoomId!);
    }
    _activeRoomId = null;
    _isPatientChat = false;
    _activePatientName = null;
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
