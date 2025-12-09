import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../coach/coach_screen.dart';
import '../../models/coach_persona.dart';

class AIAvatarsScreen extends ConsumerWidget {
  const AIAvatarsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coaches'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
        children: [
          _CoachAvatarCard(
            name: 'Fitness Coach',
            emoji: '💪',
            color: Colors.blue,
            description: 'Workout plans, exercise form, strength training',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CoachScreen(personaId: 'fitness'),
                ),
              );
            },
          ),
          _CoachAvatarCard(
            name: 'Nutritionist',
            emoji: '🥗',
            color: Colors.orange,
            description: 'Meal plans, macros, supplements, diet advice',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CoachScreen(personaId: 'nutrition'),
                ),
              );
            },
          ),
          _CoachAvatarCard(
            name: 'Physical Therapist',
            emoji: '🩺',
            color: Colors.green,
            description: 'Injury recovery, mobility, pain management',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CoachScreen(personaId: 'pt'),
                ),
              );
            },
          ),
          _CoachAvatarCard(
            name: 'Wellness Coach',
            emoji: '🧘',
            color: Colors.purple,
            description: 'Sleep, stress, mental health, mindfulness',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CoachScreen(personaId: 'wellness'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CoachAvatarCard extends StatelessWidget {
  final String name;
  final String emoji;
  final Color color;
  final String description;
  final VoidCallback onTap;

  const _CoachAvatarCard({
    required this.name,
    required this.emoji,
    required this.color,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Chat Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
