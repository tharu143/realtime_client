import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_realtime_client/flutter_realtime_client.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('RealtimeMessage', () {
    test('serialization', () {
      final msg = RealtimeMessage.event(
        event: 'test',
        payload: {'foo': 'bar'},
        seq: 1,
        clientId: 'abc',
      );

      final json = msg.toJson();
      expect(json['type'], 'event');
      expect(json['event'], 'test');
      expect(json['seq'], 1);
      expect(json['payload']['foo'], 'bar');

      final decoded = RealtimeMessage.fromJson(json);
      expect(decoded.event, 'test');
      expect(decoded.seq, 1);
    });
  });

  group('QueueStorage', () {
    late SqliteQueueStorage storage;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      storage = SqliteQueueStorage();
      // We need to initialize it.
      // Note: getDatabasesPath in ffi might need setup or we use inMemoryDatabasePath
      // But SqliteQueueStorage uses getDatabasesPath internally.
      // For test we might need to override or mock.
      // However, sqflite_common_ffi supports it on desktop.
      await storage.initialize();
      await storage.clear();
    });

    tearDown(() async {
      await storage.close();
    });

    test('enqueue and retrieve', () async {
      final msg = RealtimeMessage.event(
        event: 'test',
        payload: {'a': 1},
        seq: 1,
      );

      await storage.enqueue(msg);
      expect(await storage.count(), 1);

      final pending = await storage.getAllPending();
      expect(pending.length, 1);
      expect(pending.first.event, 'test');
    });

    test('remove up to seq', () async {
      await storage
          .enqueue(RealtimeMessage.event(event: '1', payload: {}, seq: 1));
      await storage
          .enqueue(RealtimeMessage.event(event: '2', payload: {}, seq: 2));
      await storage
          .enqueue(RealtimeMessage.event(event: '3', payload: {}, seq: 3));

      expect(await storage.count(), 3);

      await storage.removeUpToSeq(2);
      expect(await storage.count(), 1);

      final pending = await storage.getAllPending();
      expect(pending.first.seq, 3);
    });
  });
}
