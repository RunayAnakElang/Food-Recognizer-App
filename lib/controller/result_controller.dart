import 'dart:io';
import 'package:flutter/material.dart';
import 'package:submission/services/classifier_service.dart';
import 'package:submission/services/gemini_service.dart';

enum ResultState { loading, success, error }

class ResultController extends ChangeNotifier {
  final ImageClassificationService _classifierService = ImageClassificationService();
  final GeminiService _geminiService = GeminiService();

  ResultState _state = ResultState.loading;
  String _foodName = '';
  String _confidence = '';
  String _errorMessage = '';
  NutritionalInfo? _nutritionalInfo;
  bool _isLoadingNutrition = false;

  ResultState get state => _state;
  String get foodName => _foodName;
  String get confidence => _confidence;
  String get errorMessage => _errorMessage;
  NutritionalInfo? get nutritionalInfo => _nutritionalInfo;
  bool get isLoadingNutrition => _isLoadingNutrition;

  Future<void> classifyImage(File imageFile) async {
    _state = ResultState.loading;
    _nutritionalInfo = null;
    _isLoadingNutrition = false;
    notifyListeners();

    try {
      await _classifierService.init();
      final result = await _classifierService.classify(imageFile);

      _foodName = result['name'] ?? 'Unknown';
      _confidence = result['confidence'] ?? '0%';

      if (_foodName.startsWith('Error')) {
        _state = ResultState.error;
        _errorMessage = _foodName;
      } else {
        _state = ResultState.success;
      }
    } catch (e) {
      _errorMessage = 'Failed to classify image: $e';
      _state = ResultState.error;
      debugPrint(_errorMessage);
    }

    notifyListeners();
  }

  Future<void> fetchNutritionalInfo() async {
    if (_foodName.toLowerCase() == 'not food' || _foodName.toLowerCase() == 'unknown' || _nutritionalInfo != null) {
      return;
    }

    _isLoadingNutrition = true;
    notifyListeners();

    try {
      final info = await _geminiService.getNutritionalInfo(_foodName);
      _nutritionalInfo = info;
    } catch (e) {
      debugPrint('Error fetching nutrition: $e');
      _nutritionalInfo = null;
    } finally {
      _isLoadingNutrition = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _classifierService.dispose();
    super.dispose();
  }

}