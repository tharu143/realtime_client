import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'protocol.dart';

abstract class QueueStorage {
  Future<void> initialize();
  Future<void> enqueue(RealtimeMessage message);
  Future<void> remove(String idempotencyKey);
  Future<void> removeUpToSeq(int seq);
  Future<List<RealtimeMessage>> getAllPending();
  Future<int> count();
  Future<void> clear();
  Future<void> close();
}

class SqliteQueueStorage implements QueueStorage {
  Database? _db;
  final String _tableName = 'message_queue';

  @override
  Future<void> initialize() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'realtime_client_queue.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            idempotency_key TEXT UNIQUE NOT NULL,
            seq INTEGER,
            payload TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_seq ON $_tableName (seq)');
      },
    );
  }

  @override
  Future<void> enqueue(RealtimeMessage message) async {
    if (_db == null) await initialize();
    await _db!.insert(
      _tableName,
      {
        'idempotency_key': message.idempotencyKey,
        'seq': message.seq,
        'payload': jsonEncode(message.toJson()),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> remove(String idempotencyKey) async {
    if (_db == null) await initialize();
    await _db!.delete(
      _tableName,
      where: 'idempotency_key = ?',
      whereArgs: [idempotencyKey],
    );
  }

  @override
  Future<void> removeUpToSeq(int seq) async {
    if (_db == null) await initialize();
    await _db!.delete(
      _tableName,
      where: 'seq <= ?',
      whereArgs: [seq],
    );
  }

  @override
  Future<List<RealtimeMessage>> getAllPending() async {
    if (_db == null) await initialize();
    final List<Map<String, dynamic>> maps = await _db!.query(
      _tableName,
      orderBy: 'seq ASC, id ASC',
    );

    return List.generate(maps.length, (i) {
      final jsonStr = maps[i]['payload'] as String;
      return RealtimeMessage.fromJson(jsonDecode(jsonStr));
    });
  }

  @override
  Future<int> count() async {
    if (_db == null) await initialize();
    final result =
        await _db!.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<void> clear() async {
    if (_db == null) await initialize();
    await _db!.delete(_tableName);
  }

  @override
  Future<void> close() async {
    await _db?.close();
  }
}
