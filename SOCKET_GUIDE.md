# Socket.IO Guide — AHC Doctor App

## Connection

| Property | Value |
|---|---|
| **Server URL** | Same host and port as the HTTP API (`http://localhost:3000` in dev) |
| **Namespace** | Default `/` — do not specify a custom namespace |
| **Transport** | WebSocket with polling fallback |

## Authentication

Pass the JWT access token at connection time. Three accepted locations (in priority order):

```dart
// Preferred — socket.io auth option
final socket = io('http://localhost:3000', OptionBuilder()
  .setAuth({'token': accessToken})
  .build());
```

```dart
// Alternative — query parameter
final socket = io('http://localhost:3000?token=$accessToken', ...);
```

```dart
// Alternative — Authorization header
// handshake headers: { 'Authorization': 'Bearer $accessToken' }
```

The token is verified once at connection time. If it is expired or invalid the server emits a connection error with the message `Unauthorized: ...` and the socket is not accepted.

**Only DOCTOR, DIETICIAN, STAFF, and ADMIN roles can connect.** PATIENT connections are rejected with `Unauthorized: Patients cannot access team chat`.

## Reconnection

Socket.io rooms are in-memory. After any reconnect the client **must re-emit `join_room`** for every room it wants to receive messages from.

---

## Events Reference

### Client → Server

---

#### `join_room`

Join a room to start receiving its messages. Must be called after connect and after every reconnect.

```json
emit: "join_room"
payload: "<roomId>"   // plain string UUID
```

On failure the server emits `error` to the caller:
```json
{ "message": "You are not a member of this room" }
```

---

#### `leave_room`

Stop receiving messages from a room.

```json
emit: "leave_room"
payload: "<roomId>"
```

---

#### `send_message`

Send a message to a team chat room (DIRECT or GROUP).

```json
emit: "send_message"
payload: {
  "roomId":     "<roomId>",
  "content":    "HbA1c result in — looks good.",
  "mentions":   [{ "type": "USER", "id": "<userId>" }],
  "references": []
}
```

`mentions` and `references` are optional. On success the server broadcasts `new_message` to **all** sockets in the room (including the sender). On failure:
```json
emit: "error"
payload: { "message": "roomId and content are required" }
```

---

#### `delete_message`

Delete your own message (soft-delete; content is cleared).

```json
emit: "delete_message"
payload: "<messageId>"
```

Server broadcasts `message_deleted` to the room on success.

---

#### `typing`

Notify others that you are typing.

```json
emit: "typing"
payload: "<roomId>"
```

Server broadcasts `user_typing` to **other** room members only (no echo to sender).

---

#### `stop_typing`

Notify others that you stopped typing.

```json
emit: "stop_typing"
payload: "<roomId>"
```

Server broadcasts `user_stop_typing` to other room members only.

---

#### `message_delivered`

Tell the server a message has been delivered to this device. Call this when the app receives the message (via socket or FCM). Only the first call for a given messageId writes to the database — subsequent calls are no-ops.

```json
emit: "message_delivered"
payload: "<messageId>"
```

Server broadcasts `message_delivered` to all sockets in the room.

---

#### `read_message`

Tell the server the user has read all messages in a room (e.g., when the chat screen is opened or scrolled to the bottom). Updates `ChatMember.lastReadAt` in the database.

```json
emit: "read_message"
payload: { "roomId": "<roomId>" }
```

Server broadcasts `messages_read` to **other** room members only.

---

#### `react_message`

Toggle an emoji reaction on a message. Calling it again with the same emoji removes the reaction.

```json
emit: "react_message"
payload: {
  "messageId": "<messageId>",
  "emoji": "👍"
}
```

Server broadcasts `reaction_updated` to the room.

---

### Server → Client

---

#### `new_message`

A new message was sent to a room you have joined.

```json
{
  "id":         "<messageId>",
  "roomId":     "<roomId>",
  "senderId":   "<userId>",
  "content":    "Lab results look good.",
  "mentions":   [],
  "references": [],
  "isDeleted":  false,
  "createdAt":  "2026-10-07T10:00:00.000Z",
  "sender": {
    "id":   "<userId>",
    "name": "Dr. Priya Sharma",
    "role": "DOCTOR"
  }
}
```

Emitted by both the socket `send_message` handler and the REST `POST /chat/rooms/:roomId/messages` endpoint.

---

#### `message_deleted`

A message was soft-deleted.

```json
{
  "messageId": "<messageId>",
  "deletedAt": "2026-10-07T10:05:00.000Z"
}
```

---

#### `message_delivered`

A message reached at least one device of the recipient.

```json
{
  "messageId":   "<messageId>",
  "deliveredAt": "2026-10-07T10:00:01.000Z"
}
```

`deliveredAt` reflects the timestamp of the first delivery report. Subsequent reports are no-ops in the DB but the broadcast still fires.

---

#### `messages_read`

A member has read all messages in a room up to `readAt`.

```json
{
  "userId": "<userId>",
  "roomId": "<roomId>",
  "readAt": "2026-10-07T10:02:00.000Z"
}
```

**Group room read receipts:** each member has an independent `lastReadAt`. To determine whether a specific message has been read by a specific member: `message.createdAt <= member.lastReadAt`. Fetch all member `lastReadAt` values from `GET /api/v1/chat/rooms/:roomId`.

---

#### `user_typing`

A room member started typing.

```json
{
  "userId": "<userId>",
  "name":   "Dr. Priya Sharma",
  "roomId": "<roomId>"
}
```

---

#### `user_stop_typing`

A room member stopped typing.

```json
{
  "userId": "<userId>",
  "roomId": "<roomId>"
}
```

---

#### `reaction_updated`

The reaction set on a message changed.

```json
{
  "messageId": "<messageId>",
  "reactions": [
    { "id": "<reactionId>", "emoji": "👍", "userId": "<userId>" }
  ]
}
```

---

#### `error`

Emitted to the caller only when an operation fails (not broadcast).

```json
{ "message": "You are not a member of this room" }
```

---

## Minimal Connect → Join → Send → Mark Read Example

```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

final socket = IO.io(
  'http://localhost:3000',
  IO.OptionBuilder()
    .setTransports(['websocket'])
    .setAuth({'token': accessToken})
    .build(),
);

socket.onConnect((_) {
  // 1. Join the room immediately after connect
  socket.emit('join_room', roomId);
});

// 2. Receive messages
socket.on('new_message', (data) {
  final message = data as Map<String, dynamic>;
  renderMessage(message);
  // 3. Report delivery
  socket.emit('message_delivered', message['id']);
});

// 4. Mark all messages read when the screen opens
void onChatScreenOpen() {
  socket.emit('read_message', {'roomId': roomId});
}

// 5. Typing indicator
void onTextFieldChanged(String value) {
  socket.emit('typing', roomId);
}

void onTextFieldSubmitted() {
  socket.emit('stop_typing', roomId);
  socket.emit('send_message', {
    'roomId':  roomId,
    'content': messageText,
  });
}

// 6. Clean up on screen dispose
socket.emit('leave_room', roomId);
socket.disconnect();
```
