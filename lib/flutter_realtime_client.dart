/// A production-ready Flutter/Dart realtime client library.
///
/// This library provides robust connection management, persistent message queuing,
/// ordered delivery, and advanced features like typing indicators, presence management,
/// and read receipts for building reliable realtime applications.
///
/// ## Features
///
/// - **Dual Transport Support**: WebSocket and Socket.IO
/// - **Robust Connection Management**: Automatic reconnect with exponential backoff
/// - **Persistent Queue**: SQLite-based offline message storage
/// - **Ordered Delivery**: Monotonic sequence numbers and ACK protocol
/// - **Resume Protocol**: Seamless reconnection with message recovery
/// - **Advanced Features**: Typing indicators, presence, read receipts
/// - **Comprehensive Metrics**: Track connection health and performance
///
/// ## Quick Start
///
/// ```dart
/// import 'package:flutter_realtime_client/flutter_realtime_client.dart';
///
/// final client = RealtimeClient(
///   config: RealtimeConfig(url: 'ws://localhost:3001'),
///   queueStorage: SqliteQueueStorage(),
/// );
///
/// await client.connect();
///
/// // Send message
/// await client.sendEvent('chat.message', {'text': 'Hello!'});
///
/// // Receive messages
/// client.onMessage.listen((msg) {
///   print('Received: ${msg.payload}');
/// });
/// ```
///
/// See the [README](https://github.com/tharu143/realtime_client#readme) for more examples.
library flutter_realtime_client;

export 'src/client.dart';
export 'src/config.dart';
export 'src/protocol.dart';
export 'src/transport.dart';
export 'src/queue.dart';
export 'src/auth.dart';
export 'src/metrics.dart';
export 'src/features.dart';
export 'src/transports/websocket_transport.dart';
export 'src/transports/socketio_transport.dart';
