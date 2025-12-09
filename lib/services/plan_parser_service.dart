import 'dart:convert';
import '../models/plan.dart';

class PlanParserService {
  /// Tries to extract JSON plan from AI response
  /// Returns null if no JSON found or parsing fails
  Map<String, dynamic>? extractPlanJson(String aiResponse) {
    try {
      // Look for JSON in the response (between { and })
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(aiResponse);
      if (jsonMatch == null) return null;

      final jsonString = jsonMatch.group(0)!;
      final parsed = jsonDecode(jsonString);

      // Validate it has required fields
      if (parsed['planName'] != null && parsed['days'] != null) {
        return parsed;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Converts parsed JSON into Plan model
  Plan createPlanFromJson(
    Map<String, dynamic> json,
    String userId,
    String planId,
    String coachType,
    int durationWeeks,
  ) {
    final planName = json['planName'] as String;
    final description = json['description'] as String? ?? '';
    final daysJson = json['days'] as List;

    final days = daysJson.map((dayJson) {
      final itemsJson = dayJson['items'] as List? ?? [];
      final items = itemsJson.map((itemJson) {
        return PlanItem(
          description: itemJson['description'] as String,
          details: itemJson['details'] as String?,
        );
      }).toList();

      return PlanDay(
        dayNumber: dayJson['dayNumber'] as int,
        title: dayJson['title'] as String,
        notes: dayJson['notes'] as String?,
        items: items,
      );
    }).toList();

    return Plan(
      id: planId,
      userId: userId,
      name: planName,
      description: description,
      coachType: coachType,
      type: _getPlanType(coachType),
      goals: [],
      durationWeeks: durationWeeks,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: durationWeeks * 7)),
      days: days,
    );
  }

  PlanType _getPlanType(String coachType) {
    switch (coachType) {
      case 'fitness':
        return PlanType.workout;
      case 'nutrition':
        return PlanType.nutrition;
      case 'pt':
        return PlanType.recovery;
      case 'wellness':
        return PlanType.wellness;
      default:
        return PlanType.workout;
    }
  }
}
