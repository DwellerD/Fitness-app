import 'dart:convert';
import '../models/user.dart';
import 'database_helper.dart';

class UsersRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<User?> getUser(String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return User.fromMap({
      ...map,
      'prefs': map['prefs_json'] != null 
          ? jsonDecode(map['prefs_json'] as String)
          : {},
    });
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'LOWER(email) = LOWER(?)',
      whereArgs: [email],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return User.fromMap({
      ...map,
      'prefs': map['prefs_json'] != null 
          ? jsonDecode(map['prefs_json'] as String)
          : {},
    });
  }

  Future<User> createUser({
    required String id,
    required String email,
    String? name,
    String? passwordHash,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    
    await db.insert('users', {
      'id': id,
      'email': email,
      'name': name,
      'password_hash': passwordHash,
      'created_at': now,
      'prefs_json': jsonEncode({}),
    });

    return User(
      id: id,
      email: email,
      name: name,
      createdAt: now,
      prefs: {},
      passwordHash: passwordHash,
    );
  }

  Future<Map<String, dynamic>> getPrefs(String userId) async {
    final user = await getUser(userId);
    return user?.prefs ?? {};
  }

  Future<void> updatePrefs(String userId, Map<String, dynamic> merge) async {
    final db = await _dbHelper.database;
    final current = await getPrefs(userId);
    final next = {...current, ...merge};
    
    await db.update(
      'users',
      {'prefs_json': jsonEncode(next)},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
