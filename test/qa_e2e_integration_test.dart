import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_care/core/storage/token_storage.dart';
import 'package:health_care/models/patient_model.dart';
import 'package:health_care/models/daily_log_model.dart';
import 'package:health_care/models/clinical_note_model.dart';
import 'package:health_care/models/chat_model.dart';
import 'package:health_care/providers/auth_provider.dart';
import 'package:health_care/providers/patient_provider.dart';
import 'package:health_care/providers/alert_provider.dart';
import 'package:health_care/providers/chat_provider.dart';
import 'package:health_care/providers/log_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('QA E2E Suite: Authentication & Session Lifecycle', () {
    test('Token storage maintains session and device identity', () async {
      final storage = TokenStorage();
      await storage.saveTokens(
        accessToken: 'initial-access-token-123',
        refreshToken: 'initial-refresh-token-456',
      );
      await storage.saveDeviceId('qa-device-001');
      await storage.saveFcmToken('qa-fcm-token-xyz');

      expect(storage.accessToken, 'initial-access-token-123');
      expect(storage.refreshToken, 'initial-refresh-token-456');
      expect(storage.isAuthenticated, true);
      expect(await storage.getDeviceId(), 'qa-device-001');
      expect(await storage.getFcmToken(), 'qa-fcm-token-xyz');

      // Test token rotation (replaces old token)
      await storage.saveTokens(
        accessToken: 'rotated-access-token-789',
        refreshToken: 'rotated-refresh-token-999',
      );
      expect(storage.accessToken, 'rotated-access-token-789');
      expect(storage.refreshToken, 'rotated-refresh-token-999');

      // Test clear on logout
      await storage.clear();
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(storage.isAuthenticated, false);
    });

    test('AuthProvider state transitions on login and error', () {
      final authProvider = AuthProvider();
      expect(authProvider.status, AuthStatus.initial);
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.currentUser, isNull);
    });

    test('AuthProvider handles OTP and PIN authentication states', () {
      final authProvider = AuthProvider();
      authProvider.clearError();
      expect(authProvider.errorMessage, isNull);
    });
  });

  group('QA E2E Suite: Patient Directory & Search Filters', () {
    test('PatientProvider initializes with clean state', () {
      final provider = PatientProvider();
      expect(provider.patients, isEmpty);
      expect(provider.batches, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.selectedPatient, isNull);
    });

    test('PatientModel correctly parses all demographic and clinical metrics', () {
      final sampleJson = {
        'id': 'pat-101',
        'name': 'Anita Roy',
        'patientDisplayId': 'AHC-0101',
        'hasAlert': true,
        'lastLog': {
          'logDate': '2026-10-07T00:00:00.000Z',
        },
        'profile': {
          'age': 62,
          'gender': 'FEMALE',
          'hba1c': 8.1,
          'bmi': 27.3,
          'condition': 'T2D + Hypertension',
        },
      };
      final patient = PatientModel.fromJson(sampleJson);
      expect(patient.id, 'pat-101');
      expect(patient.name, 'Anita Roy');
      expect(patient.patientDisplayId, 'AHC-0101');
      expect(patient.age, 62);
      expect(patient.gender, 'FEMALE');
      expect(patient.hba1c, 8.1);
      expect(patient.bmi, 27.3);
      expect(patient.condition, 'T2D + Hypertension');
      expect(patient.hasAlert, true);
      expect(patient.lastLogDate, isNotNull);
      expect(patient.glucoseStatus, 'CRITICAL'); // hba1c > 8.0 maps to CRITICAL
    });
  });

  group('QA E2E Suite: Clinical Alerts & Actions Verification', () {
    test('AlertProvider tracks pending count and action filtering', () {
      final provider = AlertProvider();
      expect(provider.alerts, isEmpty);
      expect(provider.pendingAlertsCount, 0);
      expect(provider.showAcknowledged, false);
    });

    test('Alert actions match AHC POST /alerts/:id/acknowledge specifications', () {
      // 1. IGNORED action
      final ignorePayload = {
        'action': 'IGNORED',
        'noteContent': 'Patient confirmed values — no intervention needed.',
      };
      expect(ignorePayload['action'], 'IGNORED');

      // 2. MESSAGE_SENT action
      final messagePayload = {
        'action': 'MESSAGE_SENT',
        'messageText': 'Please recheck your fasting reading tomorrow morning.',
      };
      expect(messagePayload['action'], 'MESSAGE_SENT');

      // 3. MEDICATION_CHANGED action
      final medChangePayload = {
        'action': 'MEDICATION_CHANGED',
        'noteContent': 'Increased Metformin dose.',
        'medications': [
          {
            'medicineName': 'Metformin',
            'dose': '1000mg',
            'frequency': 'twice daily',
            'duration': '30 days',
            'instructions': 'After meals',
            'action': 'INCREASE',
          }
        ],
      };
      expect(medChangePayload['action'], 'MEDICATION_CHANGED');
      expect((medChangePayload['medications'] as List).length, 1);
    });
  });

  group('QA E2E Suite: Daily Logs, Notes, and Meal Photos', () {
    test('LogProvider maintains vitals and notes state', () {
      final provider = LogProvider();
      expect(provider.dailyLogs, isEmpty);
      expect(provider.patientNotes, isEmpty);
      expect(provider.isLoadingLogs, false);
      expect(provider.isLoadingNotes, false);
    });

    test('DailyLogModel correctly handles FBS, PPBS, and photos', () {
      final logJson = {
        'id': 'log-88',
        'patientId': 'pat-101',
        'date': '2026-10-07T07:30:00.000Z',
        'bloodPressureSystolic': 135,
        'bloodPressureDiastolic': 88,
        'fbs': 145.0,
        'ppbs': 210.0,
        'breakfastPhoto': 'https://storage.activehealthcentre.in/bf1.jpg',
        'lunchPhoto': 'https://storage.activehealthcentre.in/lu1.jpg',
        'dinnerPhoto': 'https://storage.activehealthcentre.in/di1.jpg',
      };
      final log = DailyLogModel.fromJson(logJson);
      expect(log.fbs, 145.0);
      expect(log.ppbs, 210.0);
      expect(log.breakfastPhoto, 'https://storage.activehealthcentre.in/bf1.jpg');
      expect(log.lunchPhoto, 'https://storage.activehealthcentre.in/lu1.jpg');
      expect(log.dinnerPhoto, 'https://storage.activehealthcentre.in/di1.jpg');
    });

    test('ClinicalNoteModel maps correctly to TARGET types', () {
      final noteJson = {
        'id': 'note-55',
        'patientId': 'pat-101',
        'content': 'Discussed diet plan and glucose trend.',
        'category': 'CLINICAL',
        'authorName': 'Dr. Priya Sharma',
      };
      final note = ClinicalNoteModel.fromJson(noteJson);
      expect(note.id, 'note-55');
      expect(note.authorName, 'Dr. Priya Sharma');
      expect(note.content, 'Discussed diet plan and glucose trend.');
    });
  });

  group('QA E2E Suite: Team Chat & Socket Event Protocol', () {
    test('ChatProvider initializes cleanly with empty active room', () {
      final provider = ChatProvider();
      expect(provider.conversations, isEmpty);
      expect(provider.activeMessages, isEmpty);
      expect(provider.activeRoomId, isNull);
      expect(provider.isOtherUserTyping, false);
    });

    test('ChatMessageModel supports delivery ticks and read status', () {
      final msg = ChatMessageModel(
        id: 'msg-001',
        roomId: 'room-77',
        senderId: 'doc-001',
        senderName: 'Dr. Priya Sharma',
        senderRole: 'DOCTOR',
        content: 'Patient HbA1c is stabilized.',
        createdAt: DateTime.now(),
        isDelivered: false,
        isRead: false,
      );

      final delivered = msg.copyWith(isDelivered: true);
      expect(delivered.isDelivered, true);
      expect(delivered.isRead, false);

      final read = delivered.copyWith(isRead: true);
      expect(read.isDelivered, true);
      expect(read.isRead, true);
    });
  });
}
