import 'dart:async';
import 'package:flutter/material.dart';
import 'package:realtime_client/realtime_client.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Realtime Client Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late RealtimeClient _client;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<RealtimeMessage> _messages = [];

  String _serverUrl = 'http://localhost:3000'; // Default to Socket.IO

  // Stats
  int _pendingCount = 0;
  ConnectionState _connectionState = ConnectionState.disconnected;
  RealtimeMetrics _metrics = const RealtimeMetrics();

  // Presence
  Map<String, PresenceInfo> _presence = {};

  // Typing
  Map<String, TypingIndicator> _typing = {};
  Timer? _typingTimer;

  // Read receipts
  Map<String, List<ReadReceipt>> _receipts = {};

  // Subscriptions
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _initClient();
  }

  Future<void> _initClient() async {
    final config = RealtimeConfig(
      url: _serverUrl,
      deliveryStrategy: DeliveryStrategy.atLeastOnce,
      logLevel: Level.debug,
    );

    _client = RealtimeClient(
      config: config,
      queueStorage: SqliteQueueStorage(),
      clientId: 'demo-user-flutter',
    );

    // Connection state
    _subscriptions.add(_client.connectionState.listen((state) {
      setState(() {
        _connectionState = state;
      });
    }));

    // Messages
    _subscriptions.add(_client.onMessage.listen((msg) {
      if (msg.type == MessageType.event && msg.event == 'chat.message') {
        setState(() {
          _messages.add(msg);
        });
        _scrollToBottom();
      }
    }));

    // ACKs
    _subscriptions.add(_client.onAck.listen((msg) {
      _refreshPendingCount();
    }));

    // Metrics
    _subscriptions.add(_client.metricsStream.listen((metrics) {
      setState(() {
        _metrics = metrics;
      });
    }));

    // Presence
    _subscriptions
        .add(_client.presenceManager.presenceStream.listen((presence) {
      setState(() {
        _presence = presence;
      });
    }));

    // Typing
    _subscriptions.add(_client.typingManager.typingStream.listen((typing) {
      setState(() {
        _typing = typing;
      });
    }));

    // Read receipts
    _subscriptions
        .add(_client.readReceiptManager.receiptsStream.listen((receipts) {
      setState(() {
        _receipts = receipts;
      });
    }));

    // Initial connect
    await _client.connect();

    // Set presence to online
    await _client.updatePresence(PresenceStatus.online, metadata: {
      'device': 'Flutter Demo',
    });

    _refreshPendingCount();
  }

  Future<void> _refreshPendingCount() async {
    final count = await _client.pendingCount;
    setState(() {
      _pendingCount = count;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_textController.text.isEmpty) return;

    final text = _textController.text;
    _textController.clear();

    final payload = {
      'text': text,
      'sender': _client.clientId,
    };

    // Optimistic update
    final msg = RealtimeMessage.event(
      event: 'chat.message',
      payload: payload,
      clientId: _client.clientId,
    );

    setState(() {
      _messages.add(msg);
    });
    _scrollToBottom();

    await _client.sendEvent('chat.message', payload);
    _refreshPendingCount();

    // Stop typing
    _stopTyping();
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty) {
      // Send typing indicator
      _client.sendTypingIndicator(isTyping: true);

      // Reset timer
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), _stopTyping);
    }
  }

  void _stopTyping() {
    _client.sendTypingIndicator(isTyping: false);
    _typingTimer?.cancel();
  }

  @override
  void dispose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _client.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Realtime Chat'),
            Text(
              '${_connectionState.name} | Queue: $_pendingCount',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showMetrics,
          ),
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: _showPresence,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
          IconButton(
            icon: Icon(_connectionState == ConnectionState.connected
                ? Icons.cloud_off
                : Icons.cloud_queue),
            onPressed: () {
              if (_connectionState == ConnectionState.connected) {
                _client.disconnect();
              } else {
                _client.connect();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Typing indicator
          if (_typing.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_typing.values.map((t) => t.userId).join(', ')} typing...',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ],
              ),
            ),

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg.clientId == _client.clientId;
                final payload = msg.payload ?? {};
                final text = payload['text'] ?? 'Unknown message';
                final time = DateTime.tryParse(msg.timestamp)?.toLocal() ??
                    DateTime.now();

                // Get read receipts for this message
                final receipts = msg.idempotencyKey != null
                    ? _receipts[msg.idempotencyKey!] ?? []
                    : <ReadReceipt>[];

                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: GestureDetector(
                    onLongPress: () {
                      if (!isMe && msg.idempotencyKey != null) {
                        _client.sendReadReceipt(msg.idempotencyKey!);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(text, style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormat('HH:mm:ss').format(time),
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey[600]),
                              ),
                              if (isMe && msg.seq != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'Seq: ${msg.seq}',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey[600]),
                                ),
                              ],
                              if (receipts.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.done_all,
                                    size: 12, color: Colors.blue[700]),
                                Text(
                                  ' ${receipts.length}',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.blue[700]),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                    onChanged: _onTextChanged,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMetrics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Metrics'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _metricRow(
                  'Total Reconnects', _metrics.totalReconnects.toString()),
              _metricRow(
                  'Messages Sent', _metrics.totalMessagesSent.toString()),
              _metricRow('Messages Received',
                  _metrics.totalMessagesReceived.toString()),
              _metricRow(
                  'Messages Acked', _metrics.totalMessagesAcked.toString()),
              _metricRow('Queue Size', _metrics.currentQueueSize.toString()),
              _metricRow(
                  'Failed Sends', _metrics.failedSendAttempts.toString()),
              _metricRow('Successful Sends',
                  _metrics.successfulSendAttempts.toString()),
              if (_metrics.averageReconnectTime != null)
                _metricRow('Avg Reconnect Time',
                    '${_metrics.averageReconnectTime!.inMilliseconds}ms'),
              if (_metrics.lastConnectedAt != null)
                _metricRow('Last Connected',
                    DateFormat('HH:mm:ss').format(_metrics.lastConnectedAt!)),
              if (_metrics.lastError != null)
                _metricRow('Last Error', _metrics.lastError!, isError: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: TextStyle(color: isError ? Colors.red : null),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showPresence() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Presence'),
        content: _presence.isEmpty
            ? const Text('No users online')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: _presence.entries.map((e) {
                  final info = e.value;
                  return ListTile(
                    leading: Icon(
                      Icons.circle,
                      color: info.status == PresenceStatus.online
                          ? Colors.green
                          : Colors.grey,
                      size: 12,
                    ),
                    title: Text(info.userId),
                    subtitle: Text(info.status.name),
                    trailing: Text(
                      DateFormat('HH:mm').format(info.lastSeen),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }).toList(),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Server URL'),
              controller: TextEditingController(text: _serverUrl),
              onChanged: (val) => _serverUrl = val,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _client.clearPending();
                _refreshPendingCount();
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Clear Pending Queue'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                // Re-init client with new URL
                for (var sub in _subscriptions) {
                  await sub.cancel();
                }
                _subscriptions.clear();
                await _client.dispose();
                _messages.clear();
                _initClient();
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Apply & Reconnect'),
            ),
          ],
        ),
      ),
    );
  }
}
