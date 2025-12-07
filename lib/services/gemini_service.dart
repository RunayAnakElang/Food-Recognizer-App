import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class NutritionalInfo {
  final String calories;
  final String carbohydrates;
  final String fat;
  final String fiber;
  final String protein;

  NutritionalInfo({
    required this.calories,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.protein,
  });

  factory NutritionalInfo.fromJson(Map<String, dynamic> json) {
    return NutritionalInfo(
      calories: json['calories'] ?? 'N/A',
      carbohydrates: json['carbohydrates'] ?? 'N/A',
      fat: json['fat'] ?? 'N/A',
      fiber: json['fiber'] ?? 'N/A',
      protein: json['protein'] ?? 'N/A',
    );
  }
}

class GeminiService {
  final GenerativeModel _model;

  GeminiService()
      : _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: dotenv.env['GEMINI_API_KEY']!,
  );

  Future<NutritionalInfo?> getNutritionalInfo(String foodName) async {
    final prompt = '''
      Provide the typical nutritional information for a standard serving of "$foodName". 
      The output must be a single JSON object (nothing else, no markdown, no header).
      The JSON object must contain the following keys and their values as strings with units:
      {"calories": "X kcal", "carbohydrates": "Y g", "fat": "Z g", "fiber": "A g", "protein": "B g"}.
    ''';

    try {
      final response = await _model.generateContent(
        [Content.text(prompt)],
      );

      final jsonString = response.text?.trim();

      if (jsonString != null && jsonString.isNotEmpty) {
        String cleanJsonString = jsonString
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        if (!cleanJsonString.startsWith('{') || !cleanJsonString.endsWith('}')) {
          final startIndex = cleanJsonString.indexOf('{');
          final endIndex = cleanJsonString.lastIndexOf('}');
          if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
            cleanJsonString = cleanJsonString.substring(startIndex, endIndex + 1);
          } else {
            debugPrint('Gemini API Error: Could not parse JSON structure.');
            return null;
          }
        }

        final jsonResponse = json.decode(cleanJsonString);
        return NutritionalInfo.fromJson(jsonResponse);
      }
      return null;
    } catch (e) {
      debugPrint('Gemini API Error: Failed to generate content or decode JSON: $e');
      return null;
    }
  }
}