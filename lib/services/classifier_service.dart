import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ImageClassificationService {
  late Interpreter _interpreter;
  late List<String> _labels;
  late Uint8List _modelData;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      debugPrint('Loading TFLite model...');

      final modelAsset = await rootBundle.load('assets/food_classifier.tflite');
      _modelData = modelAsset.buffer.asUint8List();

      _interpreter = await Interpreter.fromAsset(
        'assets/food_classifier.tflite',
      );

      _labels = await _loadLabels();

      final inputShape = _interpreter.getInputTensor(0).shape;
      final outputShape = _interpreter.getOutputTensor(0).shape;

      debugPrint('Model loaded successfully');
      debugPrint('Input shape: $inputShape');
      debugPrint('Output shape: $outputShape');
      debugPrint('Number of labels: ${_labels.length}');

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing model: $e');
      rethrow;
    }
  }

  Future<List<String>> _loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      final labels = labelsData
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      debugPrint('Loaded ${labels.length} labels');
      return labels;
    } catch (e) {
      debugPrint('Error loading labels: $e');
      rethrow;
    }
  }

  Future<Map<String, String>> classify(File imageFile) async {
    if (!_isInitialized) {
      throw Exception('Model not initialized. Call init() first.');
    }

    try {
      debugPrint('Starting classification in isolate...');

      final preprocessedInput = await _preprocessImage(imageFile);

      final result = await _runInferenceInIsolate(preprocessedInput);

      return result;
    } catch (e, stackTrace) {
      debugPrint('Error during classification: $e');
      debugPrint('Stack trace: $stackTrace');

      return {'name': 'Error: ${e.toString()}', 'confidence': '0%'};
    }
  }

  Future<List<List<List<List<int>>>>> _preprocessImage(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    debugPrint('Image decoded: ${image.width}x${image.height}');

    final resizedImage = img.copyResize(
      image,
      width: 192,
      height: 192,
      interpolation: img.Interpolation.linear,
    );

    debugPrint('Image resized to 192x192');

    var input = List.generate(
      1,
          (_) => List.generate(
        192,
            (y) => List.generate(192, (x) {
          final pixel = resizedImage.getPixel(x, y);
          return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
        }),
      ),
    );

    return input;
  }

  Future<Map<String, String>> _runInferenceInIsolate(
      List<List<List<List<int>>>> input,
      ) async {
    final receivePort = ReceivePort();

    final isolateData = _IsolateData(
      sendPort: receivePort.sendPort,
      modelData: _modelData,
      input: input,
      labels: _labels,
    );

    await Isolate.spawn(_isolateInference, isolateData);

    final result = await receivePort.first as Map<String, String>;
    return result;
  }

  static Future<void> _isolateInference(_IsolateData data) async {
    try {
      final interpreter = Interpreter.fromBuffer(data.modelData);

      debugPrint('[Isolate] Running inference...');

      var output = List.filled(
        data.labels.length,
        0,
      ).reshape([1, data.labels.length]);

      interpreter.run(data.input, output);

      debugPrint('[Isolate] Inference completed');

      final probabilities = output[0];

      int maxProb = probabilities[0] as int;
      int maxIndex = 0;

      for (int i = 1; i < probabilities.length; i++) {
        int prob = probabilities[i] as int;
        if (prob > maxProb) {
          maxProb = prob;
          maxIndex = i;
        }
      }

      double maxProbPercent = (maxProb / 255.0) * 100.0;

      String label = data.labels[maxIndex];

      debugPrint(
        '[Isolate] Top prediction: $label with ${maxProbPercent.toStringAsFixed(2)}%',
      );

      if (label == '__background__' ||
          label.startsWith('/g/') ||
          maxProbPercent < 30) {
        label = 'not food';
      }

      final confidence = '${maxProbPercent.toStringAsFixed(1)}%';

      interpreter.close();

      data.sendPort.send({'name': label, 'confidence': confidence});
    } catch (e) {
      debugPrint('[Isolate] Error: $e');
      data.sendPort.send({
        'name': 'Error in isolate: ${e.toString()}',
        'confidence': '0%',
      });
    }
  }

  void dispose() {
    if (_isInitialized) {
      _interpreter.close();
      _isInitialized = false;
      debugPrint('Model disposed');
    }
  }
}

class _IsolateData {
  final SendPort sendPort;
  final Uint8List modelData;
  final List<List<List<List<int>>>> input;
  final List<String> labels;

  _IsolateData({
    required this.sendPort,
    required this.modelData,
    required this.input,
    required this.labels,
  });
}