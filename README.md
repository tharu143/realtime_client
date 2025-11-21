# Realtime Client for Flutter/Dart

A **production-ready** Flutter/Dart realtime client library with robust connection management, persistence, ordered delivery, and advanced features for building reliable realtime applications.

---

## 🔥 What You Get (Main Uses)

### 1. **Live Chat & Messaging**
Instant messages, typing indicators, read receipts — reliable delivery even with flaky mobile networks.

### 2. **Real-time Order / Status Updates**
Food orders, delivery tracking, warehouse picking status — clients get accurate, ordered updates.

### 3. **Presence & Notifications (in-app)**
Who's online, agent availability, live support routing.

### 4. **Collaborative Apps**
Live cursors, shared documents, collaborative dashboards with ordered events.

### 5. **Telemetry & Live Metrics**
Push live KPIs, sensor data, device telemetry with guaranteed delivery and resume after reconnect.

### 6. **Command-and-Control / IoT**
Send commands to devices and ensure at-least-once delivery with ack and resume.

### 7. **Gaming / Low-Latency Events (non-competitive)**
Chat, matchmaking, lobby status, non-hard realtime multiplayer features.

### 8. **Audit / Compliance Workflows**
Exactly-ordered logs of actions (seq numbers + server timestamps) for audits.

### 9. **Enterprise Apps (ERP, CRM)**
Live updates for Sales Order changes, Delivery Note status, stock alerts integrated with ERPNext.

---

## ✅ Problems It Solves (Concrete)

| Problem | Solution |
|---------|----------|
| **Connection instability** | Automatic reconnect with exponential backoff + jitter → robust on mobile |
| **Message loss during disconnects** | Persistent unsent queue stored in SQLite/Hive → messages survive app restarts |
| **Duplicate messages after reconnect** | seq + ack + idempotency keys + resume protocol → de-duplication |
| **Out-of-order delivery** | Monotonic seq + server-side reordering / authoritative timestamps → preserve order |
| **Auth interruptions** | Pluggable token-refresh handler → seamless reauth & retry |
| **App killed / background** | Persistent queue + reconnect on network regained → sync when app restarts |
| **High throughput** | Batching, throttling, and background isolates → avoids UI jank |

---

## 🎯 Key Features & Why Each Matters

- **Exponential backoff + jitter** — Avoids thundering herd when server down
- **Heartbeat (ping/pong)** — Detect dead connections quickly and reconnect
- **Persistent queue** — No user data loss; good UX for offline-first apps
- **Ack & resume protocol** — Server and client agree on what's delivered/needed
- **Configurable delivery semantics** — Pick at-most-once or at-least-once per use-case
- **Network-awareness** — Respect connectivity changes; save battery by pausing when offline
- **Metrics & lifecycle events** — Observability for production debugging
- **Pluggable token refresh & secure storage** — Secure mobile auth flows
- **Typing indicators** — Real-time typing status for chat apps
- **Read receipts** — Track message read status
- **Presence management** — Track online/offline/away/busy status

---

## 🚀 Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  realtime_client:
    path: ./path/to/realtime_client
```

### Basic Usage

```dart
import 'package:realtime_client/realtime_client.dart';

// Initialize client
final client = RealtimeClient(
  config: RealtimeConfig(
    url: 'http://localhost:3000', // Socket.IO
    // or 'ws://localhost:3001' for raw WebSocket
    deliveryStrategy: DeliveryStrategy.atLeastOnce,
  ),
  queueStorage: SqliteQueueStorage(),
);

// Connect
await client.connect();

// Listen for messages
client.onMessage.listen((msg) {
  print('Received: ${msg.event} - ${msg.payload}');
});

// Send message
await client.sendEvent('chat.message', {
  'text': 'Hello World',
  'room': 'general',
});

// Disconnect
await client.disconnect();
```

---

## 📖 Advanced Features

### Typing Indicators

```dart
// Send typing indicator
await client.sendTypingIndicator(channelId: 'room-123', isTyping: true);

// Listen for typing
client.typingManager.typingStream.listen((typingMap) {
  final users = client.typingManager.getTypingUsers(channelId: 'room-123');
  print('Users typing: $users');
});

// Stop typing
await client.sendTypingIndicator(channelId: 'room-123', isTyping: false);
```

### Presence Management

```dart
// Update your presence
await client.updatePresence(PresenceStatus.online, metadata: {
  'device': 'mobile',
  'location': 'New York',
});

// Listen for presence updates
client.presenceManager.presenceStream.listen((presenceMap) {
  presenceMap.forEach((userId, info) {
    print('$userId is ${info.status.name}');
  });
});

// Check if user is online
final isOnline = client.presenceManager.isOnline('user-123');
```

### Read Receipts

```dart
// Send read receipt
await client.sendReadReceipt('message-id-123');

// Listen for read receipts
client.readReceiptManager.receiptsStream.listen((receiptsMap) {
  final receipts = client.readReceiptManager.getReceipts('message-id-123');
  print('Read by ${receipts.length} users');
});

// Check if specific user read message
final hasRead = client.readReceiptManager.hasUserRead('message-id-123', 'user-456');
```

### Metrics & Observability

```dart
// Listen to metrics
client.metricsStream.listen((metrics) {
  print('Total reconnects: ${metrics.totalReconnects}');
  print('Messages sent: ${metrics.totalMessagesSent}');
  print('Messages acked: ${metrics.totalMessagesAcked}');
  print('Queue size: ${metrics.currentQueueSize}');
  print('Avg reconnect time: ${metrics.averageReconnectTime}');
});

// Get current metrics
final metrics = client.metrics;
print(metrics.toJson());
```

### Connection State Monitoring

```dart
client.connectionState.listen((state) {
  switch (state) {
    case ConnectionState.connecting:
      print('Connecting...');
      break;
    case ConnectionState.connected:
      print('Connected!');
      break;
    case ConnectionState.disconnected:
      print('Disconnected');
      break;
    case ConnectionState.reconnecting:
      print('Reconnecting...');
      break;
    case ConnectionState.failed:
      print('Connection failed');
      break;
  }
});
```

### Authentication with Token Refresh

```dart
final authDelegate = SecureStorageAuthDelegate(
  refreshTokenCallback: () async {
    // Call your refresh endpoint
    final response = await http.post(
      Uri.parse('https://api.example.com/refresh'),
      body: {'refresh_token': 'your-refresh-token'},
    );
    final newToken = jsonDecode(response.body)['access_token'];
    return newToken;
  },
);

final client = RealtimeClient(
  config: config,
  queueStorage: SqliteQueueStorage(),
  authDelegate: authDelegate,
);
```

---

## 🛠 Real-World Examples

### A. Chat App with Message Reliability

```dart
// User types → client assigns seq=101, stores in persistent queue
await client.sendEvent('chat.message', {
  'text': 'Hello!',
  'room': 'general',
});

// Shows UI "sending"
// Client sends message; server replies ack with ack_seq=101
client.onAck.listen((ack) {
  print('Message ${ack.ackSeq} delivered!');
  // Update UI to show "delivered"
});

// Network drops; user writes 5 messages → all queued
// On reconnect client sends resume with last_ack_seq
// Server ignores duplicates and accepts missed ones
// UI updates to show all messages delivered
```

### B. Delivery Tracking for Courier

```dart
// Server pushes event: delivery.status with seq
client.onMessage.listen((msg) {
  if (msg.event == 'delivery.status') {
    final status = msg.payload!['status'];
    final location = msg.payload!['location'];
    
    // Update map with current location
    updateDeliveryMap(location);
    
    // If client missed messages (offline), after resume
    // server sends missing events so app shows correct
    // current status and step-by-step timeline
  }
});
```

### C. ERPNext Integration for Sales Orders

```dart
// Sales order updated in backend → realtime event to Sales Reps
client.onMessage.listen((msg) {
  if (msg.event == 'sales_order.updated') {
    final orderId = msg.payload!['order_id'];
    final status = msg.payload!['status'];
    
    // Update local cache
    updateSalesOrder(orderId, status);
    
    // If rep's app offline, queued events resend on resume
    // so they see consistent order of changes and don't miss approvals
  }
});
```

---

## 📦 When to Use This (vs Polling)

### ✅ Use Realtime Client When:

- Low-latency updates matter (chat, orders, presence)
- Polling cost is high / inefficient
- You need ordered delivery and/or guaranteed delivery semantics
- Mobile network is unreliable
- Offline-first experience is important

### ❌ Avoid If:

- Your updates are rare and occasional polling is simpler
- Strict ultra-low latency competitive gaming — you'll need more specialized networking
- You don't need delivery guarantees

---

## ⚖️ Trade-offs & Considerations

| Aspect | Consideration |
|--------|---------------|
| **Complexity** | More code, server support required (ack/resume) |
| **Server responsibility** | Server must implement ack/resume, dedup, and persistence for missed messages |
| **Resource usage** | Persistent connections use resources; scale server accordingly |
| **Mobile background limits** | iOS background restrictions may limit realtime while app is suspended (use push notifications as fallback) |

---

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   RealtimeClient                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Connection  │  │   Message    │  │   Feature    │  │
│  │  Management  │  │    Queue     │  │  Managers    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         │                  │                  │         │
│         ▼                  ▼                  ▼         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Transport   │  │   SQLite     │  │  Presence    │  │
│  │ (WS/Socket.IO│  │   Storage    │  │  Typing      │  │
│  │     )        │  │              │  │  Receipts    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Components

- **RealtimeClient**: Main entry point, handles state machine
- **Transport**: Abstract interface for `WebSocketTransport` and `SocketIOTransport`
- **QueueStorage**: Persistent storage for offline messages (SQLite)
- **AuthDelegate**: Handles token storage and refresh
- **PresenceManager**: Tracks user online/offline status
- **TypingIndicatorManager**: Manages typing indicators with auto-expiry
- **ReadReceiptManager**: Tracks message read receipts
- **Metrics**: Observability and monitoring

---

## 🔧 Configuration Options

```dart
final config = RealtimeConfig(
  url: 'ws://localhost:3001',
  deliveryStrategy: DeliveryStrategy.atLeastOnce, // atMostOnce, bestEffortOrdered
  initialRetryDelay: Duration(seconds: 1),
  maxRetryDelay: Duration(seconds: 30),
  jitter: 0.2, // 20% jitter
  maxRetries: -1, // -1 for infinite
  heartbeatInterval: Duration(seconds: 25),
  heartbeatTimeout: Duration(seconds: 10),
  useTls: true, // Use wss:// or https://
  batchSize: 0, // 0 to disable batching
  batchInterval: Duration(milliseconds: 50),
  logLevel: Level.info,
  connectTimeout: Duration(seconds: 10),
);
```

---

## 🧪 Testing

Run unit tests:

```bash
cd realtime_client
flutter test
```

Run integration tests (requires server):

```bash
# Terminal 1: Start server
cd server-example
npm install
npm run start:io  # or start:ws

# Terminal 2: Run tests
cd ..
flutter test test/integration_test.dart
```

---

## 🖥 Server Setup

### Protocol Specification

All messages are JSON with this structure:

```json
{
  "type": "event" | "ack" | "resume" | "resume_response" | "meta" | "error",
  "seq": 123,
  "client_id": "uuid",
  "idempotency_key": "uuid",
  "event": "chat.message",
  "payload": { ... },
  "timestamp": "2025-11-21T14:48:02Z"
}
```

### Running Example Servers

#### Socket.IO Server (Port 3000)

```bash
cd server-example
npm install
npm run start:io
```

#### WebSocket Server (Port 3001)

```bash
cd server-example
npm install
npm run start:ws
```

### Server Requirements

Your server must implement:

1. **ACK messages**: Reply with `{type: "ack", ack_seq: N}` when receiving events
2. **Resume protocol**: Handle `{type: "resume", last_ack_seq: N}` and respond with missed messages
3. **Idempotency**: Use `idempotency_key` to deduplicate messages
4. **Sequence tracking**: Track `seq` numbers per client

---

## 📱 Running the Example App

```bash
cd example
flutter pub get
flutter run
```

**Note for Android Emulator**: Use `http://10.0.2.2:3000` instead of `localhost:3000`

---

## 🔐 Security Best Practices

1. **Always use TLS** in production (`wss://` or `https://`)
2. **Store tokens securely** using `flutter_secure_storage`
3. **Implement token refresh** to handle expiry
4. **Validate server certificates** (enabled by default)
5. **Use CORS** properly on server
6. **Implement rate limiting** on server
7. **Sanitize user input** before sending

---

## 📊 Performance Tips

1. **Batch messages** when sending many at once (configure `batchSize`)
2. **Use isolates** for heavy JSON parsing if needed
3. **Limit queue size** to prevent memory issues
4. **Monitor metrics** to detect issues early
5. **Use connection pooling** on server
6. **Implement backpressure** if queue grows too large

---

## 🐛 Troubleshooting

### Connection keeps dropping

- Check network stability
- Increase `heartbeatInterval` and `heartbeatTimeout`
- Verify server is responding to heartbeats

### Messages not being delivered

- Check `metricsStream` for failed send attempts
- Verify server is sending ACKs
- Check queue size with `pendingCount`

### High memory usage

- Clear old messages from queue periodically
- Reduce `maxRetries` to prevent infinite queue growth
- Monitor `currentQueueSize` metric

### Auth errors

- Ensure `authDelegate.refreshAccessToken()` is implemented correctly
- Check token expiry times
- Verify server accepts refreshed tokens

---

## 📄 License

MIT License - see LICENSE file for details

---

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new features
4. Ensure all tests pass
5. Submit a pull request

---

## 📞 Support

For issues, questions, or feature requests, please open an issue on GitHub.

---

**Built with ❤️ for reliable realtime communication in Flutter**
