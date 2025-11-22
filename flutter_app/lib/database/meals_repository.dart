import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'database_helper.dart';

class MealsRepository {
  Future<List<Map<String, dynamic>>> getMealsForDate(String userId, String date) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      'meals',
      where: 'user_id = ? AND date(timestamp) = ?',
      whereArgs: [userId, date],
      orderBy: 'timestamp DESC',
    );
    return results;
  }

  Future<Map<String, double>> getDailyTotals(String userId, String date) async {
    final meals = await getMealsForDate(userId, date);
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final meal in meals) {
      totalCalories += (meal['total_calories'] as num?)?.toDouble() ?? 0;
      totalProtein += (meal['total_protein'] as num?)?.toDouble() ?? 0;
      totalCarbs += (meal['total_carbs'] as num?)?.toDouble() ?? 0;
      totalFat += (meal['total_fat'] as num?)?.toDouble() ?? 0;
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }

  Future<void> upsertMeal({
    String? id,
    required String userId,
    required String timestamp,
    String? photoUri,
    List<Map<String, dynamic>>? items,
    double? totalCalories,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final mealId = id ?? 'meal-${DateTime.now().millisecondsSinceEpoch}';
    
    final data = {
      'id': mealId,
      'user_id': userId,
      'timestamp': timestamp,
      'photo_uri': photoUri,
      'items_json': items != null ? jsonEncode(items) : null,
      'total_calories': totalCalories,
      'total_protein': totalProtein,
      'total_carbs': totalCarbs,
      'total_fat': totalFat,
    };

    await db.insert(
      'meals',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteMeal(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'meals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
