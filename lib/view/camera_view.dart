import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ai_object_detector/controller/scan_controller.dart'; // Adjust path as needed
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'dart:developer';

class CameraView extends StatelessWidget {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ScanController());

    return Scaffold(
      body: Obx(() => controller.isCameraInitialized.value
          ? Stack(
        children: [
          UltralyticsYoloCameraPreview(
            controller: controller.cameraController,
            predictor: controller.objectDetector,
            onCameraCreated: () {
            },
            boundingBoxesColorList: [Colors.red, Colors.blue, Colors.green],
          ),
          StreamBuilder<List<DetectedObject?>?>(
            stream: controller.objectDetector.detectionResultStream,
            builder: (context, snapshot) {
              if (!controller.isRecording.value) {
                return const SizedBox.shrink(); // Hide bounding boxes when not recording
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return const SizedBox.shrink();
              }

              final detectedObjects = snapshot.data!
                  .where((obj) => obj != null && obj.confidence >= 0.4)
                  .cast<DetectedObject>()
                  .toList();

              log("🎨 StreamBuilder received: ${detectedObjects.map((e) => e.label).toList()}");

              controller.updateDetectedObjects(detectedObjects.map((obj) => {
                'label': obj.label,
                'confidence': obj.confidence,
                'boundingBox': {
                  'left': obj.boundingBox.left,
                  'top': obj.boundingBox.top,
                  'width': obj.boundingBox.width,
                  'height': obj.boundingBox.height,
                },
              }).toList());

              return CustomPaint(
                painter: ObjectDetectorPainter(
                  detectedObjects,
                  [Colors.red, Colors.blue, Colors.green],
                ),
              );
            },
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Obx(() => Text(
                  "Target: ${controller.recognizedWord.value}",
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                )),
                const SizedBox(height: 10),
                Obx(() => Text(
                  "Command: ${controller.recognizedWords.value}",
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                )),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Obx(() => IconButton(
                      icon: Icon(
                        controller.isRecording.value ? Icons.stop : Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                        onPressed: () {
                          controller.isRecording.value = !controller.isRecording.value;
                          if (controller.isRecording.value) {
                            controller.startListening();
                          } else {
                            controller.stopListening();
                          }
                        }
                    )),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.white,
                        size: 40,
                      ),
                      onPressed: () {
                        controller.recognizedWord.value = "";
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      )
          : const Center(child: Text("Loading Preview..."))),
    );
  }
}