import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/profile.dart';
import 'database_helper.dart';

class ProfilesRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Profile?> getProfile(String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'profiles',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return Profile.fromMap({
      ...map,
      'equipment': map['equipment_json'] != null 
          ? jsonDecode(map['equipment_json'] as String)
          : [],
      'schedule_days': map['schedule_days_json'] != null 
          ? jsonDecode(map['schedule_days_json'] as String)
          : [],
    });
  }

  Future<void> upsertProfile(Profile profile) async {
    final db = await _dbHelper.database;
    
    await db.insert(
      'profiles',
      {
        'user_id': profile.userId,
        'sex': profile.sex,
        'height_cm': profile.heightCm,
        'weight_kg': profile.weightKg,
        'dob': profile.dob,
        'age': profile.age,
        'activity_level': profile.activityLevel,
        'equipment_json': jsonEncode(profile.equipment),
        'schedule_days_json': jsonEncode(profile.scheduleDays),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
