import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../providers/meal_scan_provider.dart';

class MealScanScreen extends ConsumerStatefulWidget {
  final String imagePath;

  const MealScanScreen({super.key, required this.imagePath});

  @override
  ConsumerState<MealScanScreen> createState() => _MealScanScreenState();
}

class _MealScanScreenState extends ConsumerState<MealScanScreen> {
  @override
  void initState() {
    super.initState();
    // Analyze the meal as soon as screen loads
    Future.microtask(() {
      ref.read(mealScanProvider.notifier).analyzeMeal(widget.imagePath);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(mealScanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyze Meal'),
        actions: [
          if (!scanState.isLoading && scanState.mealData != null)
            TextButton(
              onPressed: () {
                ref.read(mealScanProvider.notifier).saveMeal();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Meal logged successfully! 🎉')),
                );
              },
              child: const Text('Save', style: TextStyle(fontSize: 16)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview
            AspectRatio(
              aspectRatio: 1,
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.cover,
              ),
            ),
            
            if (scanState.isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Analyzing your meal with AI...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              )
            else if (scanState.error != null)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      scanState.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              )
            else if (scanState.mealData != null)
              _MealDataCard(mealData: scanState.mealData!),
          ],
        ),
      ),
    );
  }
}

class _MealDataCard extends StatelessWidget {
  final MealData mealData;

  const _MealDataCard({required this.mealData});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mealData.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            mealData.description,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 24),
          
          // Calories
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.teal[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department, size: 40, color: Colors.orange),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${mealData.calories}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Calories', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Macros
          const Text(
            'Macronutrients',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _MacroRow('Protein', mealData.protein, Colors.blue),
          _MacroRow('Carbs', mealData.carbs, Colors.orange),
          _MacroRow('Fat', mealData.fat, Colors.green),
          
          const SizedBox(height: 24),
          
          // Confidence note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'These are AI estimates. Adjust if needed.',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final int grams;
  final Color color;

  const _MacroRow(this.label, this.grams, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            '${grams}g',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
