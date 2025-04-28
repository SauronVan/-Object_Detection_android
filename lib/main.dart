import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oh/controller/scan_controller.dart';
import 'package:oh/view/camera_view.dart';
import 'package:oh/view/detect_view..dart';
import 'package:oh/Instruction/Instruction.dart'; // <-- NEW import

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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0), // add small padding from edge
            child: IconButton(
              icon: const Icon(
                Icons.help_outline,
                color: Colors.black,      // <-- BLACK color
                size: 32,                 // <-- Bigger size
              ),
              onPressed: () {
                Instruction.showParagraphPopup(
                  context,
                  paragraph: "Welcome to Oh. "
                      "Press Find Object to locate an item. "
                      "Say commands like find me a bottle or  "
                      "where is the chair. Point the camera and  "
                      "press the play button. Voice recognition will "
                      "start.  Your phone will vibrate as you get "
                      "closer. Or press What's Around. "
                      "The app will describe what the camera sees. "
                      "Press the speaker button to hear it. "
                      "Find out what's on the left, center, or right. "
                      "Tap the back arrow to return to the menu.",
                );
              },
            ),
          ),
        ],
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
                child: const Text("What's Around"),
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
