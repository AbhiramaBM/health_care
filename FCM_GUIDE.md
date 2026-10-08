# FCM Push Notification Guide — AHC Doctor App

## Overview

The server uses **Firebase Cloud Messaging (FCM)** via the Firebase Admin SDK. Push notifications are non-blocking — they are sent fire-and-forget alongside the primary action. A push failure never prevents an API response from succeeding.

---

## Multi-device support

Multiple devices per user are supported. Each device registers its own FCM token via `PATCH /api/v1/auth/fcm-token`. When the server sends a push to a user it fans out to **all** registered devices in parallel.

| Table | Purpose |
|---|---|
| `user_devices` | Primary per-device token registry (`userId`, `fcmToken`, `deviceId`, `platform`) |
| `users.fcm_token` | Legacy single-token column — kept in sync for backward compatibility |

---

## Registering a device

Call once after login and whenever the FCM token rotates (FCM can issue a new token at any time).

```
PATCH /api/v1/auth/fcm-token
Authorization: Bearer <accessToken>
```

```json
{
  "fcmToken":  "<firebase-registration-token>",
  "deviceId":  "my-phone-001",
  "platform":  "android"
}
```

- `deviceId` and `platform` are optional but help with debugging.
- If the same `fcmToken` is already registered to a different user account it is automatically evicted from that account before being registered to the new one.

---

## Deregistering a device

Pass the token in the logout request body:

```
POST /api/v1/auth/logout
Authorization: Bearer <accessToken>
```

```json
{
  "refreshToken": "<refreshToken>",
  "fcmToken":     "<firebase-registration-token>"
}
```

The server deletes only the matching `user_devices` row. Other devices belonging to the same user continue to receive notifications.

If `fcmToken` is omitted, only the legacy `users.fcm_token` column is cleared.

---

## When pushes are sent

| Trigger | Recipient | Priority |
|---|---|---|
| `@mention` in a team chat message | Mentioned user | `normal` |
| `@mention` in a community room message | Mentioned user | `normal` |
| New message in a community room (batch or global) | All room members | Based on notification preference |
| Alerts crossing threshold (server-side cron) | Doctor / Dietician / Staff | `high` for URGENT |

Quiet hours are respected for non-urgent pushes. URGENT alerts bypass quiet hours. Each user can override their notification timing via the notification preference settings.

---

## Payload structure

The server sends an FCM **notification + data** message:

```json
{
  "notification": {
    "title": "Dr. Priya Sharma mentioned you",
    "body":  "Lab results look good — keeping current plan."
  },
  "data": {
    "type":    "chat_mention",
    "roomId":  "<roomId>",
    "priority": "normal"
  }
}
```

The exact `data` fields vary by trigger:

| `type` value | Additional data fields |
|---|---|
| `chat_mention` | `roomId` |
| `COMMUNITY_MESSAGE` | `roomId`, `roomName`, `screen: "/community"` |
| Alert push (cron) | `alertId`, `alertType`, `patientId` |

---

## Stale token cleanup

FCM returns `messaging/registration-token-not-registered` when a token is no longer valid (e.g., the app was uninstalled). The server handles this automatically:

1. The stale token is deleted from `user_devices`.
2. If it matches `users.fcm_token`, that column is cleared to `null`.

No manual cleanup is needed.

---

## Dev / test behaviour

If `FIREBASE_PROJECT_ID`, `FIREBASE_PRIVATE_KEY`, or `FIREBASE_CLIENT_EMAIL` environment variables are missing or set to placeholder values, the Firebase SDK is not initialised and push calls are silently skipped (a console warning is logged). All other API behaviour is unaffected.

---

## Circuit breaker

Firebase calls are wrapped in an internal circuit breaker (`circuitBreaker.js`). If FCM becomes unavailable the circuit opens after repeated failures and requests are short-circuited without hanging. The circuit state is visible at `GET /api/v1/health`.
