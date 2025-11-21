import 'package:logger/logger.dart';

/// Message delivery strategies for the realtime client.
///
/// Choose the appropriate strategy based on your application's requirements:
/// - [atMostOnce]: Fastest, but messages may be lost
/// - [atLeastOnce]: Reliable, but may have duplicates (use idempotency)
/// - [bestEffortOrdered]: Balanced approach with ordering guarantees
enum DeliveryStrategy {
  /// Fire-and-forget delivery. Messages are sent once without confirmation.
  ///
  /// Use this for non-critical updates where speed is more important than reliability.
  atMostOnce,

  /// Guaranteed delivery with acknowledgements and retries.
  ///
  /// Messages are queued and retried until acknowledged. May result in duplicates
  /// if acknowledgements are lost. Use idempotency keys to handle duplicates.
  atLeastOnce,

  /// Best-effort ordered delivery without strict guarantees.
  ///
  /// Provides a balance between reliability and performance.
  bestEffortOrdered,
}

/// Configuration for the realtime client.
///
/// This class contains all settings for connection management, delivery strategies,
/// retry behavior, and performance tuning.
///
/// Example:
/// ```dart
/// final config = RealtimeConfig(
///   url: 'wss://api.example.com/realtime',
///   deliveryStrategy: DeliveryStrategy.atLeastOnce,
///   maxRetries: 10,
///   heartbeatInterval: Duration(seconds: 30),
/// );
/// ```
class RealtimeConfig {
  /// The WebSocket or Socket.IO server URL.
  ///
  /// - For WebSocket: `ws://` or `wss://`
  /// - For Socket.IO: `http://` or `https://`
  final String url;

  /// The message delivery strategy to use.
  ///
  /// See [DeliveryStrategy] for available options.
  final DeliveryStrategy deliveryStrategy;

  /// Initial backoff delay for reconnection attempts.
  ///
  /// The actual delay increases exponentially with each failed attempt.
  final Duration initialRetryDelay;

  /// Maximum backoff delay between reconnection attempts.
  ///
  /// Prevents exponential backoff from growing indefinitely.
  final Duration maxRetryDelay;

  /// Jitter factor (0.0 to 1.0) to randomize retry delays.
  ///
  /// Helps prevent thundering herd problems when many clients reconnect simultaneously.
  final double jitter;

  /// Maximum number of reconnection attempts.
  ///
  /// Set to -1 for infinite retries.
  final int maxRetries;

  /// Interval between heartbeat ping messages.
  ///
  /// Keeps the connection alive and detects disconnections.
  final Duration heartbeatInterval;

  /// Timeout for heartbeat pong responses.
  ///
  /// If no pong is received within this time, the connection is considered dead.
  final Duration heartbeatTimeout;

  /// Whether to use TLS encryption (wss/https).
  ///
  /// Should be `true` in production for security.
  final bool useTls;

  /// Number of messages to batch together (0 to disable batching).
  ///
  /// Batching can improve throughput for high-frequency messages.
  final int batchSize;

  /// Time window for collecting messages into a batch.
  final Duration batchInterval;

  /// Logging level for the client.
  ///
  /// Use [Level.debug] for development, [Level.info] or [Level.warning] for production.
  final Level logLevel;

  /// Timeout for initial connection attempts.
  final Duration connectTimeout;

  /// Creates a new [RealtimeConfig] with the specified settings.
  ///
  /// All parameters except [url] have sensible defaults for most use cases.
  const RealtimeConfig({
    required this.url,
    this.deliveryStrategy = DeliveryStrategy.atLeastOnce,
    this.initialRetryDelay = const Duration(seconds: 1),
    this.maxRetryDelay = const Duration(seconds: 30),
    this.jitter = 0.2,
    this.maxRetries = -1,
    this.heartbeatInterval = const Duration(seconds: 25),
    this.heartbeatTimeout = const Duration(seconds: 10),
    this.useTls = true,
    this.batchSize = 0,
    this.batchInterval = const Duration(milliseconds: 50),
    this.logLevel = Level.info,
    this.connectTimeout = const Duration(seconds: 10),
  });
}
