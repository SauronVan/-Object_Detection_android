import 'package:ai_object_detector/view/camera_view.dart';
import 'package:ai_object_detector/view/detect_view.dart'; // Import Detect View
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
            // "Find Object" Button (500x100)
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
            // "Naming Object" Button (500x100)
            SizedBox(
              width: 500,
              height: 100,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 28),
                ),
                onPressed: () {
                  // Navigate to Detect View (Renamed to CameraViewWithRegionsAndVoice)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CameraDetectWithBackButton(),
                    ),
                  );
                },
                child: const Text("Naming Object"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Camera View with Back Button on Top
class CameraViewWithBackButton extends StatelessWidget {
  const CameraViewWithBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const CameraView(), // The existing camera view
          Positioned(
            top: 40, // Adjust position as needed
            left: 20, // Adjust position as needed
            child: FloatingActionButton(
              onPressed: () {
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
          const CameraViewWithVoice(), // The existing camera view
          Positioned(
            top: 40, // Adjust position as needed
            left: 20, // Adjust position as needed
            child: FloatingActionButton(
              onPressed: () {
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