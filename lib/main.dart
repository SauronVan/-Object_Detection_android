import 'package:ai_object_detector/view/camera_view.dart';
import 'package:ai_object_detector/view/detect_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ai_object_detector/controller/scan_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AI Object Detection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainMenu(),
    );
  }
}

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Main Menu"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 500,
              height: 100,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 28),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CameraViewWithBackButton(),
                    ),
                  );
                },
                child: const Text("Find Object"),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 500,
              height: 100,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 28),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CameraDetectWithBackButton(),
                    ),
                  );
                },
                child: const Text("Describe Environment"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CameraViewWithBackButton extends StatelessWidget {
  const CameraViewWithBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const CameraView(),
          Positioned(
            top: 40,
            left: 20,
            child: FloatingActionButton(
              onPressed: () {
                // Clear target before returning
                final scanController = Get.find<ScanController>();
                scanController.clearTarget();
                Navigator.pop(context);
              },
              backgroundColor: Colors.black.withOpacity(0.5),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class CameraDetectWithBackButton extends StatelessWidget {
  const CameraDetectWithBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const CameraViewWithVoice(),
          Positioned(
            top: 40,
            left: 20,
            child: FloatingActionButton(
              onPressed: () {
                // Clear target before returning
                final scanController = Get.find<ScanController>();
                scanController.clearTarget();
                Navigator.pop(context);
              },
              backgroundColor: Colors.black.withOpacity(0.5),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
