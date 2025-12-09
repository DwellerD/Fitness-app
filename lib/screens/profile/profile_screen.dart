import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/meal_scan_provider.dart';
import '../../services/firestore_service.dart';
import 'personal_info_screen.dart';
import 'dietary_restrictions_screen.dart';
import 'injuries_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        children: [
          // User info header
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.teal,
                  child: Text(
                    user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                    style:
                        const TextStyle(fontSize: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.email ?? 'User',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Account section
          _SettingsSection(
            title: 'Account',
            items: [
              _SettingsItem(
                icon: Icons.person,
                title: 'Personal Info',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PersonalInfoScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          // Appearance section
          _SettingsSection(
            title: 'Appearance',
            items: [
              _SettingsItem(
                icon: Icons.dark_mode,
                title: 'Dark Mode',
                trailing: Switch(
                  value: themeMode == ThemeMode.dark,
                  onChanged: (isDark) {
                    ref
                        .read(themeModeProvider.notifier)
                        .setTheme(isDark ? ThemeMode.dark : ThemeMode.light);
                  },
                ),
                onTap: () {
                  final isDark = themeMode == ThemeMode.dark;
                  ref
                      .read(themeModeProvider.notifier)
                      .setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
                },
              ),
            ],
          ),

          // Preferences section
          _SettingsSection(
            title: 'Preferences',
            items: [
              _SettingsItem(
                icon: Icons.restaurant_menu,
                title: 'Dietary Restrictions',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DietaryRestrictionsScreen(),
                    ),
                  );
                },
              ),
              _SettingsItem(
                icon: Icons.healing,
                title: 'Injuries & Limitations',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InjuriesScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          // Data & Privacy section
          _SettingsSection(
            title: 'Data & Privacy',
            items: [
              _SettingsItem(
                icon: Icons.download,
                title: 'Export My Data',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export feature coming soon!'),
                    ),
                  );
                },
              ),
              _SettingsItem(
                icon: Icons.delete_forever,
                title: 'Delete My Data',
                isDestructive: true,
                onTap: () => _showDeleteConfirmation(context, ref),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sign out button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () =>
                  ref.read(authServiceProvider).signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'Are you sure you want to delete all your data and account? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final scaffoldMessenger =
                  ScaffoldMessenger.of(context);

              try {
                await ref
                    .read(firestoreServiceProvider)
                    .deleteAllUserData();
                await ref.read(authServiceProvider).signOut();

                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content:
                        Text('Your data has been deleted.'),
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content:
                        Text('Error deleting data: $e'),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        ...items,
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;
  final Widget? trailing;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : null;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
