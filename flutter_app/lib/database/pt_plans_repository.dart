import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'database_helper.dart';

class PTPlansRepository {
  Future<Map<String, dynamic>?> getLatestPTPlan(String userId) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      'pt_plans',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return results.first;
  }

  Future<void> upsertPTPlan({
    String? id,
    required String userId,
    required Map<String, dynamic> plan,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final planId = id ?? 'pt-plan-${DateTime.now().millisecondsSinceEpoch}';
    
    final data = {
      'id': planId,
      'user_id': userId,
      'plan_json': jsonEncode(plan),
      'created_at': DateTime.now().toIso8601String(),
    };

    await db.insert(
      'pt_plans',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
