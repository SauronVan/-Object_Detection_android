import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ai_object_detector/controller/scan_controller.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'dart:developer';

class CameraViewWithVoice extends StatefulWidget {
  const CameraViewWithVoice({Key? key}) : super(key: key);

  @override
  _CameraViewWithVoiceState createState() => _CameraViewWithVoiceState();
}

class _CameraViewWithVoiceState extends State<CameraViewWithVoice> {
  bool _isSpeaking = false;

  @override
  Widget build(BuildContext context) {
    final ScanController controller = Get.put(ScanController());

    return Scaffold(
      body: Obx(() {
        if (!controller.isCameraInitialized.value) {
          return const Center(child: Text("Loading Preview..."));
        }
        return Stack(
          children: [
            UltralyticsYoloCameraPreview(
              controller: controller.cameraController,
              predictor: controller.objectDetector,
              onCameraCreated: () {},
              boundingBoxesColorList: [Colors.red, Colors.blue, Colors.green],
            ),
            // Process detection results and draw bounding boxes with labels
            Positioned.fill(
              child: StreamBuilder<List<DetectedObject?>?>(
                stream: controller.objectDetector.detectionResultStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const SizedBox.shrink();
                  }

                  // Filter objects with confidence >= 0.4
                  final detectedObjects = snapshot.data!
                      .where((obj) => obj != null && obj.confidence >= 0.4)
                      .cast<DetectedObject>()
                      .toList();

                  // Log detected objects (optional)
                  log("Detected objects: ${detectedObjects.map((e) => e.label)
                      .toList()}");

                  // Update controller with filtered results
                  controller.updateDetectedObjects(detectedObjects.map((obj) =>
                  {
                    'label': obj.label,
                    'confidence': obj.confidence,
                    'boundingBox': {
                      'left': obj.boundingBox.left,
                      'top': obj.boundingBox.top,
                      'width': obj.boundingBox.width,
                      'height': obj.boundingBox.height,
                    },
                  }).toList());

                  // Draw bounding boxes and labels using CustomPaint
                  return CustomPaint(
                    painter: ObjectDetectorPainter(
                      detectedObjects,
                      [Colors.red, Colors.blue, Colors.green],
                    ),
                  );
                },
              ),
            ),
            // Display recognized word and command
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() =>
                      Text(
                        "Target: ${controller.recognizedWord.value}",
                        style: const TextStyle(
                            fontSize: 20, color: Colors.white),
                      )),
                  const SizedBox(height: 10),
                  Obx(() =>
                      Text(
                        "Command: ${controller.recognizedWords.value}",
                        style: const TextStyle(
                            fontSize: 16, color: Colors.white),
                      )),
                ],
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.volume_up),
        onPressed: () => _speakObjects(controller),
      ),
    );
  }

  void _speakObjects(ScanController controller) async {
    if (_isSpeaking) {
      await controller.flutterTts.stop();
      _isSpeaking = false;
    }

    // Use the device's screen width from the context
    final screenWidth = MediaQuery.of(context).size.width;

    // Dividing screen into three equal parts
    final leftBoundary = screenWidth / 3;
    final rightBoundary = 2 * (screenWidth / 3);

    // Regions map
    Map<String, List<String>> regionObjects = {
      "left": [],
      "middle": [],
      "right": [],
    };

    // Classify objects based on their bounding box position
    for (var obj in controller.detectedObjects) {
      if (obj['boundingBox'] == null) continue;

      final bbox = obj['boundingBox'];
      final left = bbox['left'];
      final width = bbox['width'];
      final right = left + width;

      // If the object spans all three regions, assign it to the middle.
      if (left < leftBoundary && right > rightBoundary) {
        regionObjects["middle"]?.add(obj['label']);
      } else {
        // Calculate the portion of the box in each region
        double leftPortion = (right < leftBoundary)
            ? 1.0
            : (left < leftBoundary)
            ? (leftBoundary - left) / width
            : 0.0;

        double rightPortion = (left > rightBoundary)
            ? 1.0
            : (right > rightBoundary)
            ? (right - rightBoundary) / width
            : 0.0;

        double middlePortion = 1.0 - (leftPortion + rightPortion);

        // Determine the dominant region for the object
        if (leftPortion >= middlePortion && leftPortion >= rightPortion) {
          regionObjects["left"]?.add(obj['label']);
        } else if (rightPortion >= leftPortion && rightPortion >= middlePortion) {
          regionObjects["right"]?.add(obj['label']);
        } else {
          regionObjects["middle"]?.add(obj['label']);
        }
      }
    }

    // Construct speech text
    List<String> speechParts = [];

    if (regionObjects["left"]!.isNotEmpty) {
      speechParts.add(
          "${regionObjects["left"]!.join(', ')} ${regionObjects["left"]!.length == 1 ? 'is' : 'are'} on the left");
    }
    if (regionObjects["middle"]!.isNotEmpty) {
      speechParts.add(
          "${regionObjects["middle"]!.join(', ')} ${regionObjects["middle"]!.length == 1 ? 'is' : 'are'} in the middle");
    }
    if (regionObjects["right"]!.isNotEmpty) {
      speechParts.add(
          "${regionObjects["right"]!.join(', ')} ${regionObjects["right"]!.length == 1 ? 'is' : 'are'} on the right");
    }

    if (speechParts.isEmpty) {
      await controller.flutterTts.speak("No objects detected.");
      return;
    }

    final speechText = speechParts.join(". ");
    _isSpeaking = true;

    await controller.flutterTts.speak(speechText).then((_) {
      _isSpeaking = false;
    });
  }
}