import '../api/api_client.dart';

/// Utility class to sanitize, translate, and format system/API errors
/// into user-friendly, professional, human-understandable clinical terms.
class ErrorUtils {
  ErrorUtils._();

  /// Convert any error/exception into a human-friendly sentence.
  /// Removes HTTP status codes, stack traces, and technical jargon.
  static String toUserFriendlyMessage(dynamic error, {int? statusCode}) {
    if (error == null) {
      return 'An unexpected error occurred. Please try again.';
    }

    int? code = statusCode;
    String raw = '';

    if (error is ApiException) {
      code ??= error.statusCode;
      raw = error.message;
    } else {
      raw = error.toString();
    }

    // Strip common technical class name prefixes
    raw = raw.replaceAll(RegExp(r'^(ApiException|DioException|Exception|ClientException|SocketException|FormatException|TypeError):\s*', caseSensitive: false), '');
    // Strip status suffixes like "(status: 409)" or "[status: 409]"
    raw = raw.replaceAll(RegExp(r'\(status:\s*\d+\)', caseSensitive: false), '');
    raw = raw.replaceAll(RegExp(r'\[status:\s*\d+\]', caseSensitive: false), '');
    raw = raw.replaceAll(RegExp(r'status:\s*\d+', caseSensitive: false), '');
    raw = raw.trim();

    final lower = raw.toLowerCase();

    // 1. Specific Clinical & Application Domain Errors
    if (lower.contains('cannot modify a sent prescription') ||
        lower.contains('create a new draft prescription') ||
        (lower.contains('sent prescription') && lower.contains('draft'))) {
      return 'The patient\'s previous prescription is already finalized. A new prescription draft has been created for these medication changes.';
    }

    if (lower.contains('alert already acknowledged') || lower.contains('already acknowledged')) {
      return 'This alert has already been reviewed and acknowledged.';
    }

    if (lower.contains('alert not found')) {
      return 'The requested alert could not be found or has been removed.';
    }

    if (lower.contains('patient not found')) {
      return 'Patient profile could not be found.';
    }

    if (lower.contains('room not found') || lower.contains('you are not a member of this room')) {
      return 'You are not assigned to this patient discussion room.';
    }

    if (lower.contains('invalid or expired refresh token') ||
        lower.contains('invalid or expired token') ||
        lower.contains('jwt expired') ||
        lower.contains('no token provided') ||
        lower.contains('unauthorized: no token')) {
      return 'Your session has expired. Please sign in again.';
    }

    if (lower.contains('invalid email or password')) {
      return 'Incorrect email or password. Please verify your details.';
    }

    if (lower.contains('account is deactivated') || lower.contains('account deactivated')) {
      return 'Your account is currently deactivated. Please contact your administrator.';
    }

    if (lower.contains('account locked')) {
      return 'Account temporarily locked due to repeated failed attempts. Please try again in 15 minutes.';
    }

    if (lower.contains('access denied') || lower.contains('unauthorized') || lower.contains('forbidden')) {
      return 'You do not have permission to perform this clinical action.';
    }

    if (lower.contains('invalid otp') || lower.contains('otp has expired')) {
      return 'The verification code is invalid or has expired. Please request a new one.';
    }

    if (lower.contains('refreshtoken is required')) {
      return 'Session authentication error. Please log in again.';
    }

    if (lower.contains('message content cannot be empty') || lower.contains('content is required')) {
      return 'Message cannot be empty.';
    }

    // 2. Network & Connectivity Errors
    if (lower.contains('connection refused') ||
        lower.contains('failed host lookup') ||
        lower.contains('network error') ||
        lower.contains('connection closed') ||
        lower.contains('connection timed out') ||
        lower.contains('connecttimeout') ||
        lower.contains('receivetimeout') ||
        lower.contains('sendtimeout') ||
        lower.contains('socketexception') ||
        lower.contains('proxy gateway error') ||
        lower.contains('bad gateway')) {
      return 'Unable to connect to the server. Please check your internet connection.';
    }

    // 3. HTTP Status Codes fallback
    if (code != null) {
      switch (code) {
        case 400:
          if (raw.isNotEmpty && !_isTechnicalGarbage(raw)) {
            return _cleanSentence(raw);
          }
          return 'Invalid request details provided. Please check your input.';
        case 401:
          return 'Your session has expired. Please sign in again.';
        case 403:
          return 'You do not have permission to perform this action.';
        case 404:
          return 'The requested record was not found.';
        case 409:
          return 'This record conflicts with existing data or has already been updated.';
        case 423:
          return 'Account temporarily locked. Please try again shortly.';
        case 429:
          return 'Too many requests. Please wait a few moments and try again.';
        case 500:
        case 502:
        case 503:
        case 504:
          return 'The server encountered an issue. Please try again shortly.';
      }
    }

    // 4. Clean Raw String if it's already an understandable English sentence
    if (raw.isNotEmpty && !_isTechnicalGarbage(raw)) {
      return _cleanSentence(raw);
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Detects if the string looks like developer stack traces, code snippets, or json
  static bool _isTechnicalGarbage(String s) {
    if (s.contains('{') ||
        s.contains('}') ||
        s.contains('null check operator') ||
        s.contains('nosuchmethod') ||
        s.contains('typeerror') ||
        s.contains('syntaxerror') ||
        s.contains('call stack') ||
        s.contains('at ') && s.contains('.dart') ||
        s.contains('dioexception') ||
        s.startsWith('http://') ||
        s.startsWith('https://')) {
      return true;
    }
    return false;
  }

  /// Ensures proper capitalization and period punctuation
  static String _cleanSentence(String s) {
    var trimmed = s.trim();
    // Strip trailing status artifact if still present
    trimmed = trimmed.replaceAll(RegExp(r'\s*\(status:\s*\d+\)$', caseSensitive: false), '');
    if (trimmed.isEmpty) return 'An unexpected error occurred. Please try again.';

    // Capitalize first letter
    final firstChar = trimmed[0].toUpperCase();
    final rest = trimmed.length > 1 ? trimmed.substring(1) : '';
    var result = '$firstChar$rest';

    if (!result.endsWith('.') && !result.endsWith('!') && !result.endsWith('?')) {
      result = '$result.';
    }
    return result;
  }
}
