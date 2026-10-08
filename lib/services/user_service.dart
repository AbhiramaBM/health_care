import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/storage/token_storage.dart';
import '../models/user_model.dart';

class UserService {
  final ApiClient _client = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage();

  /// Get current user / staff details: GET /auth/me
  Future<UserModel> getMe() async {
    final response = await _client.get(ApiEndpoints.authMe);
    final data = response.data['user'] ?? response.data;
    return UserModel.fromJson(Map<String, dynamic>.from(data));
  }

  /// Get list of staff / users: GET /admin/staff
  Future<List<UserModel>> getUsers({
    String? role,
    int? page,
    int? limit,
  }) async {
    final query = <String, dynamic>{};
    if (role != null) query['role'] = role;
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;

    final response = await _client.get(
      ApiEndpoints.adminStaff,
      queryParameters: query,
    );

    final dynamic data = response.data;
    List list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['staff'] is List) {
      list = data['staff'];
    } else if (data is Map && data['users'] is List) {
      list = data['users'];
    } else if (data is Map && data['data'] is List) {
      list = data['data'];
    } else {
      list = [];
    }

    return list
        .map((item) => UserModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// Get specific staff member by ID: GET /admin/staff/:userId
  Future<UserModel> getUserById(String userId) async {
    final response = await _client.get(ApiEndpoints.adminStaffById(userId));
    final data = response.data['user'] ?? response.data['staff'] ?? response.data;
    return UserModel.fromJson(Map<String, dynamic>.from(data));
  }

  /// Register FCM Device Token: PATCH /auth/fcm-token
  Future<void> registerDeviceToken({
    required String deviceToken,
    String? deviceId,
    String platform = 'android',
  }) async {
    final actualDeviceId = deviceId ?? await _tokenStorage.getDeviceId();
    await _tokenStorage.saveFcmToken(deviceToken);

    await _client.patch(
      ApiEndpoints.authFcmToken,
      data: {
        'fcmToken': deviceToken,
        'deviceId': actualDeviceId,
        'platform': platform,
      },
    );
  }

  /// Remove FCM Device Token on logout: POST /auth/logout
  Future<void> deleteDeviceToken(String deviceToken) async {
    final refreshToken = _tokenStorage.refreshToken;
    try {
      await _client.post(
        ApiEndpoints.authLogout,
        data: {
          if (refreshToken != null) 'refreshToken': refreshToken,
          'fcmToken': deviceToken,
        },
      );
    } catch (_) {}
  }
}
