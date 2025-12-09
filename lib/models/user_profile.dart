class UserProfile {
  final String userId;
  final String? name;
  final int? age;
  final String? gender;
  final double? height; // in cm
  final double? weight; // in kg
  final String? activityLevel;
  final List<String> dietaryRestrictions;
  final List<String> injuries;
  final int calorieGoal;
  final int proteinGoal;
  final int carbsGoal;
  final int fatGoal;
  final bool useMetric;
  final String? goals; // <-- new: free-form "Your goals / notes"
  // NEW: overall diet style preference (e.g. keto, paleo, etc.)
  final String? dietPreference;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.userId,
    this.name,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.activityLevel,
    this.dietaryRestrictions = const [],
    this.injuries = const [],
    this.calorieGoal = 2300,
    this.proteinGoal = 170,
    this.carbsGoal = 250,
    this.fatGoal = 70,
    this.useMetric = true,
    this.goals,
    this.dietPreference, // <-- new
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        'age': age,
        'gender': gender,
        'height': height,
        'weight': weight,
        'activityLevel': activityLevel,
        'dietaryRestrictions': dietaryRestrictions,
        'injuries': injuries,
        'calorieGoal': calorieGoal,
        'proteinGoal': proteinGoal,
        'carbsGoal': carbsGoal,
        'fatGoal': fatGoal,
        'useMetric': useMetric,
        'goals': goals,
        'dietPreference': dietPreference, // <-- new
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        userId: json['userId'],
        name: json['name'],
        age: json['age'],
        gender: json['gender'],
        height: json['height']?.toDouble(),
        weight: json['weight']?.toDouble(),
        activityLevel: json['activityLevel'],
        dietaryRestrictions: List<String>.from(json['dietaryRestrictions'] ?? []),
        injuries: List<String>.from(json['injuries'] ?? []),
        calorieGoal: json['calorieGoal'] ?? 2300,
        proteinGoal: json['proteinGoal'] ?? 170,
        carbsGoal: json['carbsGoal'] ?? 250,
        fatGoal: json['fatGoal'] ?? 70,
        useMetric: json['useMetric'] ?? true,
        goals: json['goals'], // <-- restore goals if present
        dietPreference: json['dietPreference'], // <-- new
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );

  UserProfile copyWith({
    String? name,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? activityLevel,
    List<String>? dietaryRestrictions,
    List<String>? injuries,
    int? calorieGoal,
    int? proteinGoal,
    int? carbsGoal,
    int? fatGoal,
    bool? useMetric,
    String? goals,
    String? dietPreference,
  }) =>
      UserProfile(
        userId: userId,
        name: name ?? this.name,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        height: height ?? this.height,
        weight: weight ?? this.weight,
        activityLevel: activityLevel ?? this.activityLevel,
        dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
        injuries: injuries ?? this.injuries,
        calorieGoal: calorieGoal ?? this.calorieGoal,
        proteinGoal: proteinGoal ?? this.proteinGoal,
        carbsGoal: carbsGoal ?? this.carbsGoal,
        fatGoal: fatGoal ?? this.fatGoal,
        useMetric: useMetric ?? this.useMetric,
        goals: goals ?? this.goals,
        dietPreference: dietPreference ?? this.dietPreference, // <-- new
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
