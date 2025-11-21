import 'dart:async';
import 'package:rxdart/rxdart.dart';

/// Presence status for a user/client
enum PresenceStatus {
  online,
  offline,
  away,
  busy,
}

class PresenceInfo {
  final String userId;
  final PresenceStatus status;
  final DateTime lastSeen;
  final Map<String, dynamic>? metadata;

  PresenceInfo({
    required this.userId,
    required this.status,
    required this.lastSeen,
    this.metadata,
  });

  factory PresenceInfo.fromJson(Map<String, dynamic> json) {
    return PresenceInfo(
      userId: json['userId'] as String,
      status: PresenceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PresenceStatus.offline,
      ),
      lastSeen: DateTime.parse(json['lastSeen'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'status': status.name,
        'lastSeen': lastSeen.toIso8601String(),
        if (metadata != null) 'metadata': metadata,
      };
}

/// Manages presence tracking for users
class PresenceManager {
  final _presenceController =
      BehaviorSubject<Map<String, PresenceInfo>>.seeded({});
  final Map<String, PresenceInfo> _presenceMap = {};

  Stream<Map<String, PresenceInfo>> get presenceStream =>
      _presenceController.stream;
  Map<String, PresenceInfo> get currentPresence =>
      Map.unmodifiable(_presenceMap);

  void updatePresence(PresenceInfo info) {
    _presenceMap[info.userId] = info;
    _presenceController.add(Map.from(_presenceMap));
  }

  void updatePresenceFromJson(Map<String, dynamic> json) {
    final info = PresenceInfo.fromJson(json);
    updatePresence(info);
  }

  void removeUser(String userId) {
    _presenceMap.remove(userId);
    _presenceController.add(Map.from(_presenceMap));
  }

  PresenceInfo? getPresence(String userId) => _presenceMap[userId];

  bool isOnline(String userId) {
    final presence = _presenceMap[userId];
    return presence?.status == PresenceStatus.online;
  }

  void dispose() {
    _presenceController.close();
  }
}

/// Typing indicator state
class TypingIndicator {
  final String userId;
  final String? channelId;
  final DateTime timestamp;

  TypingIndicator({
    required this.userId,
    this.channelId,
    required this.timestamp,
  });

  factory TypingIndicator.fromJson(Map<String, dynamic> json) {
    return TypingIndicator(
      userId: json['userId'] as String,
      channelId: json['channelId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        if (channelId != null) 'channelId': channelId,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Manages typing indicators with auto-expiry
class TypingIndicatorManager {
  final Duration timeout;
  final _typingController =
      BehaviorSubject<Map<String, TypingIndicator>>.seeded({});
  final Map<String, TypingIndicator> _typingMap = {};
  final Map<String, Timer> _timers = {};

  TypingIndicatorManager({this.timeout = const Duration(seconds: 3)});

  Stream<Map<String, TypingIndicator>> get typingStream =>
      _typingController.stream;
  Map<String, TypingIndicator> get currentTyping =>
      Map.unmodifiable(_typingMap);

  void setTyping(TypingIndicator indicator) {
    final key = indicator.channelId != null
        ? '${indicator.channelId}:${indicator.userId}'
        : indicator.userId;

    _typingMap[key] = indicator;
    _typingController.add(Map.from(_typingMap));

    // Auto-clear after timeout
    _timers[key]?.cancel();
    _timers[key] = Timer(timeout, () {
      _typingMap.remove(key);
      _timers.remove(key);
      _typingController.add(Map.from(_typingMap));
    });
  }

  void clearTyping(String userId, {String? channelId}) {
    final key = channelId != null ? '$channelId:$userId' : userId;
    _timers[key]?.cancel();
    _timers.remove(key);
    _typingMap.remove(key);
    _typingController.add(Map.from(_typingMap));
  }

  List<String> getTypingUsers({String? channelId}) {
    return _typingMap.entries
        .where((e) => channelId == null || e.value.channelId == channelId)
        .map((e) => e.value.userId)
        .toList();
  }

  void dispose() {
    for (var timer in _timers.values) {
      timer.cancel();
    }
    _typingController.close();
  }
}

/// Read receipt tracking
class ReadReceipt {
  final String userId;
  final String messageId;
  final DateTime readAt;

  ReadReceipt({
    required this.userId,
    required this.messageId,
    required this.readAt,
  });

  factory ReadReceipt.fromJson(Map<String, dynamic> json) {
    return ReadReceipt(
      userId: json['userId'] as String,
      messageId: json['messageId'] as String,
      readAt: DateTime.parse(json['readAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'messageId': messageId,
        'readAt': readAt.toIso8601String(),
      };
}

/// Manages read receipts
class ReadReceiptManager {
  final _receiptsController =
      BehaviorSubject<Map<String, List<ReadReceipt>>>.seeded({});
  final Map<String, List<ReadReceipt>> _receiptsMap = {};

  Stream<Map<String, List<ReadReceipt>>> get receiptsStream =>
      _receiptsController.stream;

  void addReceipt(ReadReceipt receipt) {
    _receiptsMap.putIfAbsent(receipt.messageId, () => []).add(receipt);
    _receiptsController.add(Map.from(_receiptsMap));
  }

  void addReceiptFromJson(Map<String, dynamic> json) {
    final receipt = ReadReceipt.fromJson(json);
    addReceipt(receipt);
  }

  List<ReadReceipt> getReceipts(String messageId) {
    return _receiptsMap[messageId] ?? [];
  }

  bool hasUserRead(String messageId, String userId) {
    final receipts = _receiptsMap[messageId];
    return receipts?.any((r) => r.userId == userId) ?? false;
  }

  void dispose() {
    _receiptsController.close();
  }
}
