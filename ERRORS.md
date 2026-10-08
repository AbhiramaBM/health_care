# Error Reference — AHC Doctor App API

## Response format

All errors return JSON with a single `error` field:

```json
{ "error": "Human-readable message describing what went wrong." }
```

In development (`NODE_ENV=development`) some 500 responses also include a `message` field with the raw exception text. Never show this field to end users.

There is no numeric error code inside the body — use the HTTP status code.

---

## HTTP status codes

| Code | When it occurs |
|---|---|
| `200 OK` | Request succeeded. |
| `201 Created` | Resource created (e.g., note, message, prescription). |
| `400 Bad Request` | Missing required field, invalid value, or malformed JSON body. |
| `401 Unauthorized` | No token, invalid token, expired token, or replayed refresh token. |
| `403 Forbidden` | Valid token but insufficient role, or accessing another patient's data. |
| `404 Not Found` | Resource does not exist or the caller does not have visibility of it. |
| `409 Conflict` | Resource already exists or action already taken (e.g., alert already acknowledged). |
| `423 Locked` | Account locked after 5 failed password attempts (unlocks after 15 min). |
| `429 Too Many Requests` | Rate limit exceeded. See rate limits below. |
| `500 Internal Server Error` | Unexpected server error. |

---

## Common error messages

### Auth

| Scenario | Status | `error` value |
|---|---|---|
| Missing `Authorization` header | 401 | `No token provided` |
| Expired or invalid JWT | 401 | `Invalid or expired token` |
| Account is deactivated | 401 | `Account is deactivated` |
| Wrong email or password | 401 | `Invalid email or password` |
| Account locked (too many failed logins) | 423 | `Account locked. Try again in X minutes.` |
| Missing `refreshToken` body field | 400 | `refreshToken is required` |
| Refresh token not found or already used | 401 | `Invalid or expired refresh token. Please log in again.` |
| Account deactivated (caught at refresh) | 403 | `Account is deactivated.` |
| OTP invalid *(patient login or staff password reset only — not doctor login)* | 400 | `Invalid OTP` |
| OTP expired or brute-forced *(patient login or staff password reset only)* | 400 | `OTP has expired or been invalidated. Please request a new one.` |

### Role / access

| Scenario | Status | `error` value |
|---|---|---|
| Role not in the allowed list for this route | 403 | `Access denied` |
| Patient accessing another patient's record | 403 | `Access denied` |
| DOCTOR accessing an alert outside their patients | 403 | `Access denied` (varies) |
| Not a member of the requested chat room | 403 | `You are not a member of this room` |

### Resources

| Scenario | Status | `error` value |
|---|---|---|
| Patient not found | 404 | `Patient not found` |
| Alert not found | 404 | `Alert not found.` |
| Log not found | 404 | `Log not found` |
| Staff user not found | 404 | `User not found` |
| Chat room not found | 404 | `Room not found` |
| Alert already acknowledged | 409 | `Alert already acknowledged` |

---

## Rate limits

| Limit | Scope | Applies to |
|---|---|---|
| 5 requests / minute | Per IP | `POST /api/v1/auth/login`, `/verify-otp`, `/reset-password`, `/check-phone`, `/login-pin` |
| 3 requests / 5 minutes | Per IP | `POST /api/v1/auth/send-otp`, `/forgot-password` |
| 500 requests / 15 minutes | Per IP | All `/api/*` routes |

When a rate limit is hit the server returns `429` with a `Retry-After` header (value in seconds):

```http
HTTP/1.1 429 Too Many Requests
Retry-After: 47

{ "error": "Too many requests, please try again later." }
```

---

## Socket errors

Socket operation failures are emitted as `error` events back to the calling socket only (not broadcast):

```json
{ "message": "You are not a member of this room" }
```

Common socket error messages:

| Scenario | `message` |
|---|---|
| Connecting without a token | `Unauthorized: No token provided` |
| Connecting with an expired token | `Unauthorized: <jwt error>` |
| Patient attempting to connect | `Unauthorized: Patients cannot access team chat` |
| `join_room` for a room you are not in | `You are not a member of this room` |
| `send_message` missing `roomId` or `content` | `roomId and content are required` |
| `send_message` with blank content | `Message content cannot be empty` |
| `delete_message` on another user's message | `You can only delete your own messages` |
| `react_message` missing `messageId` or `emoji` | `messageId and emoji are required` |

---

## Validation notes

- String fields in `req.body` are globally sanitised: `< > { } [ ] \ / & " '` are stripped before reaching any controller.
- `bmi` is always calculated server-side — sending it in a request body has no effect.
- Clinical fields (`diabeticSince`, `hba1c`, `cPeptide`, etc.) sent by a PATIENT role are silently stripped, not rejected.
