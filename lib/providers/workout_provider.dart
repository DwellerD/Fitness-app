import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/workout.dart';
import '../services/firestore_service.dart';
import 'meal_scan_provider.dart';

final recentWorkoutsProvider = StreamProvider<List<Workout>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getRecentWorkouts(limit: 20);
});

final workoutLoggerProvider = Provider<WorkoutLogger>((ref) {
  return WorkoutLogger(ref);
});

class WorkoutLogger {
  final Ref _ref;
  WorkoutLogger(this._ref);

  Future<void> logSimpleWorkout({
    required String name,
    required int durationMinutes,
  }) async {
    final firestore = _ref.read(firestoreServiceProvider);
    final userId = firestore.currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final workout = Workout(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      date: DateTime.now(),
      durationMinutes: durationMinutes,
      exercises: const [],
    );

    await firestore.saveWorkout(workout);
  }
}
