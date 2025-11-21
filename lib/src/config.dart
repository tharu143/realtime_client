import 'package:logger/logger.dart';

enum DeliveryStrategy {
  atMostOnce,
  atLeastOnce,
  bestEffortOrdered,
}

class RealtimeConfig {
  final String url;
  final DeliveryStrategy deliveryStrategy;

  /// Initial backoff delay for reconnection
  final Duration initialRetryDelay;

  /// Maximum backoff delay
  final Duration maxRetryDelay;

  /// Jitter factor (0.0 to 1.0)
  final double jitter;

  /// Maximum number of reconnection attempts (-1 for infinite)
  final int maxRetries;

  /// Heartbeat interval
  final Duration heartbeatInterval;

  /// Heartbeat timeout (if pong not received)
  final Duration heartbeatTimeout;

  /// Whether to use TLS (wss/https)
  final bool useTls;

  /// Batch size for outgoing messages (0 to disable batching)
  final int batchSize;

  /// Batch interval
  final Duration batchInterval;

  /// Logging level
  final Level logLevel;

  /// Connect timeout
  final Duration connectTimeout;

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
