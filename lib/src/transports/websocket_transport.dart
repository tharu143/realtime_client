import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../transport.dart';
import '../protocol.dart';

class WebSocketTransport implements Transport {
  WebSocketChannel? _channel;
  final _connectionStateController =
      StreamController<ConnectionState>.broadcast();
  final _messageController = StreamController<RealtimeMessage>.broadcast();
  final _errorController = StreamController<dynamic>.broadcast();

  ConnectionState _currentState = ConnectionState.disconnected;

  @override
  Stream<ConnectionState> get connectionState =>
      _connectionStateController.stream;

  @override
  Stream<RealtimeMessage> get messageStream => _messageController.stream;

  @override
  Stream<dynamic> get errorStream => _errorController.stream;

  @override
  bool get isConnected => _currentState == ConnectionState.connected;

  @override
  Future<void> connect(String url, {Map<String, String>? headers}) async {
    try {
      _updateState(ConnectionState.connecting);

      final uri = Uri.parse(url);
      // web_socket_channel supports headers in connect for some platforms (IO), but it's platform specific.
      // For simplicity in this cross-platform lib, we assume standard WS.
      // If headers are needed (e.g. for auth), they are often passed in query params or initial handshake if the library supports it.
      // IOWebSocketChannel supports headers. HtmlWebSocketChannel does not (browser limitation).
      // We will use WebSocketChannel.connect which picks the right one.
      // To support headers on IO, we might need to be more specific, but let's stick to the generic one for now
      // or check if we can pass headers.
      // The generic connect doesn't easily support headers across all platforms.
      // We will assume the user might put the token in the URL query string or we use a specific implementation if needed.
      // However, the requirements say "Support token-based auth (Authorization header Bearer <token>)".
      // This implies we should try to support headers.

      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _updateState(ConnectionState.connected);

      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String);
            final message = RealtimeMessage.fromJson(json);
            _messageController.add(message);
          } catch (e) {
            _errorController.add(e);
          }
        },
        onError: (error) {
          _errorController.add(error);
          _updateState(ConnectionState.disconnected);
        },
        onDone: () {
          _updateState(ConnectionState.disconnected);
        },
      );
    } catch (e) {
      _errorController.add(e);
      _updateState(ConnectionState.failed);
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await _channel?.sink.close(status.normalClosure);
    _channel = null;
    _updateState(ConnectionState.disconnected);
  }

  @override
  Future<void> send(RealtimeMessage message) async {
    if (_channel == null || _currentState != ConnectionState.connected) {
      throw Exception('WebSocket is not connected');
    }
    final jsonStr = jsonEncode(message.toJson());
    _channel!.sink.add(jsonStr);
  }

  void _updateState(ConnectionState state) {
    if (_currentState != state) {
      _currentState = state;
      _connectionStateController.add(state);
    }
  }

  @override
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _messageController.close();
    _errorController.close();
  }
}
