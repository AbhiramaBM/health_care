import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../config/app_config.dart';
import '../storage/token_storage.dart';
import '../api/api_endpoints.dart';
import '../utils/error_utils.dart';

class SocketService {
  socket_io.Socket? _socket;
  final TokenStorage _tokenStorage = TokenStorage();

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Track joined rooms for automatic re-joining upon reconnect
  final Set<String> _joinedRooms = <String>{};

  // Stream controllers for real-time events
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageDeletedController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageDeliveredController = StreamController<Map<String, dynamic>>.broadcast();
  final _messagesReadController = StreamController<Map<String, dynamic>>.broadcast();
  final _reactionUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  final _alertController = StreamController<Map<String, dynamic>>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<Map<String, dynamic>> get onMessageReceived => _messageController.stream;
  Stream<Map<String, dynamic>> get onMessageDeleted => _messageDeletedController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingController.stream;
  Stream<Map<String, dynamic>> get onMessageDelivered => _messageDeliveredController.stream;
  Stream<Map<String, dynamic>> get onMessagesRead => _messagesReadController.stream;
  Stream<Map<String, dynamic>> get onReactionUpdated => _reactionUpdatedController.stream;
  Stream<bool> get onConnectionChanged => _connectionStateController.stream;
  Stream<Map<String, dynamic>> get onAlertReceived => _alertController.stream;
  Stream<String> get onError => _errorController.stream;

  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  Map<String, dynamic>? _parseMapData(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  /// Initialize and connect to the Socket.IO server
  void connect({bool force = false}) {
    if (!force && _socket != null && _isConnected) return;
    if (force && _socket != null) {
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
      _isConnected = false;
    }

    final token = _tokenStorage.accessToken;
    final url = AppConfig.socketServerUrl;
    final namespace = AppConfig.socketNamespace;
    final fullUrl = (namespace.isNotEmpty && namespace != '/') ? '$url$namespace' : url;

    final options = socket_io.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .enableAutoConnect()
        .enableReconnection()
        .setReconnectionDelay(2000)
        .setReconnectionAttempts(10);

    if (token != null && token.isNotEmpty) {
      options.setAuth({'token': token});
      options.setExtraHeaders({'Authorization': 'Bearer $token'});
      options.setQuery({'token': token});
    }

    _socket = socket_io.io(fullUrl, options.build());

    _socket?.onConnect((_) {
      _isConnected = true;
      _connectionStateController.add(true);

      // Re-join active rooms on reconnect (rooms are in-memory on server)
      for (final roomId in _joinedRooms) {
        _socket?.emit(SocketEvents.joinRoom, roomId);
      }
    });

    _socket?.onDisconnect((_) {
      _isConnected = false;
      _connectionStateController.add(false);
    });

    _socket?.onConnectError((err) {
      _isConnected = false;
      _connectionStateController.add(false);
    });

    // Listen for new_message and message
    void handleNewMessage(dynamic data) {
      final parsed = _parseMapData(data);
      if (parsed != null) {
        _messageController.add(parsed);
      }
    }

    _socket?.on(SocketEvents.newMessage, handleNewMessage);
    _socket?.on('message', handleNewMessage);

    // Listen for real-time alerts
    void handleNewAlert(dynamic data) {
      final parsed = _parseMapData(data);
      if (parsed != null) {
        _alertController.add(parsed);
      }
    }

    _socket?.on('new_alert', handleNewAlert);
    _socket?.on('alert', handleNewAlert);

    // Listen for message_deleted
    _socket?.on(SocketEvents.messageDeleted, (data) {
      final parsed = _parseMapData(data);
      if (parsed != null) {
        _messageDeletedController.add(parsed);
      }
    });

    // Listen for user_typing
    _socket?.on(SocketEvents.userTyping, (data) {
      final parsed = _parseMapData(data);
      if (parsed != null) {
        parsed['isTyping'] = true;
        _typingController.add(parsed);
      }
    });

    // Listen for user_stop_typing
    _socket?.on(SocketEvents.userStopTyping, (data) {
      final parsed = _parseMapData(data);
      if (parsed != null) {
        parsed['isTyping'] = false;
        _typingController.add(parsed);
      }
    });

    // Listen for message_delivered
    _socket?.on(SocketEvents.messageDelivered, (data) {
      final parsed = _parseMapData(data);
      if (parsed != null) {
        _messageDeliveredController.add(parsed);
      }
    });

    // Listen for messages_read
    _socket?.on(SocketEvents.messagesRead, (data) {
      final parsed = _parseMapData(data);
      if (parsed != null) {
        _messagesReadController.add(parsed);
      }
    });

    // Listen for reaction_updated
    _socket?.on(SocketEvents.reactionUpdated, (data) {
      final parsed = _parseMapData(data);
      if (parsed != null) {
        _reactionUpdatedController.add(parsed);
      }
    });

    // Listen for error event
    _socket?.on(SocketEvents.error, (data) {
      final parsed = _parseMapData(data);
      if (parsed != null && parsed['message'] != null) {
        _errorController.add(ErrorUtils.toUserFriendlyMessage(parsed['message']));
      } else if (data != null) {
        _errorController.add(ErrorUtils.toUserFriendlyMessage(data));
      }
    });

    _socket?.connect();
  }

  /// Join a room (payload: string roomId)
  void joinRoom(String roomId) {
    _joinedRooms.add(roomId);
    if (_socket == null) connect();
    _socket?.emit(SocketEvents.joinRoom, roomId);
  }

  /// Leave a room (payload: string roomId)
  void leaveRoom(String roomId) {
    _joinedRooms.remove(roomId);
    _socket?.emit(SocketEvents.leaveRoom, roomId);
  }

  /// Send message via Socket (payload: { roomId, content, mentions, references })
  void sendMessage({
    required String roomId,
    required String content,
    List<Map<String, dynamic>> mentions = const [],
    List<Map<String, dynamic>> references = const [],
  }) {
    if (_socket == null) connect();
    _socket?.emit(SocketEvents.sendMessage, {
      'roomId': roomId,
      'content': content,
      'mentions': mentions,
      'references': references,
    });
  }

  /// Delete message (payload: string messageId)
  void deleteMessage(String messageId) {
    _socket?.emit(SocketEvents.deleteMessage, messageId);
  }

  /// Notify typing (payload: string roomId)
  void sendTyping(String roomId) {
    _socket?.emit(SocketEvents.typing, roomId);
  }

  /// Notify stop typing (payload: string roomId)
  void sendStopTyping(String roomId) {
    _socket?.emit(SocketEvents.stopTyping, roomId);
  }

  /// Report message delivered (payload: string messageId)
  void markDelivered(String messageId) {
    _socket?.emit(SocketEvents.messageDelivered, messageId);
  }

  /// Tell the server the user has read all messages in a room (payload: { roomId: roomId })
  void markRead(String roomId) {
    _socket?.emit(SocketEvents.readMessage, {'roomId': roomId});
  }

  /// Toggle emoji reaction (payload: { messageId, emoji })
  void reactMessage(String messageId, String emoji) {
    _socket?.emit(SocketEvents.reactMessage, {
      'messageId': messageId,
      'emoji': emoji,
    });
  }

  /// Disconnect socket
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _joinedRooms.clear();
    _connectionStateController.add(false);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _messageDeletedController.close();
    _typingController.close();
    _messageDeliveredController.close();
    _messagesReadController.close();
    _reactionUpdatedController.close();
    _connectionStateController.close();
    _alertController.close();
    _errorController.close();
  }
}
