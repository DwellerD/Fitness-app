import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class GoalsRepository {
  Future<Map<String, dynamic>?> getGoals(String userId) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      'goals',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return results.first;
  }

  Future<void> upsertGoals({
    required String userId,
    double? targetCalories,
    double? targetProtein,
    double? targetCarbs,
    double? targetFat,
  }) async {
    final db = await DatabaseHelper.instance.database;
    
    final data = {
      'user_id': userId,
      'target_calories': targetCalories,
      'target_protein': targetProtein,
      'target_carbs': targetCarbs,
      'target_fat': targetFat,
    };

    await db.insert(
      'goals',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
