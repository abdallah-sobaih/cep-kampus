import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton wrapper around the SQLite database.
/// All raw SQL is confined to this class and [ChatRepository].
/// No provider or widget ever imports sqflite directly.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  static const String _dbName = 'cep_kampus.db';
  static const int _dbVersion = 1;

  Future<Database> get database async {
    return _db ??= await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  /// Enable foreign key enforcement — SQLite disables them by default.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // Sessions table — one row per conversation.
    await db.execute('''
      CREATE TABLE sessions (
        id         TEXT    PRIMARY KEY,
        title      TEXT    NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Messages table — foreign key to sessions with CASCADE delete,
    // so deleting a session automatically deletes all its messages.
    await db.execute('''
      CREATE TABLE messages (
        id         TEXT    PRIMARY KEY,
        session_id TEXT    NOT NULL,
        role       TEXT    NOT NULL,
        content    TEXT    NOT NULL,
        sources    TEXT    NOT NULL DEFAULT '[]',
        timestamp  INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
      )
    ''');

    // Covering indexes for the two most frequent query patterns.
    await db.execute(
      'CREATE INDEX idx_sessions_updated ON sessions(updated_at DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_messages_session ON messages(session_id, timestamp ASC)',
    );
  }
}