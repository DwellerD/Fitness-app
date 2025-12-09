import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_profile.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_scan_provider.dart';

class DietaryRestrictionsScreen extends ConsumerStatefulWidget {
  const DietaryRestrictionsScreen({super.key});

  @override
  ConsumerState<DietaryRestrictionsScreen> createState() => _DietaryRestrictionsScreenState();
}

class _DietaryRestrictionsScreenState extends ConsumerState<DietaryRestrictionsScreen> {
  final List<String> _allRestrictions = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Dairy-Free',
    'Nut-Free',
    'Halal',
    'Kosher',
    'Paleo',
    'Keto',
    'Low-Carb',
    'Low-Fat',
    'No Red Meat',
    'No Pork',
    'No Seafood',
    'No Eggs',
  ];

  Set<String> _selectedRestrictions = {};
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dietary Restrictions'),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile != null && _selectedRestrictions.isEmpty) {
            _selectedRestrictions = profile.dietaryRestrictions.toSet();
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Select any dietary restrictions or preferences:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ..._allRestrictions.map((restriction) {
                      final isSelected = _selectedRestrictions.contains(restriction);
                      return CheckboxListTile(
                        title: Text(restriction),
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedRestrictions.add(restriction);
                            } else {
                              _selectedRestrictions.remove(restriction);
                            }
                          });
                        },
                        activeColor: Colors.teal,
                      );
                    }),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _saveRestrictions(profile, user?.uid),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save'),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _saveRestrictions(UserProfile? existingProfile, String? userId) async {
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final profile = (existingProfile ?? UserProfile(userId: userId)).copyWith(
        dietaryRestrictions: _selectedRestrictions.toList(),
      );

      await ref.read(firestoreServiceProvider).saveUserProfile(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dietary restrictions updated!')),
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
