class Workout {
  final String id;
  final String userId;
  final String? planId; // optional: link to a plan in future
  final String name;    // e.g. "Push Day", "Legs", etc.
  final DateTime date;
  final int durationMinutes;
  final List<WorkoutExercise> exercises;

  Workout({
    required this.id,
    required this.userId,
    required this.name,
    required this.date,
    required this.durationMinutes,
    this.planId,
    this.exercises = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'planId': planId,
        'name': name,
        'date': date.toIso8601String(),
        'durationMinutes': durationMinutes,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
        id: json['id'],
        userId: json['userId'],
        planId: json['planId'],
        name: json['name'],
        date: DateTime.parse(json['date']),
        durationMinutes: json['durationMinutes'] ?? 0,
        exercises: (json['exercises'] as List? ?? [])
            .map((e) => WorkoutExercise.fromJson(e))
            .toList(),
      );
}

class WorkoutExercise {
  final String name;
  final String? muscleGroup; // optional future use
  final List<WorkoutSet> sets;

  WorkoutExercise({
    required this.name,
    this.muscleGroup,
    this.sets = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'muscleGroup': muscleGroup,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      WorkoutExercise(
        name: json['name'],
        muscleGroup: json['muscleGroup'],
        sets: (json['sets'] as List? ?? [])
            .map((s) => WorkoutSet.fromJson(s))
            .toList(),
      );
}

class WorkoutSet {
  final int setNumber;
  final int reps;
  final double weight; // in kg or lb, based on user preference
  final bool completed;

  WorkoutSet({
    required this.setNumber,
    required this.reps,
    required this.weight,
    this.completed = true,
  });

  Map<String, dynamic> toJson() => {
        'setNumber': setNumber,
        'reps': reps,
        'weight': weight,
        'completed': completed,
      };

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
        setNumber: json['setNumber'] ?? 1,
        reps: json['reps'] ?? 0,
        weight: (json['weight'] ?? 0).toDouble(),
        completed: json['completed'] ?? true,
      );
}
