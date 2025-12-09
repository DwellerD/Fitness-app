import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_profile.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_scan_provider.dart';

class InjuriesScreen extends ConsumerStatefulWidget {
  const InjuriesScreen({super.key});

  @override
  ConsumerState<InjuriesScreen> createState() => _InjuriesScreenState();
}

class _InjuriesScreenState extends ConsumerState<InjuriesScreen> {
  final List<String> _commonInjuries = [
    'Knee Pain',
    'Lower Back Pain',
    'Shoulder Pain',
    'Elbow Pain',
    'Wrist Pain',
    'Hip Pain',
    'Ankle Pain',
    'Neck Pain',
    'Upper Back Pain',
    'Hamstring Strain',
    'Groin Strain',
    'Achilles Tendinitis',
    'Plantar Fasciitis',
    'Tennis Elbow',
    'Rotator Cuff',
  ];

  Set<String> _selectedInjuries = {};
  final TextEditingController _customController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Injuries & Limitations'),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile != null && _selectedInjuries.isEmpty) {
            _selectedInjuries = profile.injuries.toSet();
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your AI coaches will avoid exercises that aggravate these areas.',
                              style: TextStyle(color: Colors.orange[900], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Current injuries or pain areas:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ..._commonInjuries.map((injury) {
                      final isSelected = _selectedInjuries.contains(injury);
                      return CheckboxListTile(
                        title: Text(injury),
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedInjuries.add(injury);
                            } else {
                              _selectedInjuries.remove(injury);
                            }
                          });
                        },
                        activeColor: Colors.orange,
                      );
                    }),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _customController,
                      decoration: InputDecoration(
                        labelText: 'Add custom injury or limitation',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            if (_customController.text.trim().isNotEmpty) {
                              setState(() {
                                _selectedInjuries.add(_customController.text.trim());
                                _customController.clear();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedInjuries.any((injury) => !_commonInjuries.contains(injury)))
                      Wrap(
                        spacing: 8,
                        children: _selectedInjuries
                            .where((injury) => !_commonInjuries.contains(injury))
                            .map((injury) => Chip(
                                  label: Text(injury),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                  onDeleted: () {
                                    setState(() => _selectedInjuries.remove(injury));
                                  },
                                ))
                            .toList(),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _saveInjuries(profile, user?.uid),
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

  Future<void> _saveInjuries(UserProfile? existingProfile, String? userId) async {
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final profile = (existingProfile ?? UserProfile(userId: userId)).copyWith(
        injuries: _selectedInjuries.toList(),
      );

      await ref.read(firestoreServiceProvider).saveUserProfile(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Injuries & limitations updated!')),
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
