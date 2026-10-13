import 'package:flutter_test/flutter_test.dart';
import 'package:health_care/core/utils/message_formatter.dart';
import 'package:health_care/core/utils/error_utils.dart';
import 'package:health_care/models/alert_model.dart';
import 'package:health_care/models/patient_model.dart';
import 'package:health_care/models/user_model.dart';
import 'package:health_care/models/prescription_model.dart';
import 'package:health_care/models/clinical_note_model.dart';

void main() {
  group('MessageFormatter Tests', () {
    test('Maps internal alert codes to human-readable titles', () {
      expect(MessageFormatter.formatAlertTitle('NO_LOG_3_DAYS'), 'Patient has not logged in');
      expect(MessageFormatter.formatAlertTitle('NO_LOG_7_DAYS'), 'Patient has not logged in');
      expect(MessageFormatter.formatAlertTitle('PATIENT_INACTIVE'), 'Patient is inactive');
      expect(MessageFormatter.formatAlertTitle('LOW_ACTIVITY'), 'Patient activity is low');
      expect(MessageFormatter.formatAlertTitle('MISSED_CHECKIN'), 'Patient missed a check-in');
      expect(MessageFormatter.formatAlertTitle('HIGH_RISK'), 'High-risk patient');
      expect(MessageFormatter.formatAlertTitle('HIGH_FBS'), 'High fasting blood sugar');
      expect(MessageFormatter.formatAlertTitle('HIGH_PPBS'), 'High PPBS');
      expect(MessageFormatter.formatAlertTitle('CRITICAL_GLUCOSE'), 'Elevated glucose level');
    });

    test('Generates natural sentence descriptions for dynamic day alerts', () {
      expect(
        MessageFormatter.formatAlertDescription('NO_LOG_3_DAYS'),
        'The patient has not logged in for the past 3 days.',
      );
      expect(
        MessageFormatter.formatAlertDescription('NO_LOG_7_DAYS'),
        'The patient has not logged in for the past 7 days.',
      );
      expect(
        MessageFormatter.formatAlertDescription('PATIENT_INACTIVE'),
        'The patient has been inactive and may need clinical follow-up.',
      );
      expect(
        MessageFormatter.formatAlertDescription('LOW_ACTIVITY'),
        "The patient's activity has been lower than expected.",
      );
      expect(
        MessageFormatter.formatAlertDescription('MISSED_CHECKIN'),
        'The patient has missed their scheduled check-in.',
      );
      expect(
        MessageFormatter.formatAlertDescription('HIGH_RISK'),
        'This patient requires additional clinical attention.',
      );
    });

    test('Preserves universal acronyms while applying sentence case', () {
      expect(MessageFormatter.toSentenceCase('HBA1C LEVEL ELEVATED'), 'HbA1c level elevated');
      expect(MessageFormatter.toSentenceCase('CHECK BP AND BMI REGULARLY'), 'Check BP and BMI regularly');
      expect(MessageFormatter.toSentenceCase('ENTER OTP OR PIN TO LOGIN'), 'Enter OTP or PIN to login');
      expect(MessageFormatter.toSentenceCase('HIGH FBS AND PPBS DETECTED'), 'High FBS and PPBS detected');
      expect(MessageFormatter.toSentenceCase('SEND WHATSAPP REMINDER'), 'Send WhatsApp reminder');
    });

    test('Formats severities and statuses into sentence case', () {
      expect(MessageFormatter.formatSeverity('CRITICAL'), 'Critical');
      expect(MessageFormatter.formatSeverity('URGENT'), 'Urgent');
      expect(MessageFormatter.formatSeverity('HIGH'), 'High');
      expect(MessageFormatter.formatSeverity('WATCH'), 'Watch');
      expect(MessageFormatter.formatSeverity('MEDIUM'), 'Medium');
      expect(MessageFormatter.formatSeverity('LOW'), 'Low');
      expect(MessageFormatter.formatSeverity('INFO'), 'Info');

      expect(MessageFormatter.formatAlertStatus('PENDING'), 'Pending');
      expect(MessageFormatter.formatAlertStatus('ACKNOWLEDGED'), 'Acknowledged');
      expect(MessageFormatter.formatAlertStatus('IGNORED'), 'Dismissed');
    });

    test('Formats roles into sentence case', () {
      expect(MessageFormatter.formatRole('DOCTOR'), 'Doctor');
      expect(MessageFormatter.formatRole('NURSE'), 'Nurse');
      expect(MessageFormatter.formatRole('CARE_COORDINATOR'), 'Care coordinator');
      expect(MessageFormatter.formatRole('ADMIN'), 'Administrator');
    });
  });

  group('Model Display Getters Integration', () {
    test('AlertModel returns formatted display getters without breaking raw fields', () {
      final alert = AlertModel(
        id: 'alt-1',
        title: 'NO_LOG_3_DAYS',
        severity: 'URGENT',
        status: 'PENDING',
        createdAt: DateTime.now(),
      );

      // Raw fields preserved for backend serialization & test assertions
      expect(alert.title, 'NO_LOG_3_DAYS');
      expect(alert.severity, 'URGENT');
      expect(alert.status, 'PENDING');

      // UI display getters provide natural English
      expect(alert.displayTitle, 'Patient has not logged in');
      expect(alert.displayDescription, 'The patient has not logged in for the past 3 days.');
      expect(alert.displaySeverity, 'Urgent');
      expect(alert.displayStatus, 'Pending');
    });

    test('PatientModel returns formatted glucose status, condition, and gender', () {
      final patient = PatientModel(
        id: 'p-1',
        name: 'John Doe',
        gender: 'MALE',
        glucoseStatus: 'CRITICAL',
        condition: 'TYPE_2_DIABETES',
      );

      expect(patient.displayGender, 'Male');
      expect(patient.displayGlucoseStatus, 'Critical');
      expect(patient.displayCondition, 'Type 2 diabetes');
    });

    test('UserModel returns formatted role', () {
      final user = UserModel(
        id: 'u-1',
        email: 'doc@activehealthcentre.in',
        role: 'DOCTOR',
      );

      expect(user.displayRole, 'Doctor');
    });

    test('PrescriptionModel and ClinicalNoteModel format status and category', () {
      final rx = PrescriptionModel(
        id: 'rx-1',
        patientId: 'p-1',
        status: 'SENT',
        medications: [],
        createdAt: DateTime.now(),
      );
      expect(rx.displayStatus, 'Sent');

      final note = ClinicalNoteModel(
        id: 'n-1',
        patientId: 'p-1',
        category: 'DIETARY',
        content: 'Patient advised to reduce carbs.',
        createdAt: DateTime.now(),
      );
      expect(note.displayCategory, 'Dietary guidance');
    });
  });

  group('ErrorUtils Sign-in and Server Error Handling', () {
    test('Formats invalid credentials to natural English', () {
      expect(ErrorUtils.toUserFriendlyMessage('INVALID_CREDENTIALS'), 'Invalid email or password.');
      expect(ErrorUtils.toUserFriendlyMessage('invalid credentials'), 'Invalid email or password.');
      expect(ErrorUtils.toUserFriendlyMessage('USER_NOT_FOUND'), 'User not found.');
      expect(ErrorUtils.toUserFriendlyMessage('SERVER_ERROR'), 'Something went wrong. Please try again.');
    });

    test('Login context translates HTTP 500 bad password response into Invalid email or password.', () {
      expect(
        ErrorUtils.toUserFriendlyMessage('Internal server error', statusCode: 500, isLoginContext: true),
        'Invalid email or password.',
      );
    });
  });
}
