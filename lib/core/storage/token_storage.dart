import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userRoleKey = 'user_role';
  static const String _fcmTokenKey = 'fcm_token';
  static const String _deviceIdKey = 'device_id';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // In-memory cache for ultra-fast access in HTTP interceptors and chat
  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  String? _cachedDeviceId;
  String? _cachedUserId;
  String? _cachedUserRole;

  static final TokenStorage _instance = TokenStorage._internal();
  factory TokenStorage() => _instance;
  TokenStorage._internal();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedUserId = prefs.getString(_userIdKey);
    _cachedUserRole = prefs.getString(_userRoleKey);
    try {
      _cachedAccessToken = await _secureStorage.read(key: _accessTokenKey);
      _cachedRefreshToken = await _secureStorage.read(key: _refreshTokenKey);
    } catch (_) {
      _cachedAccessToken = prefs.getString(_accessTokenKey);
      _cachedRefreshToken = prefs.getString(_refreshTokenKey);
    }
  }

  String? get accessToken => _cachedAccessToken;
  String? get refreshToken => _cachedRefreshToken;
  String? get userId => _cachedUserId;
  String? get userRole => _cachedUserRole;
  bool get isAuthenticated => _cachedAccessToken != null && _cachedAccessToken!.isNotEmpty;

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _cachedAccessToken = accessToken;
    if (refreshToken != null) {
      _cachedRefreshToken = refreshToken;
    }

    try {
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      if (refreshToken != null) {
        await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      }
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      if (refreshToken != null) {
        await prefs.setString(_refreshTokenKey, refreshToken);
      }
    }
  }

  Future<void> saveUserData({required String userId, String? role}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    if (role != null) {
      await prefs.setString(_userRoleKey, role);
    }
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  Future<void> saveFcmToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token);
  }

  Future<String?> getFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fcmTokenKey);
  }

  Future<void> saveDeviceId(String deviceId) async {
    _cachedDeviceId = deviceId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceIdKey, deviceId);
  }

  Future<String?> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId;
    final prefs = await SharedPreferences.getInstance();
    _cachedDeviceId = prefs.getString(_deviceIdKey) ?? 'flutter-device-001';
    return _cachedDeviceId;
  }

  Future<void> clear() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    try {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userRoleKey);
  }
}
