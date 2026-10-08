# Quickstart — AHC Doctor App API

Eight calls that cover the core doctor-app flow: login → patients → logs → alerts → chat → push.

All examples use `curl`. Base URL is `http://localhost:3000` (dev). Replace with the production URL when deploying.

---

## Step 1 — Login

```bash
curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -H "X-Device-Id: my-phone-001" \
  -d '{
    "email":    "doctor@activehealth.com",
    "password": "Doctor@12345"
  }'
```

**Response:**
```json
{
  "token": "<accessToken>",
  "refreshToken": "<refreshToken>",
  "user": {
    "id":    "<userId>",
    "name":  "Dr. Priya Sharma",
    "role":  "DOCTOR",
    "email": "doctor@activehealth.com"
  }
}
```

Save both tokens. `token` (access token) expires in **8 hours**. `refreshToken` expires in **30 days**.

The `X-Device-Id` header ties this refresh token to your device so logout can revoke only this device.

---

## Step 2 — Use the access token

Every subsequent request requires:

```
Authorization: Bearer <accessToken>
```

If the server returns `401 Unauthorized`, your access token has expired — go to Step 3.

---

## Step 3 — Refresh the access token

Call this before the 8-hour window closes, or on any `401` response.

```bash
curl -s -X POST http://localhost:3000/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "<refreshToken>"
  }'
```

**Response:**
```json
{
  "token":        "<newAccessToken>",
  "refreshToken": "<newRefreshToken>"
}
```

**Important:** the old `refreshToken` is now invalid. Always replace both tokens in storage. Replaying an old refresh token returns `401`.

---

## Step 4 — List patients

```bash
curl -s http://localhost:3000/api/v1/patients?page=1&limit=20 \
  -H "Authorization: Bearer <accessToken>"
```

**Response shape:**
```json
{
  "patients": [
    {
      "id":               "<patientId>",
      "name":             "Ravi Kumar",
      "phone":            "98XXXXXXXX",
      "patientDisplayId": "AHC-0042",
      "profile": { "age": 54, "gender": "MALE", "hba1c": 7.2, ... }
    }
  ],
  "total": 84,
  "page":  1,
  "limit": 20,
  "pages": 5
}
```

Save a `patientId` from this response — you'll need it for steps 5–8.

To search: add `?search=ravi` (matches name, phone, or patientDisplayId).

---

## Step 5 — Fetch an alert

```bash
# List unacknowledged alerts for the patient
curl -s "http://localhost:3000/api/v1/alerts?acknowledged=false&patientId=<patientId>" \
  -H "Authorization: Bearer <accessToken>"
```

**Response shape:**
```json
{
  "alerts": [
    {
      "id":          "<alertId>",
      "type":        "HIGH_FBS",
      "priority":    "URGENT",
      "message":     "FBS 210 mg/dL — above threshold (180)",
      "acknowledged": false,
      "createdAt":   "2026-10-07T06:00:00.000Z",
      "patient":     { "name": "Ravi Kumar", "phone": "98XXXXXXXX" }
    }
  ],
  "pagination": { "page": 1, "limit": 50, "total": 3, "pages": 1 }
}
```

Save an `alertId`. To fetch a single alert by ID:

```bash
curl -s http://localhost:3000/api/v1/alerts/<alertId> \
  -H "Authorization: Bearer <accessToken>"
```

---

## Step 6 — Acknowledge the alert

Three actions are available. Pick the one that fits:

**Ignore (no action needed):**
```bash
curl -s -X POST http://localhost:3000/api/v1/alerts/<alertId>/acknowledge \
  -H "Authorization: Bearer <accessToken>" \
  -H "Content-Type: application/json" \
  -d '{
    "action":      "IGNORED",
    "noteContent": "Patient confirmed values — no intervention needed."
  }'
```

**Message the patient via WhatsApp:**
```bash
curl -s -X POST http://localhost:3000/api/v1/alerts/<alertId>/acknowledge \
  -H "Authorization: Bearer <accessToken>" \
  -H "Content-Type: application/json" \
  -d '{
    "action":      "MESSAGE_SENT",
    "messageText": "Please recheck your fasting reading tomorrow morning."
  }'
```

**Change medication (DOCTOR only):**
```bash
curl -s -X POST http://localhost:3000/api/v1/alerts/<alertId>/acknowledge \
  -H "Authorization: Bearer <accessToken>" \
  -H "Content-Type: application/json" \
  -d '{
    "action":      "MEDICATION_CHANGED",
    "noteContent": "Increased Metformin dose.",
    "medications": [
      {
        "medicineName": "Metformin",
        "dose":         "1000mg",
        "frequency":    "twice daily",
        "duration":     "30 days",
        "instructions": "After meals",
        "action":       "INCREASE"
      }
    ]
  }'
```

---

## Step 7 — Send a chat message

First, get or create a DM room with a colleague:

```bash
curl -s -X POST http://localhost:3000/api/v1/chat/rooms/direct \
  -H "Authorization: Bearer <accessToken>" \
  -H "Content-Type: application/json" \
  -d '{ "userId": "<colleagueUserId>" }'
```

**Response:** `{ "room": { "id": "<roomId>", ... } }`

Then send a message via REST:

```bash
curl -s -X POST http://localhost:3000/api/v1/chat/rooms/<roomId>/messages \
  -H "Authorization: Bearer <accessToken>" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Ravi Kumar HbA1c result in — down to 6.8. Can we review together?"
  }'
```

**Response:** `201 Created` with the full message object.

The message is also broadcast as a `new_message` socket event to all connected members of the room. See `SOCKET_GUIDE.md` for the real-time path.

---

## Step 8 — Register the device for push notifications

Call this once after login (and again if the FCM token rotates):

```bash
curl -s -X PATCH http://localhost:3000/api/v1/auth/fcm-token \
  -H "Authorization: Bearer <accessToken>" \
  -H "Content-Type: application/json" \
  -d '{
    "fcmToken":  "<firebase-registration-token>",
    "deviceId":  "my-phone-001",
    "platform":  "android"
  }'
```

Multiple devices are supported. The same FCM token is automatically removed from any other user account.

To deregister on logout, include `fcmToken` in the logout body:

```bash
curl -s -X POST http://localhost:3000/api/v1/auth/logout \
  -H "Authorization: Bearer <accessToken>" \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "<refreshToken>",
    "fcmToken":     "<firebase-registration-token>"
  }'
```

---

## Variable cheat sheet

| Variable | Where it comes from |
|---|---|
| `accessToken` | `POST /auth/login` → `token` |
| `refreshToken` | `POST /auth/login` → `refreshToken`; rotated by `POST /auth/refresh` |
| `patientId` | `GET /patients` → `patients[n].id` |
| `alertId` | `GET /alerts` → `alerts[n].id` |
| `roomId` | `POST /chat/rooms/direct` → `room.id`, or `GET /chat/rooms` → `rooms[n].id` |
| `logId` | `GET /logs/daily/:patientId` → `logs[n].id` |

---

## Getting credentials for the production server

**Production accounts are not seeded automatically.** An ADMIN must create your doctor account via:

```
POST /api/v1/auth/create-user   (ADMIN bearer token required)
```

Ask the clinic admin (or whoever holds the ADMIN account) to create a DOCTOR account and share the credentials with you directly.

**Doctor login is email + password — no OTP.** Once the admin creates your account (`POST /api/v1/auth/create-user`), you log in immediately with the email and password the admin set. There is no OTP step in the doctor login flow.

OTPs exist only for two other flows that the doctor app does not use:
- **Patient login** — phone → SMS OTP (`POST /auth/send-otp` + `POST /auth/verify-otp`). Patients only.
- **Forgot password** — sends a 6-digit OTP to the staff member's email (`POST /auth/forgot-password` + `POST /auth/reset-password`). Use this if you need to reset your password after account creation.

**Local dev only:** a seed script (`npm run db:seed` from `backend/`) creates test accounts with known credentials. These accounts exist only on a local development database — never on the production server. Ask the backend developer if you need local dev access.
