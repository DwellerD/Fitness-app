import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/plans_provider.dart';
import '../../providers/profile_provider.dart';
import '../../models/plan.dart';
import '../nutrition/nutrition_screen.dart';
import '../ai_avatars/ai_avatars_screen.dart';
import '../training/training_screen.dart';
import '../plans/plan_detail_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final todaysTotals = ref.watch(todaysTotalsProvider);
    final plansAsync = ref.watch(userPlansProvider);
    final profileAsync = ref.watch(userProfileProvider);

    final weekdayLabels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayLabel = weekdayLabels[now.weekday - 1];

    PlanDay? _pickTodayDay(Plan plan) {
      final match = plan.days.firstWhere(
        (d) => d.title.contains(todayLabel),
        orElse: () => plan.days.first,
      );
      return match;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text(
                '$greeting, ${user?.email?.split('@').first ?? 'there'}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Keep up the great work! 💪',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),

              // Today's plan summary (workout + meal)
              plansAsync.when(
                data: (plans) {
                  final workoutPlan = plans
                      .where((p) => p.type == PlanType.workout)
                      .cast<Plan?>()
                      .firstWhere((_) => true, orElse: () => null);
                  final nutritionPlan = plans
                      .where((p) => p.type == PlanType.nutrition)
                      .cast<Plan?>()
                      .firstWhere((_) => true, orElse: () => null);

                  if (workoutPlan == null && nutritionPlan == null) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    children: [
                      if (workoutPlan != null && workoutPlan.days.isNotEmpty)
                        _DashboardCard(
                          title: "Today's Workout Plan",
                          icon: Icons.fitness_center,
                          child: _TodayPlanSnippet(
                            plan: workoutPlan,
                            day: _pickTodayDay(workoutPlan) ?? workoutPlan.days.first,
                          ),
                        ),
                      if (workoutPlan != null && workoutPlan.days.isNotEmpty)
                        const SizedBox(height: 16),
                      if (nutritionPlan != null && nutritionPlan.days.isNotEmpty)
                        _DashboardCard(
                          title: "Today's Meal Plan",
                          icon: Icons.restaurant_menu,
                          child: _TodayPlanSnippet(
                            plan: nutritionPlan,
                            day: _pickTodayDay(nutritionPlan) ?? nutritionPlan.days.first,
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Today's Activity Card
              _DashboardCard(
                title: "Today's Activity",
                icon: Icons.directions_run,
                child: Column(
                  children: [
                    Text(
                      'Activity tracking coming soon',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TrainingScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.fitness_center, size: 18),
                          label: const Text('Log Workout'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            // placeholder for future tracker connection
                          },
                          icon: const Icon(Icons.watch, size: 18),
                          label: const Text('Connect Tracker'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Nutrition Card (goals from profile)
              _DashboardCard(
                title: 'Today\'s Nutrition Goals',
                icon: Icons.restaurant,
                child: profileAsync.when(
                  data: (profile) {
                    final calorieGoal = profile?.calorieGoal ?? 2300;
                    final proteinGoal = profile?.proteinGoal ?? 170;
                    final carbsGoal = profile?.carbsGoal ?? 250;
                    final fatGoal = profile?.fatGoal ?? 70;

                    return todaysTotals.when(
                      data: (totals) {
                        final calories = totals['calories'] ?? 0;
                        final protein = totals['protein'] ?? 0;
                        final carbs = totals['carbs'] ?? 0;
                        final fat = totals['fat'] ?? 0;

                        final calPct =
                            calorieGoal == 0 ? 0.0 : calories / calorieGoal;
                        final pPct =
                            proteinGoal == 0 ? 0.0 : protein / proteinGoal;
                        final cPct = carbsGoal == 0 ? 0.0 : carbs / carbsGoal;
                        final fPct = fatGoal == 0 ? 0.0 : fat / fatGoal;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Calories summary
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$calories / $calorieGoal kcal',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        'Calories eaten today',
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Remaining: ${(calorieGoal - calories).clamp(0, calorieGoal)} kcal',
                                        style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CircularProgressIndicator(
                                        value: calPct.clamp(0.0, 1.2),
                                        strokeWidth: 6,
                                        backgroundColor: Colors.grey[200],
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                                Colors.teal),
                                      ),
                                      Center(
                                        child: Text(
                                          '${(calPct * 100).clamp(0, 999).toInt()}%',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Macro bars
                            Row(
                              children: [
                                Expanded(
                                  child: _MacroBar(
                                    label: 'Protein',
                                    value: pPct.clamp(0.0, 1.2),
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _MacroBar(
                                    label: 'Carbs',
                                    value: cPct.clamp(0.0, 1.2),
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _MacroBar(
                                    label: 'Fats',
                                    value: fPct.clamp(0.0, 1.2),
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'P: $protein / $proteinGoal g',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[600]),
                                ),
                                Text(
                                  'C: $carbs / $carbsGoal g',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[600]),
                                ),
                                Text(
                                  'F: $fat / $fatGoal g',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const NutritionScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Open Nutrition'),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) =>
                          const Text('Error loading nutrition data'),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) =>
                      const Text('Error loading profile / goals'),
                ),
              ),

              const SizedBox(height: 16),

              // AI Coach Suggestion
              _DashboardCard(
                title: 'Coach Suggestion',
                icon: Icons.lightbulb,
                color: Colors.teal[50],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat with your AI coaches to get personalized advice and create custom plans! 💪',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AIAvatarsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text('Talk to Coach'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Body Check-in
              _DashboardCard(
                title: 'How are you feeling?',
                icon: Icons.favorite,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _EmojiButton(emoji: '😫', label: 'Tired'),
                        _EmojiButton(emoji: '😐', label: 'Okay'),
                        _EmojiButton(emoji: '😊', label: 'Good'),
                        _EmojiButton(emoji: '🔥', label: 'Great'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.report_problem),
                      label: const Text('My knee hurts today'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? color;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
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
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.teal),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MacroBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _EmojiButton extends StatelessWidget {
  final String emoji;
  final String label;

  const _EmojiButton({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _TodayPlanSnippet extends StatelessWidget {
  final Plan plan;
  final PlanDay day;

  const _TodayPlanSnippet({required this.plan, required this.day});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          day.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        if (day.notes != null && day.notes!.trim().isNotEmpty)
          Text(
            day.notes!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        if (day.items.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...day.items.take(2).map((i) => Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      i.description,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )),
          if (day.items.length > 2)
            Text(
              '+ ${day.items.length - 2} more',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlanDetailScreen(plan: plan),
                ),
              );
            },
            child: const Text(
              'View full plan',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
