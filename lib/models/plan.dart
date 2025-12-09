class Plan {
  final String id;
  final String userId;
  final String name;
  final String description;
  final String coachType; // 'fitness', 'nutrition', 'pt', 'wellness'
  final PlanType type;
  final List<String> goals;
  final int durationWeeks;
  final DateTime startDate;
  final DateTime? endDate;
  final PlanStatus status;
  final List<PlanDay> days;
  final double progress; // 0.0 to 1.0
  final DateTime createdAt;
  final DateTime updatedAt;

  Plan({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.coachType,
    required this.type,
    required this.goals,
    required this.durationWeeks,
    required this.startDate,
    this.endDate,
    this.status = PlanStatus.active,
    this.days = const [],
    this.progress = 0.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'description': description,
        'coachType': coachType,
        'type': type.toString(),
        'goals': goals,
        'durationWeeks': durationWeeks,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'status': status.toString(),
        'days': days.map((d) => d.toJson()).toList(),
        'progress': progress,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
        id: json['id'],
        userId: json['userId'],
        name: json['name'],
        description: json['description'],
        coachType: json['coachType'],
        type: PlanType.values.firstWhere((e) => e.toString() == json['type']),
        goals: List<String>.from(json['goals']),
        durationWeeks: json['durationWeeks'],
        startDate: DateTime.parse(json['startDate']),
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
        status: PlanStatus.values.firstWhere((e) => e.toString() == json['status']),
        days: (json['days'] as List).map((d) => PlanDay.fromJson(d)).toList(),
        progress: json['progress'] ?? 0.0,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );

  int get daysLeft {
    if (endDate == null) return durationWeeks * 7;
    return endDate!.difference(DateTime.now()).inDays;
  }
}

enum PlanType {
  workout,
  nutrition,
  recovery,
  wellness,
}

enum PlanStatus {
  active,
  paused,
  completed,
  archived,
}

class PlanDay {
  final int dayNumber;
  final String title;
  final String? notes;
  final List<PlanItem> items;
  final bool completed;

  PlanDay({
    required this.dayNumber,
    required this.title,
    this.notes,
    this.items = const [],
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
        'dayNumber': dayNumber,
        'title': title,
        'notes': notes,
        'items': items.map((i) => i.toJson()).toList(),
        'completed': completed,
      };

  factory PlanDay.fromJson(Map<String, dynamic> json) => PlanDay(
        dayNumber: json['dayNumber'],
        title: json['title'],
        notes: json['notes'],
        items: (json['items'] as List).map((i) => PlanItem.fromJson(i)).toList(),
        completed: json['completed'] ?? false,
      );
}

class PlanItem {
  final String description;
  final String? details; // e.g., "3 sets x 8 reps" or "400 calories"
  final bool completed;

  PlanItem({
    required this.description,
    this.details,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
        'description': description,
        'details': details,
        'completed': completed,
      };

  factory PlanItem.fromJson(Map<String, dynamic> json) => PlanItem(
        description: json['description'],
        details: json['details'],
        completed: json['completed'] ?? false,
      );
}
