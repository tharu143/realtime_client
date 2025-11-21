import 'package:equatable/equatable.dart';

/// Metrics for observability and monitoring
class RealtimeMetrics extends Equatable {
  final int totalReconnects;
  final int totalMessagesSent;
  final int totalMessagesReceived;
  final int totalMessagesAcked;
  final int currentQueueSize;
  final int bytesSent;
  final int bytesReceived;
  final Duration? averageReconnectTime;
  final DateTime? lastConnectedAt;
  final DateTime? lastDisconnectedAt;
  final String? lastError;
  final int failedSendAttempts;
  final int successfulSendAttempts;

  const RealtimeMetrics({
    this.totalReconnects = 0,
    this.totalMessagesSent = 0,
    this.totalMessagesReceived = 0,
    this.totalMessagesAcked = 0,
    this.currentQueueSize = 0,
    this.bytesSent = 0,
    this.bytesReceived = 0,
    this.averageReconnectTime,
    this.lastConnectedAt,
    this.lastDisconnectedAt,
    this.lastError,
    this.failedSendAttempts = 0,
    this.successfulSendAttempts = 0,
  });

  RealtimeMetrics copyWith({
    int? totalReconnects,
    int? totalMessagesSent,
    int? totalMessagesReceived,
    int? totalMessagesAcked,
    int? currentQueueSize,
    int? bytesSent,
    int? bytesReceived,
    Duration? averageReconnectTime,
    DateTime? lastConnectedAt,
    DateTime? lastDisconnectedAt,
    String? lastError,
    int? failedSendAttempts,
    int? successfulSendAttempts,
  }) {
    return RealtimeMetrics(
      totalReconnects: totalReconnects ?? this.totalReconnects,
      totalMessagesSent: totalMessagesSent ?? this.totalMessagesSent,
      totalMessagesReceived:
          totalMessagesReceived ?? this.totalMessagesReceived,
      totalMessagesAcked: totalMessagesAcked ?? this.totalMessagesAcked,
      currentQueueSize: currentQueueSize ?? this.currentQueueSize,
      bytesSent: bytesSent ?? this.bytesSent,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      averageReconnectTime: averageReconnectTime ?? this.averageReconnectTime,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      lastDisconnectedAt: lastDisconnectedAt ?? this.lastDisconnectedAt,
      lastError: lastError ?? this.lastError,
      failedSendAttempts: failedSendAttempts ?? this.failedSendAttempts,
      successfulSendAttempts:
          successfulSendAttempts ?? this.successfulSendAttempts,
    );
  }

  @override
  List<Object?> get props => [
        totalReconnects,
        totalMessagesSent,
        totalMessagesReceived,
        totalMessagesAcked,
        currentQueueSize,
        bytesSent,
        bytesReceived,
        averageReconnectTime,
        lastConnectedAt,
        lastDisconnectedAt,
        lastError,
        failedSendAttempts,
        successfulSendAttempts,
      ];

  Map<String, dynamic> toJson() => {
        'totalReconnects': totalReconnects,
        'totalMessagesSent': totalMessagesSent,
        'totalMessagesReceived': totalMessagesReceived,
        'totalMessagesAcked': totalMessagesAcked,
        'currentQueueSize': currentQueueSize,
        'bytesSent': bytesSent,
        'bytesReceived': bytesReceived,
        'averageReconnectTimeMs': averageReconnectTime?.inMilliseconds,
        'lastConnectedAt': lastConnectedAt?.toIso8601String(),
        'lastDisconnectedAt': lastDisconnectedAt?.toIso8601String(),
        'lastError': lastError,
        'failedSendAttempts': failedSendAttempts,
        'successfulSendAttempts': successfulSendAttempts,
      };
}
