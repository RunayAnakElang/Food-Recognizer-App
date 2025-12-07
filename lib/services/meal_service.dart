import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MealService {
  static const String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  Future<List<Meal>> searchMealByName(String mealName) async {
    try {
      if (mealName.toLowerCase() == 'not food' ||
          mealName.toLowerCase() == 'unknown') {
        return [];
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/search.php?s=$mealName'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['meals'] == null) {
          debugPrint('No meals found for: $mealName');
          return [];
        }

        final meals = (data['meals'] as List)
            .map((meal) => Meal.fromJson(meal))
            .toList();

        debugPrint('Found ${meals.length} meals for: $mealName');
        return meals;
      } else {
        debugPrint('Failed to load meals: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error searching meals: $e');
      return [];
    }
  }
}

class Meal {
  final String id;
  final String name;
  final String? category;
  final String? area;
  final String instructions;
  final String thumbnail;
  final List<Ingredient> ingredients;

  Meal({
    required this.id,
    required this.name,
    this.category,
    this.area,
    required this.instructions,
    required this.thumbnail,
    required this.ingredients,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    List<Ingredient> ingredients = [];

    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'];
      final measure = json['strMeasure$i'];

      if (ingredient != null &&
          ingredient.toString().trim().isNotEmpty &&
          ingredient.toString().trim() != 'null') {
        ingredients.add(Ingredient(
          name: ingredient.toString().trim(),
          measure: measure?.toString().trim() ?? '',
        ));
      }
    }

    return Meal(
      id: json['idMeal'] ?? '',
      name: json['strMeal'] ?? 'Unknown',
      category: json['strCategory'],
      area: json['strArea'],
      instructions: json['strInstructions'] ?? '',
      thumbnail: json['strMealThumb'] ?? '',
      ingredients: ingredients,
    );
  }
}

class Ingredient {
  final String name;
  final String measure;

  Ingredient({
    required this.name,
    required this.measure,
  });
}
