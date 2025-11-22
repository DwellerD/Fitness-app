import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../database/meals_repository.dart';
import '../database/goals_repository.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final _mealsRepo = MealsRepository();
  final _goalsRepo = GoalsRepository();
  
  Map<String, double>? _dailyTotals;
  Map<String, dynamic>? _goals;
  List<Map<String, dynamic>> _todayMeals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    setState(() => _loading = true);

    final today = DateTime.now().toIso8601String().split('T')[0];
    
    final totals = await _mealsRepo.getDailyTotals(auth.user!.id, today);
    final goals = await _goalsRepo.getGoals(auth.user!.id);
    final meals = await _mealsRepo.getMealsForDate(auth.user!.id, today);

    if (mounted) {
      setState(() {
        _dailyTotals = totals;
        _goals = goals;
        _todayMeals = meals;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Profile Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: Text(
                                  auth.user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                                  style: const TextStyle(fontSize: 24, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello, ${auth.user?.name ?? 'User'}!',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    if (profile != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '${profile.sex ?? 'N/A'} • ${profile.heightCm?.toInt() ?? 0}cm • ${profile.weightKg?.toInt() ?? 0}kg • ${profile.age ?? 0}y',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Macros Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s Nutrition',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          _buildMacroRow(
                            'Calories',
                            _dailyTotals?['calories'] ?? 0,
                            _goals?['target_calories'] ?? 2000,
                            'kcal',
                          ),
                          const SizedBox(height: 8),
                          _buildMacroRow(
                            'Protein',
                            _dailyTotals?['protein'] ?? 0,
                            _goals?['target_protein'] ?? 150,
                            'g',
                          ),
                          const SizedBox(height: 8),
                          _buildMacroRow(
                            'Carbs',
                            _dailyTotals?['carbs'] ?? 0,
                            _goals?['target_carbs'] ?? 200,
                            'g',
                          ),
                          const SizedBox(height: 8),
                          _buildMacroRow(
                            'Fat',
                            _dailyTotals?['fat'] ?? 0,
                            _goals?['target_fat'] ?? 70,
                            'g',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Meals List
                  Text(
                    'Today\'s Meals',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_todayMeals.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No meals logged yet',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._todayMeals.map((meal) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: meal['photo_uri'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  meal['photo_uri'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.restaurant),
                                ),
                              )
                            : const Icon(Icons.restaurant),
                        title: Text(
                          '${meal['total_calories']?.toInt() ?? 0} kcal',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'P: ${meal['total_protein']?.toInt() ?? 0}g • '
                          'C: ${meal['total_carbs']?.toInt() ?? 0}g • '
                          'F: ${meal['total_fat']?.toInt() ?? 0}g',
                        ),
                        trailing: Text(
                          _formatTime(meal['timestamp']),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    )),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-meal').then((_) => _loadData());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMacroRow(String label, double current, double target, String unit) {
    final percentage = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${current.toInt()} / ${target.toInt()} $unit'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[300],
        ),
      ],
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}
