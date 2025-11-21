import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../transport.dart';
import '../protocol.dart';

class SocketIOTransport implements Transport {
  io.Socket? _socket;
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

      // Map options
      // We can pass headers in 'extraHeaders' or 'auth' depending on server setup.
      // Usually 'extraHeaders' for handshake.
      final options = io.OptionBuilder()
          .setTransports([
            'websocket'
          ]) // Force websocket to avoid polling if desired, or let it auto
          .setExtraHeaders(headers ?? {})
          .disableAutoConnect() // We want to call connect manually
          .build();

      _socket = io.io(url, options);

      _socket!.onConnect((_) {
        _updateState(ConnectionState.connected);
      });

      _socket!.onDisconnect((_) {
        _updateState(ConnectionState.disconnected);
      });

      _socket!.onConnectError((data) {
        _errorController.add(data);
        _updateState(ConnectionState.failed);
      });

      // Listen for the unified 'message' event
      _socket!.on('message', (data) {
        try {
          // data should be a Map<String, dynamic> (JSON object)
          if (data is Map<String, dynamic>) {
            final message = RealtimeMessage.fromJson(data);
            _messageController.add(message);
          }
        } catch (e) {
          _errorController.add(e);
        }
      });

      _socket!.connect();
    } catch (e) {
      _errorController.add(e);
      _updateState(ConnectionState.failed);
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _updateState(ConnectionState.disconnected);
  }

  @override
  Future<void> send(RealtimeMessage message) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception('SocketIO is not connected');
    }
    // Send as a JSON object
    _socket!.emit('message', message.toJson());
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
