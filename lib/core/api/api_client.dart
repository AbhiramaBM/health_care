import 'dart:async';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_endpoints.dart';

import '../utils/error_utils.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  /// Formatted message in human-friendly terms without technical codes or jargon
  String get userFriendlyMessage => ErrorUtils.toUserFriendlyMessage(this);

  /// Developer debug string including status code
  String get debugMessage => 'ApiException: $message (status: $statusCode)';

  @override
  String toString() => userFriendlyMessage;
}

class ApiClient {
  late final Dio dio;
  final TokenStorage _tokenStorage = TokenStorage();
  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Always ensure the base URL matches AppConfig
          options.baseUrl = AppConfig.apiBaseUrl;

          final deviceId = await _tokenStorage.getDeviceId();
          if (deviceId != null && deviceId.isNotEmpty) {
            options.headers['X-Device-Id'] = deviceId;
          }

          final token = _tokenStorage.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Check for 401 Unauthorized (expired access token)
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/login') &&
              !error.requestOptions.path.contains('/auth/refresh')) {
            try {
              final newToken = await _handleTokenRefresh();
              if (newToken != null) {
                // Retry the original request with new token
                final opts = Options(
                  method: error.requestOptions.method,
                  headers: Map<String, dynamic>.from(error.requestOptions.headers),
                );
                opts.headers?['Authorization'] = 'Bearer $newToken';
                final response = await dio.request(
                  error.requestOptions.path,
                  options: opts,
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                );
                return handler.resolve(response);
              }
            } catch (e) {
              await _tokenStorage.clear();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<String?> _handleTokenRefresh() async {
    if (_isRefreshing) {
      return _refreshCompleter?.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = _tokenStorage.refreshToken;
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(null);
        return null;
      }

      final refreshDio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: AppConfig.connectTimeout,
          receiveTimeout: AppConfig.receiveTimeout,
        ),
      );

      final response = await refreshDio.post(
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
        _refreshCompleter!.complete(newAccessToken.toString());
        return newAccessToken.toString();
      }
      _refreshCompleter!.complete(null);
      return null;
    } catch (e) {
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  // HTTP Helpers
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  ApiException _parseError(DioException error) {
    final res = error.response;
    String message = 'Network error occurred';
    if (res?.data != null) {
      if (res?.data is Map) {
        message = res?.data['error'] ??
            res?.data['message'] ??
            res?.data.toString() ??
            message;
      } else {
        message = res?.data.toString() ?? message;
      }
    } else if (error.message != null && error.message!.isNotEmpty) {
      message = error.message!;
    }
    return ApiException(
      message,
      statusCode: res?.statusCode,
      data: res?.data,
    );
  }
}
