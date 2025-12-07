import 'package:flutter/material.dart';
import 'package:submission/services/meal_service.dart';

class MealDetailPage extends StatelessWidget {
  final Meal meal;

  const MealDetailPage({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(meal.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'meal_${meal.id}',
              child: Image.network(
                meal.thumbnail,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    color: Colors.grey[300],
                    child: const Icon(Icons.restaurant, size: 80),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (meal.category != null || meal.area != null)
                    Wrap(
                      spacing: 8,
                      children: [
                        if (meal.category != null)
                          Chip(
                            label: Text(meal.category!),
                            avatar: const Icon(Icons.category, size: 16),
                          ),
                        if (meal.area != null)
                          Chip(
                            label: Text(meal.area!),
                            avatar: const Icon(Icons.public, size: 16),
                          ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  Text(
                    'Ingredients',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...meal.ingredients.map((ingredient) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 18)),
                          Expanded(
                            child: Text(
                              '${ingredient.name}${ingredient.measure.isNotEmpty ? " - ${ingredient.measure}" : ""}',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 24),

                  Text(
                    'Instructions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    meal.instructions,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.justify,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}