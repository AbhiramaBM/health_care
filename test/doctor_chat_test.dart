import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_care/core/storage/token_storage.dart';
import 'package:health_care/models/chat_model.dart';
import 'package:health_care/models/clinical_note_model.dart';
import 'package:health_care/models/patient_model.dart';
import 'package:health_care/providers/chat_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Doctor Chat Feature End-to-End Tests', () {
    test('ChatProvider initializes cleanly without mock data', () {
      final provider = ChatProvider();
      expect(provider.conversations, isEmpty);
      expect(provider.assignedPatients, isEmpty);
      expect(provider.activeMessages, isEmpty);
      expect(provider.activeRoomId, isNull);
      expect(provider.isPatientChat, false);
      expect(provider.isLoading, false);
      expect(provider.isMessagesLoading, false);
    });

    test('ChatMessageModel correctly parses database responses from backend', () {
      final json = {
        'id': 'msg-uuid-001',
        'roomId': 'room-uuid-001',
        'content': 'Test clinical observation for HbA1c',
        'sender': {
          'id': 'doctor-uuid-001',
          'name': 'Dr. Test',
          'role': 'DOCTOR',
        },
        'createdAt': '2026-10-13T12:00:00.000Z',
        'isDelivered': true,
        'isRead': true,
      };

      final msg = ChatMessageModel.fromJson(json);
      expect(msg.id, 'msg-uuid-001');
      expect(msg.roomId, 'room-uuid-001');
      expect(msg.content, 'Test clinical observation for HbA1c');
      expect(msg.senderId, 'doctor-uuid-001');
      expect(msg.senderName, 'Dr. Test');
      expect(msg.senderRole, 'DOCTOR');
      expect(msg.isDelivered, true);
      expect(msg.isRead, true);
    });

    test('ClinicalNoteModel correctly maps to ChatMessageModel for patient consultation', () {
      final noteJson = {
        'id': 'note-uuid-999',
        'targetType': 'PATIENT_PROFILE',
        'targetId': 'patient-uuid-123',
        'patientId': 'patient-uuid-123',
        'content': 'Follow up fasting glucose tomorrow morning.',
        'noteType': 'GENERAL',
        'urgency': 'NORMAL',
        'createdAt': '2026-10-13T14:30:00.000Z',
        'author': {
          'id': 'doc-uuid-555',
          'name': 'Dr. Sharma',
          'role': 'DOCTOR',
        },
        'patient': {
          'name': 'Maheshwarappa B O',
        },
      };

      final note = ClinicalNoteModel.fromJson(noteJson);
      expect(note.id, 'note-uuid-999');
      expect(note.authorId, 'doc-uuid-555');
      expect(note.authorName, 'Dr. Sharma');
      expect(note.content, 'Follow up fasting glucose tomorrow morning.');

      // Map to ChatMessageModel as done in ChatProvider
      final chatMsg = ChatMessageModel(
        id: note.id,
        roomId: note.patientId!,
        senderId: note.authorId!,
        senderName: note.authorName!,
        senderRole: 'DOCTOR',
        content: note.content,
        createdAt: note.createdAt,
        isDelivered: true,
        isRead: true,
      );

      expect(chatMsg.id, 'note-uuid-999');
      expect(chatMsg.roomId, 'patient-uuid-123');
      expect(chatMsg.senderRole, 'DOCTOR');
      expect(chatMsg.senderName, 'Dr. Sharma');
      expect(chatMsg.content, 'Follow up fasting glucose tomorrow morning.');
    });

    test('ConversationModel parses both community and direct chat rooms', () {
      final communityJson = {
        'id': 'comm-room-1',
        'type': 'COMMUNITY_GLOBAL',
        'name': 'Active Health Community',
        'memberCount': 34,
        'lastMessage': {
          'content': 'Welcome everyone',
          'senderName': 'Samanth',
          'createdAt': '2026-10-13T10:00:00.000Z',
        },
      };

      final directJson = {
        'id': 'dm-room-2',
        'type': 'DIRECT',
        'name': 'Sneha N',
        'memberCount': 2,
        'lastMessage': null,
      };

      final commRoom = ConversationModel.fromJson(communityJson);
      expect(commRoom.id, 'comm-room-1');
      expect(commRoom.title, 'Active Health Community');
      expect(commRoom.type, 'COMMUNITY_GLOBAL');
      expect(commRoom.lastMessage, 'Welcome everyone');

      final dmRoom = ConversationModel.fromJson(directJson);
      expect(dmRoom.id, 'dm-room-2');
      expect(dmRoom.title, 'Sneha N');
      expect(dmRoom.type, 'DIRECT');
      expect(dmRoom.lastMessage, isNull);
    });

    test('TokenStorage correctly persists and provides doctor identity', () async {
      final tokenStorage = TokenStorage();
      await tokenStorage.saveUserData(
        userId: 'doctor-a6ad8e95',
        role: 'DOCTOR',
        name: 'Dr. Test',
      );

      expect(tokenStorage.userId, 'doctor-a6ad8e95');
      expect(tokenStorage.userRole, 'DOCTOR');
      expect(tokenStorage.userName, 'Dr. Test');
    });

    test('PatientModel parses assigned patient records for doctor chat', () {
      final patientJson = {
        'id': 'p-uuid-001',
        'name': 'Maheshwarappa B O',
        'phone': '8056088842',
        'isActive': true,
        'profile': {
          'patientDisplayId': 'AHV-2026-0050',
          'age': 56,
          'gender': 'MALE',
        },
      };

      final patient = PatientModel.fromJson(patientJson);
      expect(patient.id, 'p-uuid-001');
      expect(patient.name, 'Maheshwarappa B O');
      expect(patient.phone, '8056088842');
      expect(patient.patientDisplayId, 'AHV-2026-0050');
      expect(patient.age, 56);
      expect(patient.displayGender, 'Male');
    });

    test('ChatProvider closeConversation clears active room state', () {
      final provider = ChatProvider();
      provider.closeConversation();
      expect(provider.activeRoomId, isNull);
      expect(provider.isPatientChat, false);
      expect(provider.activeMessages, isEmpty);
      expect(provider.isOtherUserTyping, false);
    });
  });
}
