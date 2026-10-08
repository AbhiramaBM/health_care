/// API Endpoints constants matching the AHC backend specification exactly
class ApiEndpoints {
  ApiEndpoints._();

  // AUTH
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';
  static const String authFcmToken = '/auth/fcm-token';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authResetPassword = '/auth/reset-password';
  static const String authSendOtp = '/auth/send-otp';
  static const String authVerifyOtp = '/auth/verify-otp';
  static const String authLoginPin = '/auth/login-pin';

  // STAFF / USERS (DOCTOR, STAFF, ADMIN)
  static const String adminStaff = '/admin/staff';
  static String adminStaffById(String userId) => '/admin/staff/$userId';

  // PATIENTS
  static const String patients = '/patients';
  static String patientProfile(String patientId) => '/patients/$patientId/profile';
  static const String batches = '/batches';
  static String batchById(String batchId) => '/batches/$batchId';

  // DAILY & WEEKLY LOGS
  static String logsDaily(String patientId) => '/logs/daily/$patientId';
  static String logDailyById(String logId) => '/logs/daily/id/$logId';
  static String logsDailyByDate(String patientId, String date) => '/logs/daily/$patientId/$date';
  static String logsWeekly(String patientId) => '/logs/weekly/$patientId';
  static String logsMissed(String patientId) => '/logs/missed/$patientId';

  // CLINICAL NOTES
  static const String notes = '/notes';
  static String notesByPatient(String patientId) => '/notes/patient/$patientId';
  static String notesByDailyLog(String logId) => '/notes/DAILY_LOG/$logId';
  static String notesByAlert(String alertId) => '/notes/ALERT/$alertId';

  // ALERTS
  static const String alerts = '/alerts';
  static String alertById(String alertId) => '/alerts/$alertId';
  static String alertAcknowledge(String alertId) => '/alerts/$alertId/acknowledge';

  // PRESCRIPTIONS
  static const String prescriptions = '/prescriptions';
  static String prescriptionsByPatient(String patientId) => '/prescriptions/patient/$patientId';
  static String prescriptionById(String prescriptionId) => '/prescriptions/$prescriptionId';
  static String prescriptionSend(String prescriptionId) => '/prescriptions/$prescriptionId/send';

  // CHAT (ROOMS & MESSAGES)
  static const String chatRooms = '/chat/rooms';
  static const String chatRoomsDirect = '/chat/rooms/direct';
  static String chatRoomById(String roomId) => '/chat/rooms/$roomId';
  static String chatRoomMessages(String roomId) => '/chat/rooms/$roomId/messages';
}

/// Socket.IO Event names matching SOCKET_GUIDE.md exactly
class SocketEvents {
  SocketEvents._();

  // Client -> Server
  static const String joinRoom = 'join_room';
  static const String leaveRoom = 'leave_room';
  static const String sendMessage = 'send_message';
  static const String deleteMessage = 'delete_message';
  static const String typing = 'typing';
  static const String stopTyping = 'stop_typing';
  static const String messageDelivered = 'message_delivered';
  static const String readMessage = 'read_message';
  static const String reactMessage = 'react_message';

  // Server -> Client
  static const String newMessage = 'new_message';
  static const String messageDeleted = 'message_deleted';
  static const String messagesRead = 'messages_read';
  static const String userTyping = 'user_typing';
  static const String userStopTyping = 'user_stop_typing';
  static const String reactionUpdated = 'reaction_updated';
  static const String error = 'error';
}
