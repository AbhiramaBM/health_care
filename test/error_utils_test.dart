import 'package:flutter_test/flutter_test.dart';
import 'package:health_care/core/api/api_client.dart';
import 'package:health_care/core/utils/error_utils.dart';

void main() {
  group('ErrorUtils Human-Friendly Translation Tests', () {
    test('Translates SENT prescription 409 conflict to clear clinical terms', () {
      final apiEx = ApiException(
        'Cannot modify a SENT prescription. Create a new DRAFT prescription first.',
        statusCode: 409,
      );

      final message = ErrorUtils.toUserFriendlyMessage(apiEx);
      expect(message, isNot(contains('(status: 409)')));
      expect(message, isNot(contains('status:')));
      expect(message, contains('finalized'));
      expect(message, contains('prescription'));
    });

    test('Strips status codes from toString of ApiException', () {
      final apiEx = ApiException(
        'Alert already acknowledged',
        statusCode: 409,
      );

      expect(apiEx.toString(), isNot(contains('(status: 409)')));
      expect(apiEx.toString(), 'This alert has already been reviewed and acknowledged.');
    });

    test('Translates session expiry and auth errors', () {
      final apiEx = ApiException('Invalid or expired token', statusCode: 401);
      expect(ErrorUtils.toUserFriendlyMessage(apiEx), 'Your session has expired. Please sign in again.');

      final apiEx2 = ApiException('Invalid email or password', statusCode: 401);
      expect(ErrorUtils.toUserFriendlyMessage(apiEx2), 'Incorrect email or password. Please verify your details.');
    });

    test('Translates permission and access errors', () {
      final apiEx = ApiException('Access denied', statusCode: 403);
      expect(ErrorUtils.toUserFriendlyMessage(apiEx), 'You do not have permission to perform this clinical action.');
    });

    test('Translates network and connection errors', () {
      const netError = 'SocketException: Connection refused (OS Error: Connection refused, errno = 111)';
      expect(ErrorUtils.toUserFriendlyMessage(netError), 'Unable to connect to the server. Please check your internet connection.');
    });

    test('Translates server 500 error gracefully without leaking stack', () {
      final apiEx = ApiException('Internal Server Error', statusCode: 500);
      expect(ErrorUtils.toUserFriendlyMessage(apiEx), 'The server encountered an issue. Please try again shortly.');
    });

    test('Translates not found errors', () {
      final apiEx = ApiException('Patient not found', statusCode: 404);
      expect(ErrorUtils.toUserFriendlyMessage(apiEx), 'Patient profile could not be found.');
    });

    test('Formats clean English message properly', () {
      expect(ErrorUtils.toUserFriendlyMessage('Dosage cannot be zero (status: 400)'), 'Dosage cannot be zero.');
    });
  });
}
