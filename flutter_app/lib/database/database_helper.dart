import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fitness.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        name TEXT,
        password_hash TEXT,
        created_at TEXT NOT NULL,
        prefs_json TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE profiles (
        user_id TEXT PRIMARY KEY,
        sex TEXT,
        height_cm REAL,
        weight_kg REAL,
        dob TEXT,
        age INTEGER,
        activity_level TEXT,
        equipment_json TEXT,
        schedule_days_json TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE meals (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        type TEXT NOT NULL,
        items_json TEXT NOT NULL,
        total_kcal REAL NOT NULL,
        macros_json TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_meals_user_ts ON meals(user_id, timestamp)
    ''');

    await db.execute('''
      CREATE TABLE goals (
        user_id TEXT PRIMARY KEY,
        primary_goal TEXT NOT NULL,
        target_weight_kg REAL,
        protein_target_g REAL,
        daily_kcal_target REAL,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_plans (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        start_date TEXT NOT NULL,
        weeks INTEGER NOT NULL,
        split_json TEXT NOT NULL,
        sessions_json TEXT NOT NULL,
        progression_rules_json TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pt_plans (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        area TEXT NOT NULL,
        phase TEXT NOT NULL,
        frequency_per_week INTEGER NOT NULL,
        exercises_json TEXT NOT NULL,
        pain_guardrails_json TEXT,
        reassess_after_days INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE avatar_chats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        avatar TEXT NOT NULL,
        role TEXT NOT NULL,
        text TEXT NOT NULL,
        ts TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
