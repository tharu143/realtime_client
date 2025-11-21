# Realtime Client - Quick Reference

## Installation

```yaml
dependencies:
  flutter_realtime_client:
    path: ./flutter_realtime_client
```

## Basic Setup

```dart
import 'package:flutter_realtime_client/flutter_realtime_client.dart';

final client = RealtimeClient(
  config: RealtimeConfig(
    url: 'http://localhost:3000',
    deliveryStrategy: DeliveryStrategy.atLeastOnce,
  ),
  queueStorage: SqliteQueueStorage(),
);

await client.connect();
```

## Common Operations

### Send Message
```dart
await client.sendEvent('chat.message', {
  'text': 'Hello World',
  'room': 'general',
});
```

### Receive Messages
```dart
client.onMessage.listen((msg) {
  print('Event: ${msg.event}');
  print('Payload: ${msg.payload}');
});
```

### Monitor Connection
```dart
client.connectionState.listen((state) {
  print('Connection: ${state.name}');
});
```

### Check Queue
```dart
final pending = await client.pendingCount;
print('Pending messages: $pending');
```

## Advanced Features

### Typing Indicators
```dart
// Start typing
await client.sendTypingIndicator(channelId: 'room-1', isTyping: true);

// Listen
client.typingManager.typingStream.listen((typing) {
  final users = client.typingManager.getTypingUsers(channelId: 'room-1');
});

// Stop typing
await client.sendTypingIndicator(channelId: 'room-1', isTyping: false);
```

### Presence
```dart
// Update status
await client.updatePresence(PresenceStatus.online);

// Listen
client.presenceManager.presenceStream.listen((presence) {
  presence.forEach((userId, info) {
    print('$userId: ${info.status.name}');
  });
});

// Check
final isOnline = client.presenceManager.isOnline('user-123');
```

### Read Receipts
```dart
// Send receipt
await client.sendReadReceipt('message-id-123');

// Listen
client.readReceiptManager.receiptsStream.listen((receipts) {
  final count = client.readReceiptManager.getReceipts('message-id-123').length;
});
```

### Metrics
```dart
client.metricsStream.listen((metrics) {
  print('Reconnects: ${metrics.totalReconnects}');
  print('Sent: ${metrics.totalMessagesSent}');
  print('Acked: ${metrics.totalMessagesAcked}');
  print('Queue: ${metrics.currentQueueSize}');
});
```

## Configuration Options

```dart
RealtimeConfig(
  url: 'ws://localhost:3001',
  
  // Delivery
  deliveryStrategy: DeliveryStrategy.atLeastOnce,
  
  // Reconnection
  initialRetryDelay: Duration(seconds: 1),
  maxRetryDelay: Duration(seconds: 30),
  jitter: 0.2,
  maxRetries: -1, // -1 = infinite
  
  // Heartbeat
  heartbeatInterval: Duration(seconds: 25),
  heartbeatTimeout: Duration(seconds: 10),
  
  // Security
  useTls: true,
  
  // Performance
  batchSize: 0, // 0 = disabled
  batchInterval: Duration(milliseconds: 50),
  
  // Logging
  logLevel: Level.info,
  
  // Connection
  connectTimeout: Duration(seconds: 10),
)
```

## Authentication

```dart
final authDelegate = SecureStorageAuthDelegate(
  refreshTokenCallback: () async {
    // Your refresh logic
    return newToken;
  },
);

final client = RealtimeClient(
  config: config,
  queueStorage: SqliteQueueStorage(),
  authDelegate: authDelegate,
);
```

## Server URLs

- **Socket.IO**: `http://localhost:3000` or `https://api.example.com`
- **WebSocket**: `ws://localhost:3001` or `wss://api.example.com/ws`
- **Android Emulator**: Use `http://10.0.2.2:3000` instead of `localhost`

## Message Protocol

### Event Message
```json
{
  "type": "event",
  "seq": 123,
  "client_id": "uuid",
  "idempotency_key": "uuid",
  "event": "chat.message",
  "payload": { "text": "Hello" },
  "timestamp": "2025-11-21T14:48:02Z"
}
```

### ACK Message
```json
{
  "type": "ack",
  "ack_seq": 123,
  "client_id": "uuid",
  "timestamp": "2025-11-21T14:48:02Z"
}
```

### Resume Message
```json
{
  "type": "resume",
  "last_ack_seq": 100,
  "client_id": "uuid",
  "timestamp": "2025-11-21T14:48:02Z"
}
```

## Error Handling

```dart
client.onError.listen((error) {
  print('Error: $error');
  // Log to Sentry, etc.
});
```

## Cleanup

```dart
await client.disconnect();
client.dispose();
```

## Testing

### Unit Tests
```bash
flutter test
```

### Start Test Server
```bash
cd server-example
npm install
npm run start:io  # Socket.IO on port 3000
npm run start:ws  # WebSocket on port 3001
```

### Run Example App
```bash
cd example
flutter pub get
flutter run
```

## Common Patterns

### Chat App
```dart
// Send message
await client.sendEvent('chat.message', {
  'text': text,
  'room': roomId,
});

// Receive messages
client.onMessage.listen((msg) {
  if (msg.event == 'chat.message') {
    addMessageToUI(msg.payload!['text']);
  }
});

// Typing indicator
textField.onChanged = (text) {
  client.sendTypingIndicator(channelId: roomId, isTyping: true);
};
```

### Delivery Tracking
```dart
client.onMessage.listen((msg) {
  if (msg.event == 'delivery.status') {
    final location = msg.payload!['location'];
    updateMapMarker(location);
  }
});
```

### Live Dashboard
```dart
client.onMessage.listen((msg) {
  if (msg.event == 'metrics.update') {
    updateDashboard(msg.payload!);
  }
});
```

## Troubleshooting

### Connection Issues
- Check server is running
- Verify URL is correct
- Check network connectivity
- Review logs (`logLevel: Level.debug`)

### Messages Not Delivered
- Check `pendingCount`
- Verify server sends ACKs
- Check `metricsStream` for errors

### High Memory
- Clear old messages: `await client.clearPending()`
- Reduce `maxRetries`
- Monitor `currentQueueSize`

### Auth Errors
- Implement `refreshAccessToken()`
- Check token expiry
- Verify server accepts tokens

## Performance Tips

1. **Batch messages** for high throughput
2. **Monitor metrics** to detect issues
3. **Clear old queue** periodically
4. **Use isolates** for heavy parsing
5. **Limit queue size** to prevent memory issues

## Security Checklist

- ✅ Use TLS in production (`useTls: true`)
- ✅ Store tokens securely (`flutter_secure_storage`)
- ✅ Implement token refresh
- ✅ Validate server certificates
- ✅ Use CORS on server
- ✅ Implement rate limiting
- ✅ Sanitize user input

## Resources

- **README.md**: Full documentation
- **DESIGN.md**: Architecture details
- **IMPLEMENTATION_SUMMARY.md**: Complete feature list
- **example/**: Demo app
- **server-example/**: Test servers

---

**Need help?** Check the full README or open an issue on GitHub.
