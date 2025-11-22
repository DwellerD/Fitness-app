import 'package:flutter/material.dart';

class AvatarsScreen extends StatelessWidget {
  const AvatarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coaches'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildAvatarCard(
            context,
            'Nutrition Coach',
            Icons.restaurant_menu,
            Colors.green,
            'nutrition',
          ),
          _buildAvatarCard(
            context,
            'Fitness Coach',
            Icons.fitness_center,
            Colors.blue,
            'fitness',
          ),
          _buildAvatarCard(
            context,
            'Wellness Coach',
            Icons.spa,
            Colors.purple,
            'wellness',
          ),
          _buildAvatarCard(
            context,
            'Personal Trainer',
            Icons.sports_gymnastics,
            Colors.orange,
            'trainer',
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String avatarId,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/avatar-chat', arguments: avatarId);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
