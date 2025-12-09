import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/plans_provider.dart';
import '../../models/plan.dart';
import 'plan_detail_screen.dart';
import '../ai_avatars/ai_avatars_screen.dart';
import '../coach/coach_screen.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(userPlansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Plans'),
      ),
      body: plansAsync.when(
        data: (plans) {
          final workoutPlans =
              plans.where((p) => p.type == PlanType.workout).toList();
          final nutritionPlans =
              plans.where((p) => p.type == PlanType.nutrition).toList();
          final recoveryPlans =
              plans.where((p) => p.type == PlanType.recovery).toList();
          final wellnessPlans =
              plans.where((p) => p.type == PlanType.wellness).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Workout section
              const _SectionHeader(title: 'Workout Plans'),
              const SizedBox(height: 8),
              if (workoutPlans.isEmpty)
                _EmptySectionCard(
                  label: 'No workout plans yet',
                  buttonLabel: 'Make a workout plan',
                  color: Colors.blue,
                  personaId: 'fitness',
                )
              else ...[
                ...workoutPlans.map((plan) => _PlanCard(plan: plan)),
              ],
              const SizedBox(height: 16),

              // Nutrition section
              const _SectionHeader(title: 'Nutrition Plans'),
              const SizedBox(height: 8),
              if (nutritionPlans.isEmpty)
                _EmptySectionCard(
                  label: 'No nutrition plans yet',
                  buttonLabel: 'Make a nutrition plan',
                  color: Colors.orange,
                  personaId: 'nutrition',
                )
              else ...[
                ...nutritionPlans.map((plan) => _PlanCard(plan: plan)),
              ],
              const SizedBox(height: 16),

              // Physical Therapy section
              const _SectionHeader(title: 'Physical Therapy Plans'),
              const SizedBox(height: 8),
              if (recoveryPlans.isEmpty)
                _EmptySectionCard(
                  label: 'No physical therapy plans yet',
                  buttonLabel: 'Make a PT plan',
                  color: Colors.green,
                  personaId: 'pt',
                )
              else ...[
                ...recoveryPlans.map((plan) => _PlanCard(plan: plan)),
              ],
              const SizedBox(height: 16),

              // Wellness section
              const _SectionHeader(title: 'Wellness Plans'),
              const SizedBox(height: 8),
              if (wellnessPlans.isEmpty)
                _EmptySectionCard(
                  label: 'No wellness plans yet',
                  buttonLabel: 'Make a wellness plan',
                  color: Colors.purple,
                  personaId: 'wellness',
                )
              else ...[
                ...wellnessPlans.map((plan) => _PlanCard(plan: plan)),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _EmptyPlansView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today,
                size: 64,
                color: Colors.teal[700],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Active Plans',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chat with your AI coaches to create personalized plans!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AIAvatarsScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.psychology),
              label: const Text('Talk to AI Coaches'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySectionCard extends StatelessWidget {
  final String label;
  final String buttonLabel;
  final Color color;
  final String personaId;

  const _EmptySectionCard({
    required this.label,
    required this.buttonLabel,
    required this.color,
    required this.personaId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CoachScreen(personaId: personaId),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: color,
            ),
            child: Text(
              buttonLabel,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Plan plan;

  const _PlanCard({required this.plan});

  Color get _color {
    switch (plan.type) {
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

  IconData get _icon {
    switch (plan.type) {
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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlanDetailScreen(plan: plan),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon, color: _color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        plan.type.toString().split('.').last.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              plan.description,
              style: TextStyle(color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${(plan.progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: plan.progress,
                          minHeight: 6,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(_color),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    Text(
                      '${plan.daysLeft}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _color,
                      ),
                    ),
                    Text(
                      'days left',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
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
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit plan'),
                style: TextButton.styleFrom(
                  foregroundColor: _color,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
