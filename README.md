# HealthCare Clinical Flutter App

A Flutter application for Healthcare Staff, Doctors, and Clinical Practitioners, integrating with your external REST API and real-time Socket.IO server with zero fake data.

## Architecture

```
lib/
├── core/
│   ├── api/
│   │   ├── api_client.dart          # Dio client with JWT Bearer injection & 401 token refresh
│   │   └── api_endpoints.dart       # Complete endpoint map matching the backend
│   ├── config/
│   │   └── app_config.dart          # Dynamic Base URL & Socket configurations
│   ├── socket/
│   │   └── socket_service.dart      # Real-time Socket.IO client (chat, typing, read receipts)
│   ├── storage/
│   │   └── token_storage.dart       # Secure token & session persistence
│   └── theme/
│       └── app_theme.dart           # Clinical UI Design System
├── models/
│   ├── user_model.dart              # Staff & User profiles
│   ├── patient_model.dart           # Patient demographics & batch cohorts
│   ├── daily_log_model.dart         # Vitals (BP, HR, Glucose, Temp) & daily logs
│   ├── clinical_note_model.dart     # Patient, Log, and Alert notes
│   ├── alert_model.dart             # Clinical alerts (severity & status)
│   ├── prescription_model.dart      # Prescriptions & active medications
│   ├── chat_model.dart              # Conversations & chat messages
│   └── meal_photo_model.dart        # Dietary & meal photo logs
├── services/                        # 100% Real API integration (No fake/mock data)
│   ├── auth_service.dart            # /auth/* (OTP request/verify, login, refresh, logout, me)
│   ├── user_service.dart            # /users/* and /users/device-token
│   ├── patient_service.dart         # /patients/* (search, batches, details)
│   ├── daily_log_service.dart       # /patients/{id}/daily-logs
│   ├── clinical_note_service.dart   # /patients/{id}/notes, /logs/{id}/notes, /alerts/{id}/notes
│   ├── alert_service.dart           # /alerts/* (acknowledge, ignore, change-medication, message)
│   ├── prescription_service.dart    # /patients/{id}/prescriptions & medications
│   ├── chat_service.dart            # /chat/* (conversations, messages, users, batches)
│   └── media_service.dart           # /patients/{id}/meal-photos
├── providers/                       # State management (ChangeNotifier)
│   ├── auth_provider.dart
│   ├── patient_provider.dart
│   ├── alert_provider.dart
│   ├── chat_provider.dart
│   └── log_provider.dart
├── screens/
│   ├── auth/login_screen.dart       # Dual OTP & Password staff authentication
│   ├── dashboard/dashboard_screen.dart # Overview metrics & navigation
│   ├── patients/                    # Patient directory & detailed tabs
│   ├── alerts/alerts_screen.dart    # Live clinical alerts & multi-action sheet
│   ├── chat/                        # Real-time Socket.IO chat & active conversations
│   └── settings/                    # Profile & Server endpoint configuration dialog
└── main.dart
```

---

## Implemented API Endpoints

| Category | Method | Endpoint | Implementation |
|---|---|---|---|
| **AUTH** | `POST` | `/auth/otp/request` | `AuthService.requestOtp` |
| | `POST` | `/auth/otp/verify` | `AuthService.verifyOtp` |
| | `POST` | `/auth/login` | `AuthService.login` |
| | `POST` | `/auth/refresh` | `AuthService.refreshToken` & `ApiClient` interceptor |
| | `POST` | `/auth/logout` | `AuthService.logout` |
| | `GET` | `/auth/me` | `AuthService.getMe` |
| **USERS / STAFF** | `GET` | `/users/me` | `UserService.getMe` |
| | `GET` | `/users` | `UserService.getUsers` |
| | `GET` | `/users/{userId}` | `UserService.getUserById` |
| **PATIENTS** | `GET` | `/patients` | `PatientService.getPatients` |
| | `GET` | `/patients/{patientId}` | `PatientService.getPatientById` |
| | `GET` | `/patients/search` | `PatientService.searchPatients` |
| | `GET` | `/patients/batches` | `PatientService.getPatientBatches` |
| **DAILY LOGS** | `GET` | `/patients/{patientId}/daily-logs` | `DailyLogService.getDailyLogs` |
| | `GET` | `/patients/{patientId}/daily-logs/{logId}` | `DailyLogService.getDailyLogById` |
| **CLINICAL NOTES** | `GET` | `/patients/{patientId}/notes` | `ClinicalNoteService.getPatientNotes` |
| | `POST` | `/patients/{patientId}/notes` | `ClinicalNoteService.addPatientNote` |
| | `GET` | `/logs/{logId}/notes` | `ClinicalNoteService.getLogNotes` |
| | `POST` | `/logs/{logId}/notes` | `ClinicalNoteService.addLogNote` |
| | `GET` | `/alerts/{alertId}/notes` | `ClinicalNoteService.getAlertNotes` |
| | `POST` | `/alerts/{alertId}/notes` | `ClinicalNoteService.addAlertNote` |
| **ALERTS** | `GET` | `/alerts` | `AlertService.getAlerts` |
| | `GET` | `/alerts/{alertId}` | `AlertService.getAlertById` |
| | `POST` | `/alerts/{alertId}/acknowledge` | `AlertService.acknowledgeAlert` |
| | `POST` | `/alerts/{alertId}/ignore` | `AlertService.ignoreAlert` |
| | `POST` | `/alerts/{alertId}/change-medication` | `AlertService.changeMedication` |
| | `POST` | `/alerts/{alertId}/message` | `AlertService.sendAlertMessage` |
| **PRESCRIPTIONS** | `GET` | `/patients/{patientId}/prescriptions` | `PrescriptionService.getPrescriptions` |
| | `GET` | `/patients/{patientId}/prescriptions/{id}` | `PrescriptionService.getPrescriptionById` |
| | `GET` | `/patients/{patientId}/medications` | `PrescriptionService.getMedications` |
| **CHAT** | `GET` | `/chat/conversations` | `ChatService.getConversations` |
| | `GET` | `/chat/conversations/{id}` | `ChatService.getConversationById` |
| | `GET` | `/chat/conversations/{id}/messages` | `ChatService.getMessages` |
| | `POST` | `/chat/conversations/{id}/messages` | `ChatService.sendMessage` |
| | `GET` | `/chat/users` | `ChatService.getChatUsers` |
| | `GET` | `/chat/batches` | `ChatService.getChatBatches` |
| **NOTIFICATIONS** | `POST` | `/users/device-token` | `UserService.registerDeviceToken` |
| | `DELETE` | `/users/device-token` | `UserService.deleteDeviceToken` |
| **MEAL PHOTOS** | `GET` | `/patients/{patientId}/meal-photos` | `MediaService.getPatientMealPhotos` |

---

## Real-Time Socket.IO Integration

The `SocketService` (`lib/core/socket/socket_service.dart`) implements full bidirectional event handling:
- **`connect` / `disconnect`**: Auto-reconnection with Bearer authentication
- **`join_conversation` / `leave_conversation`**: Room-based presence
- **`send_message` / `receive_message`**: Real-time message streaming
- **`typing` / `stop_typing`**: Live typing indication with debounce
- **`message_delivered` / `message_read`**: Live delivery status indicators

---

## Configuring Backend Endpoints

You can configure endpoints either:
1. In code: `lib/core/config/app_config.dart` (`apiBaseUrl`, `socketServerUrl`, `socketNamespace`).
2. Inside the app: Tap the **Settings icon** on the Login screen or **API & Socket Server Endpoints** on the Profile tab to change URLs dynamically.
