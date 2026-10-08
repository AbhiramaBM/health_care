import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/storage/token_storage.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _client = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage();

  /// Process auth response: extract tokens, user data, save to secure storage, register FCM
  Future<UserModel> _processAuthResponse(Map<String, dynamic> data, String? deviceId) async {
    final accessToken = data['token'] ?? data['accessToken'];
    final refreshToken = data['refreshToken'];

    if (accessToken != null) {
      await _tokenStorage.saveTokens(
        accessToken: accessToken.toString(),
        refreshToken: refreshToken?.toString(),
      );
    }

    final userJson = data['user'] ?? data;
    final user = UserModel.fromJson(Map<String, dynamic>.from(userJson));
    await _tokenStorage.saveUserData(userId: user.id, role: user.role);

    // If an FCM token was previously saved, register it with the backend
    final savedFcmToken = await _tokenStorage.getFcmToken();
    if (savedFcmToken != null && savedFcmToken.isNotEmpty) {
      try {
        await updateFcmToken(
          fcmToken: savedFcmToken,
          deviceId: deviceId,
          platform: 'android',
        );
      } catch (_) {}
    }

    return user;
  }

  /// Doctors log in with email and password: POST /auth/login
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final deviceId = await _tokenStorage.getDeviceId();

    final response = await _client.post(
      ApiEndpoints.authLogin,
      data: {
        'email': email.trim(),
        'password': password,
      },
    );

    return _processAuthResponse(response.data, deviceId);
  }

  /// Request OTP for phone: POST /auth/send-otp
  Future<void> sendOtp(String phone) async {
    await _client.post(
      ApiEndpoints.authSendOtp,
      data: {'phone': phone.trim()},
    );
  }

  /// Verify OTP and log in: POST /auth/verify-otp
  Future<UserModel> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final deviceId = await _tokenStorage.getDeviceId();
    final response = await _client.post(
      ApiEndpoints.authVerifyOtp,
      data: {
        'phone': phone.trim(),
        'otp': otp.trim(),
      },
    );
    return _processAuthResponse(response.data, deviceId);
  }

  /// Login with Phone + PIN: POST /auth/login-pin
  Future<UserModel> loginWithPin({
    required String phone,
    required String pin,
  }) async {
    final deviceId = await _tokenStorage.getDeviceId();
    final response = await _client.post(
      ApiEndpoints.authLoginPin,
      data: {
        'phone': phone.trim(),
        'pin': pin.trim(),
      },
    );
    return _processAuthResponse(response.data, deviceId);
  }

  /// Single-use refresh token rotation: POST /auth/refresh
  Future<String?> refreshToken() async {
    final refreshToken = _tokenStorage.refreshToken;
    if (refreshToken == null) return null;

    final response = await _client.post(
      ApiEndpoints.authRefresh,
      data: {'refreshToken': refreshToken},
    );

    final data = response.data;
    final newAccessToken = data['token'] ?? data['accessToken'];
    final newRefreshToken = data['refreshToken'] ?? refreshToken;

    if (newAccessToken != null) {
      await _tokenStorage.saveTokens(
        accessToken: newAccessToken.toString(),
        refreshToken: newRefreshToken.toString(),
      );
      return newAccessToken.toString();
    }
    return null;
  }

  /// Request 6-digit password reset OTP: POST /auth/forgot-password
  Future<void> forgotPassword(String email) async {
    await _client.post(
      ApiEndpoints.authForgotPassword,
      data: {'email': email.trim()},
    );
  }

  /// Reset password using 6-digit code: POST /auth/reset-password
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _client.post(
      ApiEndpoints.authResetPassword,
      data: {
        'email': email.trim(),
        'otp': otp.trim(),
        'newPassword': newPassword,
      },
    );
  }

  /// Register / update FCM push notification token: PATCH /auth/fcm-token
  Future<void> updateFcmToken({
    required String fcmToken,
    String? deviceId,
    String platform = 'android',
  }) async {
    final actualDeviceId = deviceId ?? await _tokenStorage.getDeviceId();
    await _tokenStorage.saveFcmToken(fcmToken);

    await _client.patch(
      ApiEndpoints.authFcmToken,
      data: {
        'fcmToken': fcmToken,
        'deviceId': actualDeviceId,
        'platform': platform,
      },
    );
  }

  /// Logout and revoke tokens/devices: POST /auth/logout
  Future<void> logout() async {
    final refreshToken = _tokenStorage.refreshToken;
    final fcmToken = await _tokenStorage.getFcmToken();

    try {
      await _client.post(
        ApiEndpoints.authLogout,
        data: {
          if (refreshToken != null) 'refreshToken': refreshToken,
          if (fcmToken != null) 'fcmToken': fcmToken,
        },
      );
    } catch (_) {
      // Proceed with local logout regardless of network error
    } finally {
      await _tokenStorage.clear();
    }
  }

  /// Get current authenticated doctor profile: GET /auth/me
  Future<UserModel> getMe() async {
    final response = await _client.get(ApiEndpoints.authMe);
    final userJson = response.data['user'] ?? response.data;
    return UserModel.fromJson(Map<String, dynamic>.from(userJson));
  }
}
