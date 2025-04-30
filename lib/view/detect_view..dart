import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oh/controller/scan_controller.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

class CameraViewWithVoice extends StatefulWidget {
  const CameraViewWithVoice({Key? key}) : super(key: key);

  @override
  _CameraViewWithVoiceState createState() => _CameraViewWithVoiceState();
}

class _CameraViewWithVoiceState extends State<CameraViewWithVoice> {
  final ScanController controller = Get.put(ScanController());

  bool _isSpeaking = false;
  bool _isDetecting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (!controller.isCameraInitialized.value) {
          return const Center(child: Text("Loading Preview..."));
        }

        return Stack(
          children: [
            UltralyticsYoloCameraPreview(
              controller: controller.cameraController,
              predictor: _isDetecting ? controller.objectDetector : null,
              onCameraCreated: () {},
              boundingBoxesColorList: [Colors.red, Colors.blue, Colors.green],
            ),
            if (_isDetecting)
              Positioned.fill(
                child: StreamBuilder<List<DetectedObject?>?>(
                  stream: controller.objectDetector.detectionResultStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data == null) {
                      return const SizedBox.shrink();
                    }

                    final detected = snapshot.data!
                        .where((d) => d != null && d.confidence >= 0.4)
                        .cast<DetectedObject>()
                        .toList();

                    log("Detected objects: ${detected.map((e) => e.label).toList()}");

                    controller.updateDetectedObjects(
                      detected.map((obj) => {
                        'label': obj.label,
                        'confidence': obj.confidence,
                        'boundingBox': {
                          'left': obj.boundingBox.left,
                          'top': obj.boundingBox.top,
                          'width': obj.boundingBox.width,
                          'height': obj.boundingBox.height,
                        },
                      }).toList(),
                    );

                    return CustomPaint(
                      painter: ObjectDetectorPainter(
                        detected,
                        [Colors.red, Colors.blue, Colors.green],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      }),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.volume_up),
        onPressed: () async {
          // Clear previous state
          controller.clearTarget();
          controller.updateDetectedObjects([]);
          if (_isSpeaking) {
            await controller.flutterTts.stop();
            _isSpeaking = false;
          }
          setState(() => _isDetecting = true);
          await Future.delayed(const Duration(milliseconds: 500));
          final rawDetection = await controller.objectDetector.detectionResultStream
              .firstWhere((list) => list != null && list.isNotEmpty);
          final detection = rawDetection!;
          final filtered = detection
              .where((obj) => obj != null && obj.confidence >= 0.3)
              .cast<DetectedObject>()
              .toList();
          controller.updateDetectedObjects(
            filtered.map((obj) => {
              'label': obj.label,
              'confidence': obj.confidence,
              'boundingBox': {
                'left': obj.boundingBox.left,
                'top': obj.boundingBox.top,
                'width': obj.boundingBox.width,
                'height': obj.boundingBox.height,
              },
            }).toList(),
          );

          await _speakObjects(controller);

          setState(() => _isDetecting = false);
          controller.updateDetectedObjects([]);
        },
      ),
    );
  }

  Future<void> _speakObjects(ScanController controller) async {
    if (_isSpeaking) {
      await controller.flutterTts.stop();
      _isSpeaking = false;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final leftBoundary = screenWidth / 3;
    final rightBoundary = 2 * (screenWidth / 3);

    Map<String, Map<String, int>> regionObjects = {
      "left": {},
      "middle": {},
      "right": {},
    };

    for (var obj in controller.detectedObjects) {
      final bbox = obj['boundingBox'] as Map<String, double>?;
      if (bbox == null) continue;

      final left = bbox['left']!;
      final width = bbox['width']!;
      final right = left + width;
      final label = obj['label'] as String;

      String region;
      if (left < leftBoundary && right > rightBoundary) {
        region = "middle";
      } else {
        final leftPortion = (right < leftBoundary)
            ? 1.0
            : (left < leftBoundary)
            ? (leftBoundary - left) / width
            : 0.0;
        final rightPortion = (left > rightBoundary)
            ? 1.0
            : (right > rightBoundary)
            ? (right - rightBoundary) / width
            : 0.0;
        final middlePortion = 1.0 - (leftPortion + rightPortion);

        if (leftPortion >= middlePortion && leftPortion >= rightPortion) {
          region = "left";
        } else if (rightPortion >= leftPortion && rightPortion >= middlePortion) {
          region = "right";
        } else {
          region = "middle";
        }
      }

      regionObjects[region]!
          .update(label, (count) => count + 1, ifAbsent: () => 1);
    }

    final speechParts = <String>[];

    regionObjects.forEach((region, objs) {
      if (objs.isEmpty) return;
      final descs = objs.entries
          .map((e) => e.value == 1 ? "1 ${e.key}" : "${e.value} ${e.key}s")
          .join(', ');
      final regionText = {
        "left": "on the left",
        "middle": "in the middle",
        "right": "on the right",
      }[region]!;
      speechParts.add("${descs} ${regionText}");
    });

    if (speechParts.isEmpty) {
      await controller.flutterTts.speak("No objects detected.");
      return;
    }

    _isSpeaking = true;
    await controller.flutterTts
        .speak(speechParts.join('. '))
        .then((_) => _isSpeaking = false);
  }
}
