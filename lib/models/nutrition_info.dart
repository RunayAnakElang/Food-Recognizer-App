class NutritionInfo {
  final double calories;
  final double carbohydrates;
  final double fat;
  final double fiber;
  final double protein;

  NutritionInfo({
    required this.calories,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.protein,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      calories: _parseDouble(json['calories']),
      carbohydrates: _parseDouble(json['carbohydrates']),
      fat: _parseDouble(json['fat']),
      fiber: _parseDouble(json['fiber']),
      protein: _parseDouble(json['protein']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleanValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleanValue) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'protein': protein,
    };
  }
}