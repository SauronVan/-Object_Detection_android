import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'package:ultralytics_yolo/yolo_model.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;
import 'package:path/path.dart';
import 'package:vibration/vibration.dart';

class ScanController extends GetxController {
  late UltralyticsYoloCameraController cameraController;
  late stt.SpeechToText speech;
  late FlutterTts flutterTts;
  late ObjectDetector objectDetector;

  var isCameraInitialized = false.obs;
  var recognizedWord = "".obs;
  var recognizedWords = "".obs;
  var labels = <String>[].obs;
  var detectedObjects = <Map<String, dynamic>>[].obs;
  var isSpeechInitialized = false.obs;
  var isRecording = false.obs;
  final String modelFilePath = 'assets/yolov8n_int8.tflite';
  final String metadataFilePath = 'assets/metadata.yaml';
  final String labelsFilePath = 'assets/labels.txt';

  @override
  void onInit() {
    super.onInit();
    initCameraAndDetector();
    initSpeechToText();
    initTextToSpeech();
    loadLabels();
  }

  @override
  void dispose() {
    speech.stop();
    cameraController.dispose();
    super.dispose();
  }

  Future<void> initCameraAndDetector() async {
    if (await Permission.camera.request().isGranted) {
      cameraController = UltralyticsYoloCameraController();
      final modelPath = await _copy(modelFilePath);
      final metadataPath = await _copy(metadataFilePath);
      final model = LocalYoloModel(
        id: '',
        task: Task.detect,
        format: Format.tflite,
        modelPath: modelPath,
        metadataPath: metadataPath,
      );
      objectDetector = ObjectDetector(model: model);
      await objectDetector.loadModel(useGpu: true);

      _listenToDetectionResults();

      isCameraInitialized(true);
      update();
    }
  }

  Future<String> _copy(String assetPath) async {
    final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
    await io.Directory(dirname(path)).create(recursive: true);
    final file = io.File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(
          byteData.buffer.asUint8List(
              byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }

  void _listenToDetectionResults() {
    objectDetector.detectionResultStream.listen((results) {
      if (results != null && results.isNotEmpty) {
        final detected = results
            .where((obj) => obj != null)
            .map((obj) => {
          'label': obj!.label,
          'confidence': obj.confidence,
          'boundingBox': {
            'left': obj.boundingBox.left,
            'top': obj.boundingBox.top,
            'width': obj.boundingBox.width,
            'height': obj.boundingBox.height,
          },
        })
            .toList();
        updateDetectedObjects(detected);
      } else {
        updateDetectedObjects([]);
      }
    }, onError: (error) {});
  }

  Future<void> initSpeechToText() async {
    speech = stt.SpeechToText();
    if (await Permission.microphone.request().isGranted) {
      bool initialized = await speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {}
        },
        onError: (error) {
          isSpeechInitialized(false);
          Future.delayed(const Duration(seconds: 1), startListening);
        },
      );
      if (initialized) {
        isSpeechInitialized(true);
      } else {
        isSpeechInitialized(false);
      }
    } else {
      isSpeechInitialized(false);
    }
  }

  void initTextToSpeech() {
    flutterTts = FlutterTts();
  }

  Future<void> startListening() async {
    if (!isSpeechInitialized.value) {
      await initSpeechToText();
      if (!isSpeechInitialized.value) {
        return;
      }
    }

    if (speech.isListening) {
      return;
    }

    bool available = await speech.listen(
      onResult: (result) {
        String recognizedText = result.recognizedWords.trim().toLowerCase();
        recognizedWords.value = recognizedText;

        String lastWord = recognizedText.split(" ").last;

        if (labels.contains(lastWord)) {
          recognizedWord.value = lastWord;
          flutterTts.speak(lastWord);
          checkForMatchingBbox();
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
      labels.addAll(labelList);
    } catch (e) {}
  }

  void updateDetectedObjects(List<Map<String, dynamic>> objects) {
    detectedObjects.assignAll(objects);
    checkForMatchingBbox();
  }

  Future<void> checkForMatchingBbox() async {
    if (recognizedWord.value.isEmpty) {
      return;
    }

    if (detectedObjects.isEmpty) {
      return;
    }

    bool matchFound = false;
    for (var obj in detectedObjects) {
      final label = obj['label']?.toString().toLowerCase().trim();
      if (label == recognizedWord.value) {
        matchFound = true;
        break;
      }
    }

    if (matchFound && await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 500);
    }
  }

  void clearTarget() {
    recognizedWord.value = "";
  }
}
