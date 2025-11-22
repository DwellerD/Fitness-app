import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class AvatarChatsRepository {
  Future<List<Map<String, dynamic>>> getThread(String userId, String avatarId) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      'avatar_chats',
      where: 'user_id = ? AND avatar_id = ?',
      whereArgs: [userId, avatarId],
      orderBy: 'timestamp ASC',
    );
    return results;
  }

  Future<void> addMessage({
    required String userId,
    required String avatarId,
    required String role,
    required String content,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final messageId = 'msg-${DateTime.now().millisecondsSinceEpoch}';
    
    final data = {
      'id': messageId,
      'user_id': userId,
      'avatar_id': avatarId,
      'role': role,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await db.insert(
      'avatar_chats',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearThread(String userId, String avatarId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'avatar_chats',
      where: 'user_id = ? AND avatar_id = ?',
      whereArgs: [userId, avatarId],
    );
  }
}
