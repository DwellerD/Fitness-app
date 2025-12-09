import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/plan.dart';
import '../../services/firestore_service.dart';
import '../../providers/meal_scan_provider.dart';
import '../coach/coach_screen.dart';

class PlanDetailScreen extends ConsumerStatefulWidget {
  final Plan plan;
  const PlanDetailScreen({super.key, required this.plan});

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  PlanDay? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _pickInitialDay(widget.plan);
  }

  // NEW: try to pick the PlanDay that corresponds to "today"
  PlanDay? _pickInitialDay(Plan plan) {
    if (plan.days.isEmpty) return null;

    final now = DateTime.now();
    // weekIndex: 1-based index of the current week within the plan duration
    final daysSinceStart = now.difference(plan.startDate).inDays;
    final currentWeekIndex =
        daysSinceStart < 0 ? 1 : (daysSinceStart ~/ 7) + 1; // clamp to 1+

    // weekday index 0..6 (Mon..Sun)
    final weekdayIndex = now.weekday - 1;

    // Try to find a day whose title matches Week N – {weekdayLabel}
    final weekdayLabels = const [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    final expectedTitle =
        'Week $currentWeekIndex – ${weekdayLabels[weekdayIndex]}';

    final matchByTitle = plan.days
        .where((d) => d.title.trim().toLowerCase() ==
            expectedTitle.trim().toLowerCase())
        .toList();
    if (matchByTitle.isNotEmpty) {
      return matchByTitle.first;
    }

    // Fallback: first incomplete day; if all complete, first day
    final firstIncomplete =
        plan.days.firstWhere((d) => !d.completed, orElse: () => plan.days.first);
    return firstIncomplete;
  }

  // NEW: move selection to next chronological day after a completion
  void _selectNextDayAfter(int completedDayNumber) {
    final sortedDays = [...widget.plan.days]
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    // Next day by dayNumber
    final next = sortedDays
        .firstWhere((d) => d.dayNumber > completedDayNumber,
            orElse: () => sortedDays.last);

    setState(() {
      _selectedDay = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;

    return Scaffold(
      appBar: AppBar(
        title: Text(plan.name),
        actions: [
          IconButton(
            tooltip: 'Edit with Coach',
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CoachScreen(
                    personaId: plan.coachType,
                    editingPlanId: plan.id,
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Delete Plan',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getColor(plan.type),
                  _getColor(plan.type).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_getIcon(plan.type), color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            plan.type.toString().split('.').last.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  plan.description,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: 'Progress',
                        value: '${(plan.progress * 100).toInt()}%',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBox(
                        label: 'Duration',
                        value: '${plan.durationWeeks} weeks',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBox(
                        label: 'Days Left',
                        value: '${plan.daysLeft}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall Progress',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: plan.progress,
                    minHeight: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(_getColor(plan.type)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(plan.progress * 100).toInt()}% Complete',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (plan.days.isEmpty)
            _EmptyPlanContent(plan: plan)
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calendar View',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _PlanCalendar(
                  days: plan.days,
                  color: _getColor(plan.type),
                  onDaySelected: (day) {
                    setState(() {
                      _selectedDay = day; // always show ONLY the tapped day
                    });
                  },
                  selectedDay: _selectedDay,
                  planId: plan.id,
                ),
                const SizedBox(height: 16),
                if (_selectedDay != null)
                  _DayDetailCard(
                    day: _selectedDay!,
                    color: _getColor(plan.type),
                    planId: plan.id,
                    onDayCompleted: () {
                      _selectNextDayAfter(_selectedDay!.dayNumber);
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text(
          'Are you sure you want to delete the plan "${widget.plan.name}"? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await ref.read(firestoreServiceProvider).deletePlan(widget.plan.id);
      if (context.mounted) {
        Navigator.pop(context); // go back to plans list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting plan: $e')),
        );
      }
    }
  }

  Color _getColor(PlanType type) {
    switch (type) {
      case PlanType.workout:
        return Colors.blue;
      case PlanType.nutrition:
        return Colors.orange;
      case PlanType.recovery:
        return Colors.green;
      case PlanType.wellness:
        return Colors.purple;
    }
  }

  IconData _getIcon(PlanType type) {
    switch (type) {
      case PlanType.workout:
        return Icons.fitness_center;
      case PlanType.nutrition:
        return Icons.restaurant_menu;
      case PlanType.recovery:
        return Icons.healing;
      case PlanType.wellness:
        return Icons.spa;
    }
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlanContent extends StatelessWidget {
  final Plan plan;

  const _EmptyPlanContent({required this.plan});

  @override
  Widget build(BuildContext context) {
    String prefill;
    switch (plan.type) {
      case PlanType.workout:
        prefill =
            "I have a plan called \"${plan.name}\". Can you help me build a detailed weekly workout plan for it?";
        break;
      case PlanType.nutrition:
        prefill =
            "I have a plan called \"${plan.name}\". Can you help me build a detailed weekly meal plan for it?";
        break;
      case PlanType.recovery:
        prefill =
            "I have a plan called \"${plan.name}\". Can you help me build a detailed physical therapy / recovery plan for it?";
        break;
      case PlanType.wellness:
        prefill =
            "I have a plan called \"${plan.name}\". Can you help me build a detailed weekly wellness routine for it?";
        break;
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.edit_note, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No detailed plan yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This plan was created from a chat. Chat with your coach again to add more details!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CoachScreen(
                      personaId: plan.coachType,
                    ),
                  ),
                ).then((_) {});
              },
              icon: const Icon(Icons.psychology),
              label: const Text('Make a plan with your coach'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCalendar extends ConsumerWidget {
  final List<PlanDay> days;
  final Color color;
  final void Function(PlanDay) onDaySelected;
  final PlanDay? selectedDay;
  final String planId;

  const _PlanCalendar({
    required this.days,
    required this.color,
    required this.onDaySelected,
    required this.selectedDay,
    required this.planId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (days.isEmpty) {
      return const Text('No days in this plan yet.');
    }

    final Map<int, List<PlanDay>> weeks = {};
    for (final d in days) {
      final weekIndex = ((d.dayNumber - 1) ~/ 7) + 1;
      weeks.putIfAbsent(weekIndex, () => []);
      weeks[weekIndex]!.add(d);
    }

    final weekIndices = weeks.keys.toList()..sort();

    return Column(
      children: weekIndices.map((week) {
        final weekDays = weeks[week]!..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Week $week',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: weekDays.map((day) {
                final isSelected = selectedDay?.dayNumber == day.dayNumber;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDaySelected(day),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.2)
                            : (day.completed
                                ? color.withOpacity(0.1)
                                : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : (day.completed ? color : Colors.grey[300]!),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'D${day.dayNumber}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: day.completed ? color : Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Icon(
                            day.completed ? Icons.check_circle : Icons.circle,
                            size: 14,
                            color: day.completed ? color : Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }
}

class _DayDetailCard extends ConsumerWidget {
  final PlanDay day;
  final Color color;
  final String planId;
  final VoidCallback onDayCompleted; // NEW

  const _DayDetailCard({
    required this.day,
    required this.color,
    required this.planId,
    required this.onDayCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: day.completed ? color : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Day ${day.dayNumber}: ${day.title}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (day.notes != null && day.notes!.trim().isNotEmpty)
            Text(
              day.notes!,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          if (day.notes != null && day.notes!.trim().isNotEmpty)
            const SizedBox(height: 12),
          if (day.items.isNotEmpty) ...[
            const Text(
              'Items / Exercises',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...day.items.map((item) => _PlanItemTile(item: item, color: color)),
            const SizedBox(height: 12),
          ],
          if (!day.completed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await ref
                      .read(firestoreServiceProvider)
                      .completePlanDay(planId, day.dayNumber);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Day completed! 🎉')),
                    );
                  }
                  // Move to next day in parent state
                  onDayCompleted();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.check),
                label: const Text('Mark Day Complete & Go to Next'),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanItemTile extends StatelessWidget {
  final PlanItem item;
  final Color color;

  const _PlanItemTile({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: const TextStyle(fontSize: 15),
                ),
                if (item.details != null)
                  Text(
                    item.details!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
