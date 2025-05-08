import 'dart:async'; // For Timer
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert'; // For LineSplitter
import 'package:tflite_flutter/tflite_flutter.dart';

// Define your categories in the exact order your model outputs them
const List<String> CATEGORIES = [
  'entertainment', 'food', 'shopping', 'technology', 'transport'
];

// Define the expected input sequence length for your BERT model
const int MAX_SEQ_LENGTH = 128;

class BertTokenizer {
  final Map<String, int> _vocabulary;
  final String _clsToken = '[CLS]';
  final String _sepToken = '[SEP]';
  final String _unkToken = '[UNK]';
  final int _padTokenId;

  BertTokenizer(this._vocabulary) : _padTokenId = _vocabulary['[PAD]'] ?? 0;

  static Future<BertTokenizer> loadVocabulary(String vocabPath) async {
    try {
      print("Attempting to load vocabulary from '$vocabPath'...");
      final String vocabData = await rootBundle.loadString(vocabPath);
      final Map<String, int> vocabulary = {};
      final List<String> lines = LineSplitter.split(vocabData).toList();
      for (int i = 0; i < lines.length; i++) {
        final String token = lines[i].trim();
        if (token.isNotEmpty) {
          vocabulary[token] = i;
        }
      }
      print("Vocabulary loaded from '$vocabPath'. Size: ${vocabulary.length}");
      if (!vocabulary.containsKey('[PAD]')) print("Warning: [PAD] token not found in vocab!");
      if (!vocabulary.containsKey('[UNK]')) print("Warning: [UNK] token not found in vocab!");
      if (!vocabulary.containsKey('[CLS]')) print("Warning: [CLS] token not found in vocab!");
      if (!vocabulary.containsKey('[SEP]')) print("Warning: [SEP] token not found in vocab!");
      return BertTokenizer(vocabulary);
    } catch (e) {
      print("Error loading vocabulary from '$vocabPath': $e");
      rethrow;
    }
  }

  List<String> _basicTokenize(String text) {
    text = text.toLowerCase();
    text = text.replaceAllMapped(RegExp(r'([,.!?()])'), (match) => ' ${match.group(1)} ');
    return text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  }

  List<int> _convertToIds(List<String> tokens) {
    return tokens
        .map((token) => _vocabulary[token] ?? _vocabulary[_unkToken]!)
        .toList();
  }

  Map<String, List<int>> encode(String text, {int maxLength = MAX_SEQ_LENGTH}) {
    print("Tokenizing text: '$text'");
    List<String> tokens = _basicTokenize(text);

    if (tokens.length > maxLength - 2) {
      tokens = tokens.sublist(0, maxLength - 2);
    }

    List<int> inputIds = <int>[_vocabulary[_clsToken] ?? _vocabulary[_unkToken]!];
    inputIds.addAll(_convertToIds(tokens));
    inputIds.add(_vocabulary[_sepToken] ?? _vocabulary[_unkToken]!);

    List<int> attentionMask = List.filled(inputIds.length, 1, growable: true);

    int paddingLength = maxLength - inputIds.length;
    if (paddingLength > 0) {
      inputIds.addAll(List.filled(paddingLength, _padTokenId));
      attentionMask.addAll(List.filled(paddingLength, 0));
    }

    List<int> tokenTypeIds = List.filled(maxLength, 0);

    print("Encoded input_ids (first 10): ${inputIds.sublist(0, 10)}");
    print("Encoded attention_mask (first 10): ${attentionMask.sublist(0, 10)}");
    print("Encoded token_type_ids (first 10): ${tokenTypeIds.sublist(0, 10)}");

    return {
      'input_ids': inputIds,
      'attention_mask': attentionMask,
      'token_type_ids': tokenTypeIds,
    };
  }
}

class CategoryPredictionService {
  Interpreter? _interpreter;
  BertTokenizer? _tokenizer;
  bool _isModelLoaded = false;

  // Asset paths
  final String _modelPath = 'assets/models/mobilebert.tflite';
  final String _vocabPath = 'assets/models/vocab.txt';

  CategoryPredictionService() {
    loadModel();
  }

  Future<void> loadModel() async {
    if (_isModelLoaded) {
      print("CategoryPredictionService already loaded, skipping...");
      return;
    }
    try {
      print("Attempting to load vocabulary from: $_vocabPath");
      _tokenizer = await BertTokenizer.loadVocabulary(_vocabPath);

      print("Attempting to load model from: $_modelPath");
      _interpreter = await Interpreter.fromAsset(_modelPath);

      if (_interpreter == null) {
        throw Exception("Interpreter is null after loading model");
      }

      print("Model loaded successfully: ${_interpreter != null}");
      _interpreter!.allocateTensors();
      print("Tensors allocated successfully");

      print('Input tensors:');
      _interpreter!.getInputTensors().asMap().forEach((i, tensor) {
        print('  Input tensor $i: name=${tensor.name}, shape=${tensor.shape}, type=${tensor.type}');
      });
      print('Output tensors:');
      _interpreter!.getOutputTensors().asMap().forEach((i, tensor) {
        print('  Output tensor $i: name=${tensor.name}, shape=${tensor.shape}, type=${tensor.type}');
      });

      _isModelLoaded = true;
      print('TFLite model and tokenizer loaded successfully.');
    } catch (e, stackTrace) {
      print('Failed to load TFLite model or tokenizer: $e');
      print('StackTrace: $stackTrace');
      _isModelLoaded = false;
      if (e.toString().contains("Unable to create interpreter") || e.toString().contains("No such file or directory")) {
        print("CRITICAL: Ensure '$_modelPath' and '$_vocabPath' exist at these exact paths in your assets folder AND are declared in pubspec.yaml.");
      }
    }
  }

  Future<String?> predictCategory(String description) async {
    if (!_isModelLoaded || _interpreter == null || _tokenizer == null) {
      print('Model not loaded or tokenizer not initialized. Attempting to reload...');
      await loadModel();
      if (!_isModelLoaded || _interpreter == null || _tokenizer == null) {
        print('Reload failed. Cannot predict.');
        return null;
      }
    }

    try {
      print("Predicting category for description: '$description'");
      final Map<String, List<int>> encodedInput = _tokenizer!.encode(description);

      final inputIds = [encodedInput['input_ids']!];
      final attentionMask = [encodedInput['attention_mask']!];
      final tokenTypeIds = [encodedInput['token_type_ids']!];

      int expectedInputNum = _interpreter!.getInputTensors().length;
      List<Object> inputs;

      if (expectedInputNum == 3) {
        inputs = [attentionMask, inputIds, tokenTypeIds];
      } else if (expectedInputNum == 1) {
        inputs = [inputIds];
      } else {
        print("Error: Unexpected number of input tensors: $expectedInputNum. Check your model via Netron or TF Lite visualizer.");
        return null;
      }

      final outputShape = _interpreter!.getOutputTensors()[0].shape;
      var output = List.generate(outputShape[0], (_) => List.filled(outputShape[1], 0.0));

      print("Running inference...");
      _interpreter!.runForMultipleInputs(inputs, {0: output});

      List<double> probabilities = (output as List<List<double>>)[0];
      print("Inference output probabilities: $probabilities");

      double maxProb = -1.0;
      int predictedIndex = -1;

      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          predictedIndex = i;
        }
      }

      if (predictedIndex != -1 && predictedIndex < CATEGORIES.length) {
        String predictedCategory = CATEGORIES[predictedIndex];
        print("Input: '$description' -> Predicted category: $predictedCategory, Confidence: $maxProb");
        switch (predictedCategory) {
          case 'food':
            return 'Food';
          case 'transport':
            return 'Transportation';
          case 'shopping':
            return 'Shopping';
          case 'entertainment':
            return 'Entertainment';
          case 'technology':
            return 'Other';
          default:
            return 'Other';
        }
      } else {
        print("Failed to predict category. Index: $predictedIndex, Prob: $maxProb. Output array: $probabilities. Ensure CATEGORIES list matches model output size (${probabilities.length}).");
        return null;
      }
    } catch (e, stackTrace) {
      print('Error during prediction for "$description": $e');
      print('StackTrace: $stackTrace');
      return null;
    }
  }

  void dispose() {
    print("Disposing CategoryPredictionService...");
    _interpreter?.close();
    _isModelLoaded = false;
  }
}
