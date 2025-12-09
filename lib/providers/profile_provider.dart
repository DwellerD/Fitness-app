import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import 'meal_scan_provider.dart';

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getUserProfile();
});
