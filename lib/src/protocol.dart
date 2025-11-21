import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'protocol.g.dart';

/// Types of messages exchanged between client and server.
///
/// Each message type serves a specific purpose in the realtime protocol.
enum MessageType {
  /// Application-level event message containing user data.
  @JsonValue('event')
  event,

  /// Acknowledgement message confirming receipt of an event.
  @JsonValue('ack')
  ack,

  /// Resume request sent by client after reconnection.
  @JsonValue('resume')
  resume,

  /// Server response to resume request with missed messages.
  @JsonValue('resume_response')
  resumeResponse,

  /// Protocol-level metadata message (e.g., ping/pong).
  @JsonValue('meta')
  meta,

  /// Error message indicating a protocol or application error.
  @JsonValue('error')
  error,
}

/// A message in the realtime protocol.
///
/// This class represents all types of messages exchanged between client and server,
/// including events, acknowledgements, resume requests, and errors.
///
/// Messages are serialized to/from JSON for transmission over the network.
@JsonSerializable(explicitToJson: true)
class RealtimeMessage {
  /// The type of this message.
  final MessageType type;

  /// Monotonic sequence number for ordering (used in event messages).
  final int? seq;

  /// Unique identifier for the client that sent this message.
  @JsonKey(name: 'client_id')
  final String? clientId;

  /// Unique key for idempotent message processing.
  @JsonKey(name: 'idempotency_key')
  final String? idempotencyKey;

  /// Event name (for event messages).
  final String? event;

  /// Event payload data (for event messages).
  final Map<String, dynamic>? payload;

  /// ISO 8601 timestamp when the message was created.
  final String timestamp;

  /// Sequence number being acknowledged (for ACK messages).
  @JsonKey(name: 'ack_seq')
  final int? ackSeq;

  /// Last acknowledged sequence number (for resume messages).
  @JsonKey(name: 'last_ack_seq')
  final int? lastAckSeq;

  /// Server's highest acknowledged sequence (for resume response).
  @JsonKey(name: 'server_ack_seq')
  final int? serverAckSeq;

  /// List of missed messages (for resume response).
  final List<RealtimeMessage>? missing;

  /// Creates a new [RealtimeMessage].
  ///
  /// Use the factory constructors ([event], [ack], [resume]) instead
  /// of calling this constructor directly.
  RealtimeMessage({
    required this.type,
    this.seq,
    this.clientId,
    this.idempotencyKey,
    this.event,
    this.payload,
    required this.timestamp,
    this.ackSeq,
    this.lastAckSeq,
    this.serverAckSeq,
    this.missing,
  });

  /// Creates a [RealtimeMessage] from JSON.
  factory RealtimeMessage.fromJson(Map<String, dynamic> json) =>
      _$RealtimeMessageFromJson(json);

  /// Converts this message to JSON.
  Map<String, dynamic> toJson() => _$RealtimeMessageToJson(this);

  /// Creates an event message.
  ///
  /// Event messages carry application data from client to server or vice versa.
  ///
  /// - [event]: The event name (e.g., 'chat.message', 'user.joined')
  /// - [payload]: The event data
  /// - [seq]: Optional sequence number (assigned by client if not provided)
  /// - [clientId]: Optional client identifier
  /// - [idempotencyKey]: Optional idempotency key (auto-generated if not provided)
  factory RealtimeMessage.event({
    required String event,
    required Map<String, dynamic> payload,
    int? seq,
    String? clientId,
    String? idempotencyKey,
  }) {
    return RealtimeMessage(
      type: MessageType.event,
      event: event,
      payload: payload,
      seq: seq,
      clientId: clientId,
      idempotencyKey: idempotencyKey ?? const Uuid().v4(),
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  /// Creates an acknowledgement message.
  ///
  /// ACK messages confirm receipt of an event message.
  ///
  /// - [ackSeq]: The sequence number being acknowledged
  /// - [clientId]: Optional client identifier
  factory RealtimeMessage.ack({
    required int ackSeq,
    String? clientId,
  }) {
    return RealtimeMessage(
      type: MessageType.ack,
      ackSeq: ackSeq,
      clientId: clientId,
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  /// Creates a resume request message.
  ///
  /// Resume messages are sent by the client after reconnection to request
  /// any messages that were missed during the disconnection.
  ///
  /// - [lastAckSeq]: The last sequence number acknowledged before disconnection
  /// - [clientId]: The client identifier
  factory RealtimeMessage.resume({
    required int lastAckSeq,
    required String clientId,
  }) {
    return RealtimeMessage(
      type: MessageType.resume,
      lastAckSeq: lastAckSeq,
      clientId: clientId,
      timestamp: DateTime.now().toIso8601String(),
    );
  }
}
