
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'package:ultralytics_yolo/yolo_model.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;
import 'package:path/path.dart';
import 'package:vibration/vibration.dart';

class ScanController extends GetxController {
  late UltralyticsYoloCameraController cameraController;
  late stt.SpeechToText speech;
  late FlutterTts flutterTts;
  late ObjectDetector objectDetector;

  int frameCount = 0;

  final isCameraInitialized = false.obs;
  final recognizedWord = "".obs;
  final recognizedWords = "".obs;
  final labels = <String>[].obs;
  final detectedObjects = <Map<String, dynamic>>[].obs;
  final isSpeechInitialized = false.obs;
  final isRecording = false.obs;

  late final String modelFilePath;
  late final Format modelFormat;
  final String metadataFilePath = 'assets/metadata.yaml';
  final String labelsFilePath = 'assets/labels.txt';
  int _consecutiveDetectionCount = 0;
  Map<String, dynamic>? _baseBoundingBox;
  Map<String, dynamic>? _referenceBoundingBox;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void dispose() {
    speech.stop();
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _checkAndRequestPermissions();
    await loadLabels();
    initTextToSpeech();
    await initSpeechToText();
    await initCameraAndDetector();
  }

  Future<void> _checkAndRequestPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (!statuses.values.every((status) => status.isGranted)) {
      Get.snackbar(
        'Permission Error',
        'Camera and microphone permissions are required.',
      );
    }
  }

  Future<void> initCameraAndDetector() async {

    modelFilePath = 'assets/yolov8n_int8.tflite';
    modelFormat = Format.tflite;

    cameraController = UltralyticsYoloCameraController();

    try {
      final modelPath = await _copyAssetToFile(modelFilePath);
      Get.log("Model copied to: $modelPath");

      String? metadataPath;
      metadataPath = await _copyAssetToFile(metadataFilePath);

      final model = LocalYoloModel(
        id: '',
        task: Task.detect,
        format: modelFormat,
        modelPath: modelPath,
        metadataPath: metadataPath,
      );

      objectDetector = ObjectDetector(model: model);
      await objectDetector.loadModel(useGpu: true);

      _listenToDetectionResults();
      isCameraInitialized.value = true;
      update();
    } catch (e) {
      Get.snackbar(
        'Initialization Error',
        'Failed to initialize camera and detector: $e',
      );
    }
  }

  Future<String> _copyAssetToFile(String assetPath) async {
    final directory = await getApplicationSupportDirectory();
    final filePath = '${directory.path}/$assetPath';
    final file = io.File(filePath);

    if (!await file.exists()) {
      try {
        await io.Directory(dirname(filePath)).create(recursive: true);
        final byteData = await rootBundle.load(assetPath);
        await file.writeAsBytes(
          byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          ),
        );
      } catch (e) {
        Get.log('Error copying asset $assetPath: $e');
        rethrow;
      }
    }
    return file.path;
  }

  void _listenToDetectionResults() {
    objectDetector.detectionResultStream.listen(
          (results) {
        frameCount++;
        if (frameCount % 5 != 0) return; // Process every 10th frame.
        if (frameCount > 10000) frameCount = 0; // Reset counter to prevent overflow.

        if (results != null && results.isNotEmpty) {
          final detected = results.map((obj) {
            return {
              'label': obj!.label.toString().toLowerCase().trim(),
              'confidence': obj.confidence,
              'boundingBox': {
                'left': obj.boundingBox.left,
                'top': obj.boundingBox.top,
                'width': obj.boundingBox.width,
                'height': obj.boundingBox.height,
              },
            };
          }).toList();
          updateDetectedObjects(detected);
        } else {
          updateDetectedObjects([]);
        }
      },
      onError: (error) {
        Get.log('Detection stream error: $error');
      },
    );
  }

  Future<void> initSpeechToText() async {
    speech = stt.SpeechToText();
    if (await Permission.microphone.isGranted) {
      bool initialized = await speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
          }
        },
        onError: (error) {
          isSpeechInitialized.value = false;
          Future.delayed(const Duration(seconds: 1), startListening);
        },
      );
      isSpeechInitialized.value = initialized;
    } else {
      isSpeechInitialized.value = false;
    }
  }

  void initTextToSpeech() {
    flutterTts = FlutterTts();
  }

  Future<void> startListening() async {
    if (!isSpeechInitialized.value) {
      await initSpeechToText();
      if (!isSpeechInitialized.value) return;
    }
    if (speech.isListening) return;

    bool available = await speech.listen(
      onResult: (result) {
        final recognizedText = result.recognizedWords.trim().toLowerCase();
        recognizedWords.value = recognizedText;
        if (recognizedText.isEmpty) return;

        final words = recognizedText.split(" ");
        String? target;

        if (words.length >= 3) {
          final lastThree = "${words[words.length - 3]} ${words[words.length - 2]} ${words.last}";
          if (labels.contains(lastThree)) {
            target = lastThree;
          }
        }

        if (target == null && words.length >= 2) {
          final lastTwo = "${words[words.length - 2]} ${words.last}";
          if (labels.contains(lastTwo)) {
            target = lastTwo;
          }
        }

        if (target == null && labels.contains(words.last)) {
          target = words.last;
        }


        if (target != null) {
          if (recognizedWord.value != target) {
            _clearDetectionCache();
          }
          recognizedWord.value = target;
          flutterTts.speak(target);
          checkForMatchingBbox();
        }
      },
      listenFor: const Duration(seconds: 100),
      pauseFor: const Duration(seconds: 20),
    );

    if (!available) {
      Future.delayed(const Duration(seconds: 1), startListening);
    }
  }

  void stopListening() {
    speech.stop();
  }

  Future<void> loadLabels() async {
    try {
      final data = await rootBundle.loadString(labelsFilePath);
      final labelList = data
          .split('\n')
          .map((label) => label.trim().toLowerCase())
          .where((label) => label.isNotEmpty)
          .toList();
      labels.assignAll(labelList);
    } catch (e) {
      Get.log('Error loading labels: $e');
    }
  }

  void updateDetectedObjects(List<Map<String, dynamic>> objects) {
    detectedObjects.assignAll(objects);
    checkForMatchingBbox();
  }

  Future<void> checkForMatchingBbox() async {
    final target = recognizedWord.value;
    if (target.isEmpty || detectedObjects.isEmpty) return;

    final matchingObj = detectedObjects.firstWhere(
          (obj) => (obj['label'] as String) == target,
      orElse: () => {},
    );
    if (matchingObj.isEmpty) return;

    final currentBox = matchingObj['boundingBox'] as Map<String, dynamic>;
    if (_referenceBoundingBox == null) {
      if (_consecutiveDetectionCount == 0) {
        _baseBoundingBox = currentBox;
        _consecutiveDetectionCount = 1;
        return;
      } else {
        if (_isInsideExpanded(currentBox, _baseBoundingBox!)) {
          _consecutiveDetectionCount++;
        } else {
          _baseBoundingBox = currentBox;
          _consecutiveDetectionCount = 1;
        }
        if (_consecutiveDetectionCount >= 3) {
          _referenceBoundingBox = currentBox;
          if (await Vibration.hasVibrator() ?? false) {
            Vibration.vibrate(duration: 500, amplitude: 100);
          }
          return;
        }
      }
    } else {
      if (_isInsideExpanded(currentBox, _referenceBoundingBox!)) {
        double currentArea = currentBox['width'] * currentBox['height'];
        double referenceArea = _referenceBoundingBox!['width'] * _referenceBoundingBox!['height'];
        double ratio = currentArea / referenceArea;

        int duration;
        int amplitude;

        if (ratio < 0.5) {
          duration = 100;
          amplitude = 20;
        } else if (ratio >= 0.5 && ratio < 1) {
          duration = ((ratio - 0.5) * 200 + 100).round();
          amplitude = ((ratio - 0.5) * 50).round();
        } else if (ratio >= 1 && ratio < 2) {
          duration = ((ratio - 1) * 2700 + 300).round();
          amplitude = ((ratio - 1) * 205 + 50).round();
        } else {
          duration = 3000;
          amplitude = 255;
        }

        duration = duration.clamp(10, 3000);
        amplitude = amplitude.clamp(20, 255);


        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: duration, amplitude: amplitude);
        }
      } else {
        _referenceBoundingBox = currentBox;
        _baseBoundingBox = currentBox;
        _consecutiveDetectionCount = 1;
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 500, amplitude: 100);
        }
      }
    }
  }


  bool _isInsideExpanded(Map<String, dynamic> currentBox, Map<String, dynamic> baseBox) {
    double baseCenterX = baseBox['left'] + baseBox['width'] / 2;
    double baseCenterY = baseBox['top'] + baseBox['height'] / 2;
    double expandedHalfWidth = baseBox['width'];
    double expandedHalfHeight = baseBox['height'];
    double expandedLeft = baseCenterX - expandedHalfWidth;
    double expandedTop = baseCenterY - expandedHalfHeight;
    double expandedRight = baseCenterX + expandedHalfWidth;
    double expandedBottom = baseCenterY + expandedHalfHeight;

    double currLeft = currentBox['left'];
    double currTop = currentBox['top'];
    double currRight = currLeft + currentBox['width'];
    double currBottom = currTop + currentBox['height'];

    return (currLeft >= expandedLeft &&
        currTop >= expandedTop &&
        currRight <= expandedRight &&
        currBottom <= expandedBottom);
  }

  void _clearDetectionCache() {
    _baseBoundingBox = null;
    _referenceBoundingBox = null;
    _consecutiveDetectionCount = 0;
  }
  void clearTarget() {
    recognizedWord.value = "";
    _clearDetectionCache();
  }
}
