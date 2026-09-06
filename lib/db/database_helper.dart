import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'learning_english.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE daily_facts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        english_text TEXT NOT NULL,
        spanish_translation TEXT NOT NULL,
        difficulty TEXT,
        publish_date TEXT,
        is_read INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE dictionary (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_en TEXT NOT NULL,
        word_es TEXT NOT NULL,
        part_of_speech TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE user_vocabulary (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL,
        translation TEXT NOT NULL,
        next_review_date TEXT,
        interval INTEGER,
        ease_factor REAL
      )
    ''');
  }

  Future<void> closeDB() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<int> insertFact(Fact fact) async {
    final db = await database;
    return await db.insert('daily_facts', fact.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Fact>> getAllFacts() async {
    final db = await database;
    final result = await db.query('daily_facts');
    return result.map((map) => Fact.fromMap(map)).toList();
  }

  Future<List<Fact>> getUnreadFacts() async {
    final db = await database;
    final result = await db.query(
      'daily_facts',
      where: 'is_read = ?',
      whereArgs: [0],
    );
    return result.map((map) => Fact.fromMap(map)).toList();
  }

  Future<void> markFactAsRead(int id) async {
    final db = await database;
    await db.update(
      'daily_facts',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getDictionary() async {
    final db = await database;
    return await db.query('dictionary');
  }

  Future<Map<String, dynamic>?> lookupWord(String word) async {
    final db = await database;
    final cleanedWord = word.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
    final result = await db.query(
      'dictionary',
      where: 'LOWER(word_en) = ?',
      whereArgs: [cleanedWord],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<int> insertDictionaryEntry(Map<String, dynamic> entry) async {
    final db = await database;
    return await db.insert('dictionary', entry,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getUserVocabulary() async {
    final db = await database;
    return await db.query('user_vocabulary');
  }

  Future<int> insertUserVocabulary(Map<String, dynamic> entry) async {
    final db = await database;
    return await db.insert('user_vocabulary', entry,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateUserVocabulary(Map<String, dynamic> entry) async {
    final db = await database;
    await db.update(
      'user_vocabulary',
      entry,
      where: 'id = ?',
      whereArgs: [entry['id']],
    );
  }

  Future<void> deleteUserVocabulary(int id) async {
    final db = await database;
    await db.delete(
      'user_vocabulary',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
