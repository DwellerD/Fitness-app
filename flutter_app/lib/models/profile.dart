class Profile {
  final String userId;
  final String? sex;
  final double? heightCm;
  final double? weightKg;
  final String? dob;
  final int? age;
  final String? activityLevel;
  final List<String> equipment;
  final List<String> scheduleDays;

  Profile({
    required this.userId,
    this.sex,
    this.heightCm,
    this.weightKg,
    this.dob,
    this.age,
    this.activityLevel,
    this.equipment = const [],
    this.scheduleDays = const [],
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      userId: map['user_id'] as String,
      sex: map['sex'] as String?,
      heightCm: map['height_cm'] != null ? (map['height_cm'] as num).toDouble() : null,
      weightKg: map['weight_kg'] != null ? (map['weight_kg'] as num).toDouble() : null,
      dob: map['dob'] as String?,
      age: map['age'] as int?,
      activityLevel: map['activity_level'] as String?,
      equipment: map['equipment'] != null 
          ? List<String>.from(map['equipment'] as List)
          : [],
      scheduleDays: map['schedule_days'] != null 
          ? List<String>.from(map['schedule_days'] as List)
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'sex': sex,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'dob': dob,
      'age': age,
      'activity_level': activityLevel,
      'equipment': equipment,
      'schedule_days': scheduleDays,
    };
  }

  Profile copyWith({
    String? userId,
    String? sex,
    double? heightCm,
    double? weightKg,
    String? dob,
    int? age,
    String? activityLevel,
    List<String>? equipment,
    List<String>? scheduleDays,
  }) {
    return Profile(
      userId: userId ?? this.userId,
      sex: sex ?? this.sex,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      dob: dob ?? this.dob,
      age: age ?? this.age,
      activityLevel: activityLevel ?? this.activityLevel,
      equipment: equipment ?? this.equipment,
      scheduleDays: scheduleDays ?? this.scheduleDays,
    );
  }
}
