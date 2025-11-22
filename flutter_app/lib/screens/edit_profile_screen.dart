import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/profile.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _feetController = TextEditingController();
  final _inchesController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  
  String? _selectedGender;
  String? _selectedActivityLevel;
  bool _loading = true;
  bool _saving = false;
  bool _useMetric = true; // true = cm/kg, false = feet+inches/lbs

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _loadProfile() {
    final auth = context.read<AuthProvider>();
    
    setState(() {
      _nameController.text = auth.user?.name ?? '';
      final heightCm = auth.profile?.heightCm;
      if (heightCm != null) {
        _heightController.text = heightCm.toString();
        // Convert to feet and inches for imperial display
        final totalInches = heightCm / 2.54;
        _feetController.text = (totalInches ~/ 12).toString();
        _inchesController.text = (totalInches % 12).toStringAsFixed(1);
      }
      _weightController.text = auth.profile?.weightKg?.toString() ?? '';
      _ageController.text = auth.profile?.age?.toString() ?? '';
      _selectedGender = auth.profile?.sex;
      _selectedActivityLevel = auth.profile?.activityLevel;
      _loading = false;
    });
  }

  void _toggleUnits() {
    setState(() {
      final currentWeight = double.tryParse(_weightController.text);

      if (_useMetric) {
        // Convert cm to feet/inches, kg to lbs
        final currentHeight = double.tryParse(_heightController.text);
        if (currentHeight != null) {
          final totalInches = currentHeight / 2.54;
          _feetController.text = (totalInches ~/ 12).toString();
          _inchesController.text = (totalInches % 12).toStringAsFixed(1);
        }
        if (currentWeight != null) {
          _weightController.text = (currentWeight * 2.20462).toStringAsFixed(1);
        }
      } else {
        // Convert feet/inches to cm, lbs to kg
        final feet = int.tryParse(_feetController.text) ?? 0;
        final inches = double.tryParse(_inchesController.text) ?? 0;
        final totalInches = (feet * 12) + inches;
        _heightController.text = (totalInches * 2.54).toStringAsFixed(1);
        
        if (currentWeight != null) {
          _weightController.text = (currentWeight / 2.20462).toStringAsFixed(1);
        }
      }

      _useMetric = !_useMetric;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    setState(() => _saving = true);

    try {
      // Update name in user if changed
      if (_nameController.text != auth.user!.name) {
        // You could add updateUser method to auth provider if needed
      }

      // Convert to metric if needed before saving
      double? heightCm;
      double? weightKg = double.tryParse(_weightController.text);

      if (_useMetric) {
        heightCm = double.tryParse(_heightController.text);
      } else {
        // Convert feet + inches to cm
        final feet = int.tryParse(_feetController.text) ?? 0;
        final inches = double.tryParse(_inchesController.text) ?? 0;
        final totalInches = (feet * 12) + inches;
        heightCm = totalInches * 2.54;
        
        // Convert lbs to kg
        if (weightKg != null) weightKg = weightKg / 2.20462;
      }

      final updatedProfile = Profile(
        userId: auth.user!.id,
        sex: _selectedGender,
        heightCm: heightCm,
        weightKg: weightKg,
        age: int.tryParse(_ageController.text),
        activityLevel: _selectedActivityLevel,
        equipment: auth.profile?.equipment ?? [],
        scheduleDays: auth.profile?.scheduleDays ?? [],
      );

      await auth.updateProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saving ? null : _saveProfile,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Personal Information',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        OutlinedButton.icon(
                          onPressed: _toggleUnits,
                          icon: const Icon(Icons.swap_horiz, size: 18),
                          label: Text(_useMetric ? 'Metric' : 'Imperial'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedGender = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select your gender';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        prefixIcon: Icon(Icons.calendar_today),
                        suffixText: 'years',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your age';
                        }
                        final age = int.tryParse(value);
                        if (age == null || age < 1 || age > 120) {
                          return 'Please enter a valid age';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    if (_useMetric)
                      TextFormField(
                        controller: _heightController,
                        decoration: const InputDecoration(
                          labelText: 'Height',
                          prefixIcon: Icon(Icons.height),
                          suffixText: 'cm',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your height';
                          }
                          final height = double.tryParse(value);
                          if (height == null) {
                            return 'Please enter a valid number';
                          }
                          if (height < 50 || height > 300) {
                            return 'Please enter a valid height (50-300 cm)';
                          }
                          return null;
                        },
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _feetController,
                              decoration: const InputDecoration(
                                labelText: 'Feet',
                                prefixIcon: Icon(Icons.height),
                                suffixText: 'ft',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final feet = int.tryParse(value);
                                if (feet == null || feet < 0 || feet > 8) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _inchesController,
                              decoration: const InputDecoration(
                                labelText: 'Inches',
                                suffixText: 'in',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final inches = double.tryParse(value);
                                if (inches == null || inches < 0 || inches >= 12) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _weightController,
                      decoration: InputDecoration(
                        labelText: 'Weight',
                        prefixIcon: const Icon(Icons.monitor_weight),
                        suffixText: _useMetric ? 'kg' : 'lbs',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your weight';
                        }
                        final weight = double.tryParse(value);
                        if (weight == null) {
                          return 'Please enter a valid number';
                        }
                        if (_useMetric && (weight < 20 || weight > 500)) {
                          return 'Please enter a valid weight (20-500 kg)';
                        }
                        if (!_useMetric && (weight < 44 || weight > 1100)) {
                          return 'Please enter a valid weight (44-1100 lbs)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      'Activity Level',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedActivityLevel,
                      decoration: const InputDecoration(
                        labelText: 'Activity Level',
                        prefixIcon: Icon(Icons.directions_run),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'sedentary',
                          child: Text('Sedentary (little or no exercise)'),
                        ),
                        DropdownMenuItem(
                          value: 'light',
                          child: Text('Lightly Active (1-3 days/week)'),
                        ),
                        DropdownMenuItem(
                          value: 'moderate',
                          child: Text('Moderately Active (3-5 days/week)'),
                        ),
                        DropdownMenuItem(
                          value: 'very',
                          child: Text('Very Active (6-7 days/week)'),
                        ),
                        DropdownMenuItem(
                          value: 'extra',
                          child: Text('Extra Active (athlete/physical job)'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedActivityLevel = value);
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    ElevatedButton(
                      onPressed: _saving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Profile'),
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
                                  'Why we need this',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your profile information helps us provide personalized workout plans, nutrition recommendations, and accurate calorie estimates.',
                              style: Theme.of(context).textTheme.bodySmall,
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
