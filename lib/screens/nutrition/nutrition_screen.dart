import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/profile_provider.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nutrition'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Today'),
              Tab(text: 'Recipes'),
              Tab(text: 'Grocery'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TodayTab(),
            _RecipesTab(),
            _GroceryTab(),
          ],
        ),
      ),
    );
  }
}

class _TodayTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaysMeals = ref.watch(todaysMealsProvider);
    final todaysTotals = ref.watch(todaysTotalsProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Calorie summary
        profileAsync.when(
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

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$calories / $calorieGoal',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Text('Calories'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MacroColumn(
                            'Protein',
                            '${protein}g',
                            '${proteinGoal}g',
                            Colors.blue,
                          ),
                          _MacroColumn(
                            'Carbs',
                            '${carbs}g',
                            '${carbsGoal}g',
                            Colors.orange,
                          ),
                          _MacroColumn(
                            'Fats',
                            '${fat}g',
                            '${fatGoal}g',
                            Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error loading totals'),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => const Text('Error loading profile'),
        ),
        const SizedBox(height: 24),
        
        // Today's meals
        todaysMeals.when(
          data: (meals) {
            if (meals.isEmpty) {
              return Column(
                children: [
                  const Icon(Icons.restaurant, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No meals logged today'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Scan Your First Meal'),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today\'s Meals',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...meals.map((meal) => _MealCard(meal: meal)),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Error loading meals'),
        ),
      ],
    );
  }
}

class _MacroColumn extends StatelessWidget {
  final String label;
  final String current;
  final String target;
  final Color color;

  const _MacroColumn(this.label, this.current, this.target, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(current, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text('/ $target', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  final meal;

  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.restaurant, color: Colors.teal, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      meal.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '${meal.calories} cal',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MacroChip('P: ${meal.protein}g', Colors.blue),
              const SizedBox(width: 8),
              _MacroChip('C: ${meal.carbs}g', Colors.orange),
              const SizedBox(width: 8),
              _MacroChip('F: ${meal.fat}g', Colors.green),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MacroChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _RecipesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Recipes coming soon'));
  }
}

class _GroceryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Grocery planner coming soon'));
  }
}
