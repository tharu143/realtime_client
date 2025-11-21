import 'dart:async';
import 'protocol.dart';

enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

abstract class Transport {
  Stream<ConnectionState> get connectionState;
  Stream<RealtimeMessage> get messageStream;
  Stream<dynamic> get errorStream;

  Future<void> connect(String url, {Map<String, String>? headers});
  Future<void> disconnect();
  Future<void> send(RealtimeMessage message);
  bool get isConnected;
  void dispose();
}
