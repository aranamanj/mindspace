import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/mood_entry.dart';
import '../models/journal_entry.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._internal();
  static Database? _database;

  DBHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mindspace.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE moods (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        mood_score  INTEGER NOT NULL,
        note        TEXT,
        created_at  TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE journals (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        title       TEXT NOT NULL,
        content     TEXT NOT NULL,
        created_at  TEXT NOT NULL,
        updated_at  TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ── Mood ──────────────────────────────────────────────────────────────────

  Future<int> insertMood(MoodEntry mood) async =>
      (await database).insert('moods', mood.toMap());

  Future<List<MoodEntry>> getMoods() async {
    final maps =
        await (await database).query('moods', orderBy: 'created_at DESC');
    return maps.map(MoodEntry.fromMap).toList();
  }

  Future<int> deleteMood(int id) async =>
      (await database).delete('moods', where: 'id = ?', whereArgs: [id]);

  // ── Journal ───────────────────────────────────────────────────────────────

  Future<int> insertJournal(JournalEntry entry) async =>
      (await database).insert('journals', entry.toMap());

  Future<List<JournalEntry>> getJournals() async {
    final maps =
        await (await database).query('journals', orderBy: 'created_at DESC');
    return maps.map(JournalEntry.fromMap).toList();
  }

  Future<int> updateJournal(JournalEntry entry) async =>
      (await database).update(
        'journals',
        entry.toMap(),
        where: 'id = ?',
        whereArgs: [entry.id],
      );

  Future<int> deleteJournal(int id) async =>
      (await database).delete('journals', where: 'id = ?', whereArgs: [id]);

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final rows = await (await database)
        .query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    await (await database).insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}