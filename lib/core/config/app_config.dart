import 'package:flutter/foundation.dart';

/// Configuration class for Healthcare API & Socket connections
class AppConfig {
  AppConfig._();

  // Active Health Centre Endpoints
  static const String prodApiBaseUrl = 'https://api.activehealthcentre.in/api/v1';
  static const String devProxyApiBaseUrl = 'http://localhost:5050/api/v1';

  // Automatically use CORS Proxy for Web development or prod URL on Mobile
  static String apiBaseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kIsWeb ? devProxyApiBaseUrl : prodApiBaseUrl,
  );

  static String socketServerUrl = const String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: kIsWeb ? 'http://localhost:5050' : 'https://api.activehealthcentre.in',
  );

  static String socketNamespace = '/';

  // API Timeout settings
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// Allows updating runtime configuration (e.g. from developer settings or env)
  static void updateConfig({
    String? baseUrl,
    String? socketUrl,
    String? socketNs,
  }) {
    if (baseUrl != null && baseUrl.isNotEmpty) apiBaseUrl = baseUrl;
    if (socketUrl != null && socketUrl.isNotEmpty) socketServerUrl = socketUrl;
    if (socketNs != null) socketNamespace = socketNs;
  }
}
