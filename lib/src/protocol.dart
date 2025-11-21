import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'protocol.g.dart';

enum MessageType {
  @JsonValue('event')
  event,
  @JsonValue('ack')
  ack,
  @JsonValue('resume')
  resume,
  @JsonValue('resume_response')
  resumeResponse,
  @JsonValue('meta')
  meta,
  @JsonValue('error')
  error,
}

@JsonSerializable(explicitToJson: true)
class RealtimeMessage {
  final MessageType type;
  final int? seq;
  @JsonKey(name: 'client_id')
  final String? clientId;
  @JsonKey(name: 'idempotency_key')
  final String? idempotencyKey;
  final String? event;
  final Map<String, dynamic>? payload;
  final String timestamp;

  // For Ack
  @JsonKey(name: 'ack_seq')
  final int? ackSeq;

  // For Resume
  @JsonKey(name: 'last_ack_seq')
  final int? lastAckSeq;

  // For Resume Response
  @JsonKey(name: 'server_ack_seq')
  final int? serverAckSeq;
  final List<RealtimeMessage>? missing;

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

  factory RealtimeMessage.fromJson(Map<String, dynamic> json) =>
      _$RealtimeMessageFromJson(json);
  Map<String, dynamic> toJson() => _$RealtimeMessageToJson(this);

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
