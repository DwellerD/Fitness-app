import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plan.dart';
import '../services/firestore_service.dart';
import 'meal_scan_provider.dart';

final userPlansProvider = StreamProvider<List<Plan>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getUserPlans();
});
