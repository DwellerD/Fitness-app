import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../providers/meal_scan_provider.dart';

// Provider for today's meals
final todaysMealsProvider = StreamProvider<List<MealData>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getTodaysMeals();
});

// Provider for today's nutrition totals
final todaysTotalsProvider = StreamProvider<Map<String, int>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getTodaysTotals();
});
