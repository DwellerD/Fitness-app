import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/meal_scan_provider.dart';
import '../models/user_profile.dart';
import '../models/plan.dart';
import '../models/workout.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;
  String? get currentUserId => _userId;

  // Meals --------------------------------------------------------

  Future<void> saveMeal(MealData meal) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not logged in');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .add({
      'name': meal.name,
      'description': meal.description,
      'calories': meal.calories,
      'protein': meal.protein,
      'carbs': meal.carbs,
      'fat': meal.fat,
      'timestamp': FieldValue.serverTimestamp(),
      'date': DateTime.now().toIso8601String().split('T')[0],
    });
  }

  Stream<List<MealData>> getTodaysMeals() {
    final userId = _userId;
    if (userId == null) return Stream.value([]);

    final today = DateTime.now().toIso8601String().split('T')[0];

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .where('date', isEqualTo: today)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return MealData(
          name: data['name'],
          description: data['description'],
          calories: data['calories'],
          protein: data['protein'],
          carbs: data['carbs'],
          fat: data['fat'],
        );
      }).toList();
    });
  }

  Stream<Map<String, int>> getTodaysTotals() {
    return getTodaysMeals().map((meals) {
      int totalCalories = 0;
      int totalProtein = 0;
      int totalCarbs = 0;
      int totalFat = 0;

      for (final meal in meals) {
        totalCalories += meal.calories;
        totalProtein += meal.protein;
        totalCarbs += meal.carbs;
        totalFat += meal.fat;
      }

      return {
        'calories': totalCalories,
        'protein': totalProtein,
        'carbs': totalCarbs,
        'fat': totalFat,
      };
    });
  }

  // User profile -------------------------------------------------

  Stream<UserProfile?> getUserProfile() {
    final userId = _userId;
    if (userId == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return UserProfile.fromJson({...snapshot.data()!, 'userId': userId});
    });
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not logged in');

    await _firestore
        .collection('users')
        .doc(userId)
        .set(profile.toJson(), SetOptions(merge: true));
  }

  // Plans --------------------------------------------------------

  Future<void> savePlan(Plan plan) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not logged in');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('plans')
        .doc(plan.id)
        .set(plan.toJson());
  }

  Future<void> deletePlan(String planId) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not logged in');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('plans')
        .doc(planId)
        .delete();
  }

  // NEW: delete all plans of a given PlanType for this user
  Future<void> deletePlansByType(PlanType type) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not logged in');

    final plansSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('plans')
        .where('type', isEqualTo: type.toString())
        .get();

    for (final doc in plansSnap.docs) {
      await doc.reference.delete();
    }
  }

  Stream<List<Plan>> getUserPlans() {
    final userId = _userId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('plans')
        // TEMP: drop the where() to avoid composite index requirement
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Plan.fromJson(doc.data()))
          .toList();
    });
  }

  Future<void> updatePlanProgress(String planId, double progress) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not logged in');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('plans')
        .doc(planId)
        .update({
      'progress': progress,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> completePlanDay(String planId, int dayNumber) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not logged in');

    final planRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('plans')
        .doc(planId);

    final planDoc = await planRef.get();
    if (!planDoc.exists) return;

    final plan = Plan.fromJson(planDoc.data()!);

    final updatedDays = plan.days.map((day) {
      if (day.dayNumber == dayNumber) {
        return PlanDay(
          dayNumber: day.dayNumber,
          title: day.title,
          notes: day.notes,
          items: day.items,
          completed: true,
        );
      }
      return day;
    }).toList();

    final totalDays = updatedDays.length;
    final completedDays = updatedDays.where((d) => d.completed).length;
    final newProgress = totalDays == 0 ? 0.0 : completedDays / totalDays;

    await planRef.update({
      'days': updatedDays.map((d) => d.toJson()).toList(),
      'progress': newProgress,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Replace all days of a plan (used when AI regenerates a plan)
  Future<void> replacePlanDays(String planId, List<PlanDay> newDays) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not logged in');

    final planRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('plans')
        .doc(planId);

    final totalDays = newDays.length;
    final completedDays = newDays.where((d) => d.completed).length;
    final newProgress = totalDays == 0 ? 0.0 : completedDays / totalDays;

    await planRef.update({
      'days': newDays.map((d) => d.toJson()).toList(),
      'progress': newProgress,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Update notes/items for a single day in a plan
  Future<void> updatePlanDay(
    String planId,
    int dayNumber, {
    String? title,
    String? notes,
    List<PlanItem>? items,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not logged in');

    final planRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('plans')
        .doc(planId);

    final planDoc = await planRef.get();
    if (!planDoc.exists) return;

    final plan = Plan.fromJson(planDoc.data()!);

    final updatedDays = plan.days.map((day) {
      if (day.dayNumber == dayNumber) {
        return PlanDay(
          dayNumber: day.dayNumber,
          title: title ?? day.title,
          notes: notes ?? day.notes,
          items: items ?? day.items,
          completed: day.completed,
        );
      }
      return day;
    }).toList();

    await planRef.update({
      'days': updatedDays.map((d) => d.toJson()).toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Workouts --------------------------------------------------------

  Future<void> saveWorkout(Workout workout) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not logged in');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workout.id)
        .set(workout.toJson());
  }

  Stream<List<Workout>> getRecentWorkouts({int limit = 20}) {
    final userId = _userId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Workout.fromJson(doc.data()))
          .toList();
    });
  }

  // Data export / deletion ---------------------------------------

  Future<void> deleteAllUserData() async {
    final userId = _userId;
    if (userId == null) throw Exception('User not logged in');

    final mealsSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .get();
    for (final doc in mealsSnap.docs) {
      await doc.reference.delete();
    }

    final plansSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('plans')
        .get();
    for (final doc in plansSnap.docs) {
      await doc.reference.delete();
    }

    final workoutsSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .get();
    for (final doc in workoutsSnap.docs) {
      await doc.reference.delete();
    }

    await _firestore.collection('users').doc(userId).delete();
  }

  Future<Map<String, dynamic>> exportUserData() async {
    final userId = _userId;
    if (userId == null) throw Exception('User not logged in');

    final profileDoc =
        await _firestore.collection('users').doc(userId).get();
    final profile = profileDoc.exists ? profileDoc.data() : {};

    final mealsSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .get();
    final meals = mealsSnap.docs.map((d) => d.data()).toList();

    final plansSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('plans')
        .get();
    final plans = plansSnap.docs.map((d) => d.data()).toList();

    final workoutsSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .get();
    final workouts = workoutsSnap.docs.map((d) => d.data()).toList();

    return {
      'profile': profile,
      'meals': meals,
      'plans': plans,
      'workouts': workouts,
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }
}
