import 'package:flutter/material.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plans'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.fitness_center, size: 40),
              title: const Text('Workout Plan'),
              subtitle: const Text('AI-generated exercise routines'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Navigate to workout plan detail
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Workout plans coming soon'),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.restaurant, size: 40),
              title: const Text('Nutrition Plan'),
              subtitle: const Text('Personalized meal plans'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Navigate to PT plan detail
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nutrition plans coming soon'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
