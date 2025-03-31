import 'dart:io';
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

  // Observable states
  final isCameraInitialized = false.obs;
  final recognizedWord = "".obs;
  final recognizedWords = "".obs;
  final labels = <String>[].obs;
  final detectedObjects = <Map<String, dynamic>>[].obs;
  final isSpeechInitialized = false.obs;
  final isRecording = false.obs;

  // Model asset paths and formats based on platform.
  late final String modelFilePath;
  late final Format modelFormat;
  final String metadataFilePath = 'assets/metadata.yaml';
  final String labelsFilePath = 'assets/labels.txt';

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
    // Request camera and microphone permissions.
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
    // Determine model asset and format based on platform.
    if (Platform.isIOS) {
      modelFilePath = 'assets/yolov8n.mlmodel';
      modelFormat = Format.coreml;
    } else {
      modelFilePath = 'assets/yolov8n_int8.tflite';
      modelFormat = Format.tflite;
    }

    cameraController = UltralyticsYoloCameraController();

    try {
      // Copy model asset (and metadata if needed) to an accessible file path.
      final modelPath = await _copyAssetToFile(modelFilePath);
      Get.log("Model copied to: $modelPath");

      String? metadataPath;
      if (!Platform.isIOS) {
        metadataPath = await _copyAssetToFile(metadataFilePath);
      }

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
            // Optionally restart listening if needed.
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
        if (recognizedText.isNotEmpty) {
          final lastWord = recognizedText.split(" ").last;
          if (labels.contains(lastWord)) {
            recognizedWord.value = lastWord;
            flutterTts.speak(lastWord);
            checkForMatchingBbox();
          }
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 2),
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

    final matchFound = detectedObjects.any((obj) =>
    (obj['label'] as String).trim().toLowerCase() == target);

    if (matchFound && await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 500);
    }
  }

  void clearTarget() {
    recognizedWord.value = "";
  }
}
