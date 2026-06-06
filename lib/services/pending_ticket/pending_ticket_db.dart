import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'pending_ticket.dart';

/// SQLite-backed outbox for ticket submissions that failed to reach the server.
class PendingTicketDb {
  static const String _table = 'pending_tickets';
  static Database? _db;

  static Future<Database> _database() async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'pending_tickets.db');
    _db = await openDatabase(
      path,
      version: 2, // ← bumped from 1 to 2
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            deviceId INTEGER NOT NULL,
            plate TEXT NOT NULL,
            ticketNumber TEXT NOT NULL UNIQUE,
            base64Image TEXT,
            needsInsert INTEGER NOT NULL,
            needsImage INTEGER NOT NULL,
            attempts INTEGER NOT NULL DEFAULT 0,
            lastError TEXT,
            createdAt TEXT NOT NULL,
            entrySyncTime TEXT NOT NULL DEFAULT ''
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add entrySyncTime column to existing installs.
          // DEFAULT '' so old queued rows get an empty string (handled in retry).
          await db.execute(
            "ALTER TABLE $_table ADD COLUMN entrySyncTime TEXT NOT NULL DEFAULT ''",
          );
        }
      },
    );
    return _db!;
  }

  /// Adds (or replaces, keyed by ticketNumber) a pending ticket.
  static Future<void> enqueue(PendingTicket ticket) async {
    final db = await _database();
    await db.insert(
      _table,
      ticket.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<PendingTicket>> getAll() async {
    final db = await _database();
    final rows = await db.query(_table, orderBy: 'id ASC');
    return rows.map(PendingTicket.fromMap).toList();
  }

  static Future<int> count() async {
    final db = await _database();
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM $_table');
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  static Future<void> update(PendingTicket ticket) async {
    if (ticket.id == null) return;
    final db = await _database();
    await db.update(
      _table,
      ticket.toMap(),
      where: 'id = ?',
      whereArgs: [ticket.id],
    );
  }

  static Future<void> delete(int id) async {
    final db = await _database();
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}