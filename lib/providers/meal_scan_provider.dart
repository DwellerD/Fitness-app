import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/meal_analysis_service.dart';
import '../services/firestore_service.dart';

class MealData {
  final String name;
  final String description;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  MealData({
    required this.name,
    required this.description,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class MealScanState {
  final bool isLoading;
  final MealData? mealData;
  final String? error;

  MealScanState({
    this.isLoading = false,
    this.mealData,
    this.error,
  });

  MealScanState copyWith({
    bool? isLoading,
    MealData? mealData,
    String? error,
  }) {
    return MealScanState(
      isLoading: isLoading ?? this.isLoading,
      mealData: mealData ?? this.mealData,
      error: error,
    );
  }
}

class MealScanNotifier extends StateNotifier<MealScanState> {
  final MealAnalysisService _service;
  final FirestoreService _firestoreService;

  MealScanNotifier(this._service, this._firestoreService) : super(MealScanState());

  Future<void> analyzeMeal(String imagePath) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final mealData = await _service.analyzeMealImage(imagePath);
      state = state.copyWith(isLoading: false, mealData: mealData);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to analyze meal. Please try again.',
      );
    }
  }

  Future<void> saveMeal() async {
    if (state.mealData != null) {
      await _firestoreService.saveMeal(state.mealData!);
      state = MealScanState();
    }
  }
}

final mealAnalysisServiceProvider = Provider((ref) => MealAnalysisService());
final firestoreServiceProvider = Provider((ref) => FirestoreService());

final mealScanProvider = StateNotifierProvider<MealScanNotifier, MealScanState>((ref) {
  return MealScanNotifier(
    ref.watch(mealAnalysisServiceProvider),
    ref.watch(firestoreServiceProvider),
  );
});
