import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../database/goals_repository.dart';

class EditGoalsScreen extends StatefulWidget {
  const EditGoalsScreen({super.key});

  @override
  State<EditGoalsScreen> createState() => _EditGoalsScreenState();
}

class _EditGoalsScreenState extends State<EditGoalsScreen> {
  final _goalsRepo = GoalsRepository();
  final _formKey = GlobalKey<FormState>();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    setState(() => _loading = true);

    try {
      final goals = await _goalsRepo.getGoals(auth.user!.id);
      
      if (mounted) {
        if (goals != null) {
          _caloriesController.text = goals['target_calories']?.toString() ?? '2000';
          _proteinController.text = goals['target_protein']?.toString() ?? '150';
          _carbsController.text = goals['target_carbs']?.toString() ?? '200';
          _fatController.text = goals['target_fat']?.toString() ?? '70';
        } else {
          // Set defaults
          _caloriesController.text = '2000';
          _proteinController.text = '150';
          _carbsController.text = '200';
          _fatController.text = '70';
        }
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading goals: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveGoals() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    setState(() => _saving = true);

    try {
      await _goalsRepo.upsertGoals(
        userId: auth.user!.id,
        targetCalories: double.tryParse(_caloriesController.text),
        targetProtein: double.tryParse(_proteinController.text),
        targetCarbs: double.tryParse(_carbsController.text),
        targetFat: double.tryParse(_fatController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goals updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving goals: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _applyPreset(String preset) {
    setState(() {
      switch (preset) {
        case 'cutting':
          _caloriesController.text = '1800';
          _proteinController.text = '180';
          _carbsController.text = '150';
          _fatController.text = '50';
          break;
        case 'maintaining':
          _caloriesController.text = '2200';
          _proteinController.text = '165';
          _carbsController.text = '220';
          _fatController.text = '70';
          break;
        case 'bulking':
          _caloriesController.text = '2800';
          _proteinController.text = '200';
          _carbsController.text = '315';
          _fatController.text = '80';
          break;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied ${preset.toUpperCase()} preset'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildPresetInfo(String title, String macros, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          macros,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saving ? null : _saveGoals,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Set your daily nutrition targets',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    
                    TextFormField(
                      controller: _caloriesController,
                      decoration: const InputDecoration(
                        labelText: 'Calories',
                        suffixText: 'kcal',
                        prefixIcon: Icon(Icons.local_fire_department),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a value';
                        }
                        final num = double.tryParse(value);
                        if (num == null || num <= 0) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _proteinController,
                      decoration: const InputDecoration(
                        labelText: 'Protein',
                        suffixText: 'g',
                        prefixIcon: Icon(Icons.egg),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a value';
                        }
                        final num = double.tryParse(value);
                        if (num == null || num <= 0) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _carbsController,
                      decoration: const InputDecoration(
                        labelText: 'Carbs',
                        suffixText: 'g',
                        prefixIcon: Icon(Icons.rice_bowl),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a value';
                        }
                        final num = double.tryParse(value);
                        if (num == null || num <= 0) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _fatController,
                      decoration: const InputDecoration(
                        labelText: 'Fat',
                        suffixText: 'g',
                        prefixIcon: Icon(Icons.water_drop),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a value';
                        }
                        final num = double.tryParse(value);
                        if (num == null || num <= 0) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    ElevatedButton(
                      onPressed: _saving ? null : _saveGoals,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Goals'),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      'Quick Presets',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _applyPreset('cutting'),
                            icon: const Icon(Icons.trending_down),
                            label: const Text('Cutting'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _applyPreset('maintaining'),
                            icon: const Icon(Icons.horizontal_rule),
                            label: const Text('Maintain'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _applyPreset('bulking'),
                            icon: const Icon(Icons.trending_up),
                            label: const Text('Bulking'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Card(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Preset Guide',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildPresetInfo(
                              'Cutting',
                              '1,800 kcal • 180g protein • 150g carbs • 50g fat',
                              'Fat loss while preserving muscle',
                            ),
                            const Divider(height: 16),
                            _buildPresetInfo(
                              'Maintaining',
                              '2,200 kcal • 165g protein • 220g carbs • 70g fat',
                              'Maintain current weight and composition',
                            ),
                            const Divider(height: 16),
                            _buildPresetInfo(
                              'Bulking',
                              '2,800 kcal • 200g protein • 315g carbs • 80g fat',
                              'Build muscle with controlled surplus',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
