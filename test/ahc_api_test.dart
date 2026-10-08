import 'package:flutter_test/flutter_test.dart';
import 'package:health_care/core/api/api_endpoints.dart';
import 'package:health_care/core/config/app_config.dart';
import 'package:health_care/models/user_model.dart';
import 'package:health_care/models/patient_model.dart';
import 'package:health_care/models/alert_model.dart';
import 'package:health_care/models/daily_log_model.dart';
import 'package:health_care/models/clinical_note_model.dart';
import 'package:health_care/models/prescription_model.dart';
import 'package:health_care/models/chat_model.dart';

void main() {
  group('AHC Server Configuration & Endpoints', () {
    test('Config points to live AHC production server', () {
      expect(AppConfig.apiBaseUrl, 'https://api.activehealthcentre.in/api/v1');
      expect(AppConfig.socketServerUrl, 'https://api.activehealthcentre.in');
      expect(AppConfig.socketNamespace, '/');
    });

    test('ApiEndpoints match Postman collection paths', () {
      expect(ApiEndpoints.authLogin, '/auth/login');
      expect(ApiEndpoints.authRefresh, '/auth/refresh');
      expect(ApiEndpoints.authLogout, '/auth/logout');
      expect(ApiEndpoints.authMe, '/auth/me');
      expect(ApiEndpoints.authFcmToken, '/auth/fcm-token');
      expect(ApiEndpoints.authForgotPassword, '/auth/forgot-password');
      expect(ApiEndpoints.authResetPassword, '/auth/reset-password');

      expect(ApiEndpoints.adminStaff, '/admin/staff');
      expect(ApiEndpoints.adminStaffById('u-1'), '/admin/staff/u-1');

      expect(ApiEndpoints.patients, '/patients');
      expect(ApiEndpoints.patientProfile('p-1'), '/patients/p-1/profile');
      expect(ApiEndpoints.batches, '/batches');

      expect(ApiEndpoints.logsDaily('p-1'), '/logs/daily/p-1');
      expect(ApiEndpoints.logDailyById('log-1'), '/logs/daily/id/log-1');
      expect(ApiEndpoints.logsWeekly('p-1'), '/logs/weekly/p-1');
      expect(ApiEndpoints.logsMissed('p-1'), '/logs/missed/p-1');

      expect(ApiEndpoints.notes, '/notes');
      expect(ApiEndpoints.notesByPatient('p-1'), '/notes/patient/p-1');
      expect(ApiEndpoints.notesByDailyLog('l-1'), '/notes/DAILY_LOG/l-1');
      expect(ApiEndpoints.notesByAlert('a-1'), '/notes/ALERT/a-1');

      expect(ApiEndpoints.alerts, '/alerts');
      expect(ApiEndpoints.alertById('a-1'), '/alerts/a-1');
      expect(ApiEndpoints.alertAcknowledge('a-1'), '/alerts/a-1/acknowledge');

      expect(ApiEndpoints.prescriptions, '/prescriptions');
      expect(ApiEndpoints.prescriptionsByPatient('p-1'), '/prescriptions/patient/p-1');
      expect(ApiEndpoints.prescriptionById('rx-1'), '/prescriptions/rx-1');
      expect(ApiEndpoints.prescriptionSend('rx-1'), '/prescriptions/rx-1/send');

      expect(ApiEndpoints.chatRooms, '/chat/rooms');
      expect(ApiEndpoints.chatRoomsDirect, '/chat/rooms/direct');
      expect(ApiEndpoints.chatRoomById('r-1'), '/chat/rooms/r-1');
      expect(ApiEndpoints.chatRoomMessages('r-1'), '/chat/rooms/r-1/messages');
    });

    test('SocketEvents match SOCKET_GUIDE.md', () {
      expect(SocketEvents.joinRoom, 'join_room');
      expect(SocketEvents.leaveRoom, 'leave_room');
      expect(SocketEvents.sendMessage, 'send_message');
      expect(SocketEvents.deleteMessage, 'delete_message');
      expect(SocketEvents.typing, 'typing');
      expect(SocketEvents.stopTyping, 'stop_typing');
      expect(SocketEvents.messageDelivered, 'message_delivered');
      expect(SocketEvents.readMessage, 'read_message');
      expect(SocketEvents.reactMessage, 'react_message');

      expect(SocketEvents.newMessage, 'new_message');
      expect(SocketEvents.messageDeleted, 'message_deleted');
      expect(SocketEvents.messagesRead, 'messages_read');
      expect(SocketEvents.userTyping, 'user_typing');
      expect(SocketEvents.userStopTyping, 'user_stop_typing');
      expect(SocketEvents.reactionUpdated, 'reaction_updated');
    });
  });

  group('AHC Models Serialization & Deserialization', () {
    test('UserModel parses doctor profile correctly', () {
      final json = {
        'id': 'doc-123',
        'name': 'Dr. Priya Sharma',
        'role': 'DOCTOR',
        'email': 'doctor@activehealth.com',
      };
      final user = UserModel.fromJson(json);
      expect(user.id, 'doc-123');
      expect(user.name, 'Dr. Priya Sharma');
      expect(user.role, 'DOCTOR');
      expect(user.email, 'doctor@activehealth.com');
    });

    test('PatientModel parses demographics and clinical profile', () {
      final json = {
        'id': 'pat-42',
        'name': 'Ravi Kumar',
        'phone': '9876543210',
        'patientDisplayId': 'AHC-0042',
        'profile': {
          'age': 54,
          'gender': 'MALE',
          'hba1c': 7.2,
          'bmi': 24.5,
          'condition': 'Type 2 Diabetes',
        },
      };
      final patient = PatientModel.fromJson(json);
      expect(patient.id, 'pat-42');
      expect(patient.name, 'Ravi Kumar');
      expect(patient.patientDisplayId, 'AHC-0042');
      expect(patient.age, 54);
      expect(patient.gender, 'MALE');
      expect(patient.hba1c, 7.2);
      expect(patient.bmi, 24.5);
      expect(patient.condition, 'Type 2 Diabetes');
    });

    test('AlertModel parses AHC alert format and status', () {
      final json = {
        'id': 'alert-99',
        'type': 'HIGH_FBS',
        'priority': 'URGENT',
        'message': 'FBS 210 mg/dL — above threshold (180)',
        'acknowledged': false,
        'createdAt': '2026-10-07T06:00:00.000Z',
        'patient': {
          'id': 'pat-42',
          'name': 'Ravi Kumar',
          'phone': '9876543210',
        },
      };
      final alert = AlertModel.fromJson(json);
      expect(alert.id, 'alert-99');
      expect(alert.title, 'HIGH_FBS');
      expect(alert.severity, 'URGENT');
      expect(alert.description, 'FBS 210 mg/dL — above threshold (180)');
      expect(alert.isAcknowledged, false);
      expect(alert.patientName, 'Ravi Kumar');
      expect(alert.patientPhone, '9876543210');
    });

    test('AlertModel parses acknowledged alert with note', () {
      final json = {
        'id': 'alert-100',
        'type': 'LOW_SUGAR',
        'priority': 'URGENT',
        'acknowledged': true,
        'acknowledgementNote': 'Reviewed and confirmed.',
        'createdAt': '2026-10-07T06:00:00.000Z',
      };
      final alert = AlertModel.fromJson(json);
      expect(alert.isAcknowledged, true);
      expect(alert.status, 'acknowledged');
    });

    test('DailyLogModel parses vitals, FBS, PPBS and meal photos', () {
      final json = {
        'id': 'log-55',
        'patientId': 'pat-42',
        'date': '2026-10-07T08:00:00.000Z',
        'bloodPressureSystolic': 130,
        'bloodPressureDiastolic': 85,
        'heartRate': 72,
        'fbs': 115.5,
        'ppbs': 142.0,
        'breakfastPhoto': 'https://s3.aws.com/meal1.jpg',
        'lunchPhoto': 'https://s3.aws.com/meal2.jpg',
      };
      final log = DailyLogModel.fromJson(json);
      expect(log.id, 'log-55');
      expect(log.bloodPressureSystolic, 130.0);
      expect(log.bloodPressureDiastolic, 85.0);
      expect(log.fbs, 115.5);
      expect(log.ppbs, 142.0);
      expect(log.breakfastPhoto, 'https://s3.aws.com/meal1.jpg');
      expect(log.lunchPhoto, 'https://s3.aws.com/meal2.jpg');
      expect(log.dinnerPhoto, isNull);
    });

    test('ClinicalNoteModel parses target type and content', () {
      final json = {
        'id': 'note-1',
        'patientId': 'pat-42',
        'content': 'HbA1c trending down — continue current plan.',
        'targetType': 'PATIENT_PROFILE',
        'category': 'CLINICAL',
      };
      final note = ClinicalNoteModel.fromJson(json);
      expect(note.id, 'note-1');
      expect(note.content, 'HbA1c trending down — continue current plan.');
    });

    test('PrescriptionModel parses medications list', () {
      final json = {
        'id': 'rx-1',
        'patientId': 'pat-42',
        'status': 'DRAFT',
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
      final rx = PrescriptionModel.fromJson(json);
      expect(rx.id, 'rx-1');
      expect(rx.medications.length, 1);
      expect(rx.medications[0].name, 'Metformin');
      expect(rx.medications[0].dosage, '1000mg');
      expect(rx.medications[0].frequency, 'twice daily');
    });

    test('ChatMessageModel and ConversationModel parse socket formats', () {
      final roomJson = {
        'id': 'room-01',
        'name': 'Internal Medicine Team',
        'type': 'GROUP',
        'unreadCount': 2,
        'lastMessage': {'content': 'Review completed.'},
      };
      final room = ConversationModel.fromJson(roomJson);
      expect(room.id, 'room-01');
      expect(room.title, 'Internal Medicine Team');
      expect(room.lastMessage, 'Review completed.');
      expect(room.unreadCount, 2);

      final msgJson = {
        'id': 'msg-100',
        'roomId': 'room-01',
        'senderId': 'doc-123',
        'content': 'All clear on Ravi Kumar labs.',
        'deliveredAt': '2026-10-07T10:00:00.000Z',
        'sender': {'name': 'Dr. Priya Sharma', 'role': 'DOCTOR'},
      };
      final msg = ChatMessageModel.fromJson(msgJson);
      expect(msg.id, 'msg-100');
      expect(msg.roomId, 'room-01');
      expect(msg.content, 'All clear on Ravi Kumar labs.');
      expect(msg.senderName, 'Dr. Priya Sharma');
      expect(msg.senderRole, 'DOCTOR');
      expect(msg.isDelivered, true);
      expect(msg.isRead, false);
    });
  });
}
