import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_profile.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_scan_provider.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightFeetController = TextEditingController();
  final _heightInchesController = TextEditingController();
  final _weightController = TextEditingController();
  final _goalsController = TextEditingController();

  String? _gender;
  String? _activityLevel;
  String? _dietPreference; // NEW
  bool _isLoading = false;
  bool _useMetric = true;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    _weightController.dispose();
    _goalsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Info'),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile != null && _nameController.text.isEmpty) {
            _nameController.text = profile.name ?? '';
            _ageController.text = profile.age?.toString() ?? '';
            _gender = profile.gender;
            _activityLevel = profile.activityLevel;
            _useMetric = profile.useMetric;
            _goalsController.text = profile.goals ?? '';
            _dietPreference = profile.dietPreference; // NEW

            // Height: load into appropriate fields
            if (profile.height != null) {
              final hCm = profile.height!;
              if (_useMetric) {
                // metric: show cm as-is
                // store in inches text field just in case we toggle later
                final inchesTotal = hCm / 2.54;
                final feet = inchesTotal ~/ 12;
                final inches = (inchesTotal - feet * 12).round();
                _heightFeetController.text = feet.toString();
                _heightInchesController.text = inches.toString();
              } else {
                // imperial: split cm → ft/in
                final inchesTotal = hCm / 2.54;
                final feet = inchesTotal ~/ 12;
                final inches = (inchesTotal - feet * 12).round();
                _heightFeetController.text = feet.toString();
                _heightInchesController.text = inches.toString();
              }
            }
            // Weight as stored (kg or lb based on useMetric)
            _weightController.text = profile.weight?.toString() ?? '';
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Unit Switcher
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.straighten, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Units',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text('Metric')),
                          ButtonSegment(value: false, label: Text('Imperial')),
                        ],
                        selected: {_useMetric},
                        onSelectionChanged: (Set<bool> newSelection) {
                          setState(() => _useMetric = newSelection.first);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.cake),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.wc),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) => setState(() => _gender = value),
                ),
                const SizedBox(height: 16),
                if (_useMetric)
                  TextFormField(
                    controller: _heightFeetController,
                    decoration: const InputDecoration(
                      labelText: 'Height (cm)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.height),
                    ),
                    keyboardType: TextInputType.number,
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _heightFeetController,
                          decoration: const InputDecoration(
                            labelText: 'Height (ft)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.height),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _heightInchesController,
                          decoration: const InputDecoration(
                            labelText: 'Height (in)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _weightController,
                  decoration: InputDecoration(
                    labelText: _useMetric ? 'Weight (kg)' : 'Weight (lbs)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.monitor_weight),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _activityLevel,
                  decoration: const InputDecoration(
                    labelText: 'Activity Level',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_run),
                  ),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'sedentary',
                      child: Text('Sedentary', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: 'light',
                      child: Text('Lightly Active', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: 'moderate',
                      child: Text('Moderately Active', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: 'very',
                      child: Text('Very Active', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: 'extra',
                      child: Text('Extra Active', overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  onChanged: (value) => setState(() => _activityLevel = value),
                ),
                const SizedBox(height: 16),

                // NEW: Diet preference
                DropdownButtonFormField<String>(
                  value: _dietPreference,
                  decoration: const InputDecoration(
                    labelText: 'Diet Preference',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.restaurant_menu),
                  ),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'none',
                      child: Text('No specific diet'),
                    ),
                    DropdownMenuItem(
                      value: 'keto',
                      child: Text('Keto'),
                    ),
                    DropdownMenuItem(
                      value: 'paleo',
                      child: Text('Paleo'),
                    ),
                    DropdownMenuItem(
                      value: 'mediterranean',
                      child: Text('Mediterranean'),
                    ),
                    DropdownMenuItem(
                      value: 'low_carb',
                      child: Text('Low Carb'),
                    ),
                    DropdownMenuItem(
                      value: 'low_fat',
                      child: Text('Low Fat'),
                    ),
                    DropdownMenuItem(
                      value: 'high_protein',
                      child: Text('High Protein'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _dietPreference = value),
                ),
                const SizedBox(height: 16),

                Text(
                  'Your Goals',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Share your main fitness, nutrition, or wellness goals. Your AI coaches will use this when giving advice.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _goalsController,
                  decoration: const InputDecoration(
                    labelText: 'Your goals, preferences, notes',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _saveProfile(profile, user?.uid),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Changes'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _saveProfile(UserProfile? existingProfile, String? userId) async {
    if (!_formKey.currentState!.validate() || userId == null) return;

    setState(() => _isLoading = true);

    try {
      // Convert height to cm
      double? heightCm;
      if (_useMetric) {
        // interpret text as cm directly
        final cm = double.tryParse(_heightFeetController.text);
        heightCm = cm;
      } else {
        final feet = int.tryParse(_heightFeetController.text) ?? 0;
        final inches = int.tryParse(_heightInchesController.text) ?? 0;
        final totalInches = feet * 12 + inches;
        if (totalInches > 0) {
          heightCm = totalInches * 2.54;
        }
      }

      double? weight;
      final weightVal = double.tryParse(_weightController.text);
      if (weightVal != null) {
        weight = _useMetric ? weightVal : weightVal * 0.45359237; // lb -> kg
      }

      final profile = (existingProfile ?? UserProfile(userId: userId)).copyWith(
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        age: int.tryParse(_ageController.text),
        gender: _gender,
        height: heightCm,
        weight: weight,
        activityLevel: _activityLevel,
        useMetric: _useMetric,
        goals: _goalsController.text.trim().isEmpty
            ? null
            : _goalsController.text.trim(),
        dietPreference: _dietPreference == 'none' ? null : _dietPreference,
      );

      await ref.read(firestoreServiceProvider).saveUserProfile(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
