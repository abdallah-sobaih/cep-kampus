import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/chat_session.dart';


/// All database I/O is isolated here.
/// Providers depend on this class, never on [DatabaseHelper] directly.
class ChatRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<Database> get _db async => _helper.database;

  // ---------------------------------------------------------------------------
  // Sessions
  // ---------------------------------------------------------------------------

  /// Returns all sessions ordered by most recently updated first.
  Future<List<ChatSession>> getAllSessions() async {
    final db = await _db;
    final rows = await db.query('sessions', orderBy: 'updated_at DESC');
    return rows.map(ChatSession.fromMap).toList();
  }

  Future<void> insertSession(ChatSession session) async {
    final db = await _db;
    await db.insert(
      'sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSessionTitle(String sessionId, String title) async {
    final db = await _db;
    await db.update(
      'sessions',
      {
        'title': title,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Bumps [updated_at] so the session rises to the top of the sidebar
  /// after receiving a new message — mirrors ChatGPT's ordering behaviour.
  Future<void> touchSession(String sessionId) async {
    final db = await _db;
    await db.update(
      'sessions',
      {'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Deletes the session row. All associated messages are removed
  /// automatically via the ON DELETE CASCADE foreign key constraint.
  Future<void> deleteSession(String sessionId) async {
    final db = await _db;
    await db.delete('sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  // ---------------------------------------------------------------------------
  // Messages
  // ---------------------------------------------------------------------------

  Future<List<ChatMessage>> getMessagesForSession(String sessionId) async {
    final db = await _db;
    final rows = await db.query(
      'messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
    return rows.map(ChatMessage.fromMap).toList();
  }

  Future<void> insertMessage(ChatMessage message) async {
    final db = await _db;
    await db.insert(
      'messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}