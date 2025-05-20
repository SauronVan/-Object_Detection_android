import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:oh/controller/scan_controller.dart';
import 'package:oh/view/camera_view.dart';
import 'package:oh/view/detect_view..dart';
import 'package:oh/Instruction/Instruction.dart';
import 'package:oh/Instruction/termsandcondition.dart';
import 'package:oh/Instruction/Supported_class.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _hasAcceptedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('accepted_terms') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasAcceptedTerms(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return GetMaterialApp(
          title: 'AI Object Detection',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: snapshot.data! ? const MainMenu() : const TermsPage(),
        );
      },
    );
  }
}

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  final FlutterTts flutterTts = FlutterTts();

  void _showSupportedClasses() async {
    List<String> classes = await SupportedClass.loadLabels();

    String textToSpeak = "Nhóm đối tượng hỗ trợ: \n" + classes.join(", ");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: _SupportedClassPopup(
          paragraph: textToSpeak,
        ),
      ),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Màn Hình Chính"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.category, color: Colors.black, size: 30),
              tooltip: 'Supported Classes',
              onPressed: _showSupportedClasses,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.black, size: 40),
              onPressed: () {
                Instruction.showParagraphPopup(
                  context,
                  paragraph: "Hướng dẫn sử dụng: \n\n"
                      "Nhấn Tìm Vật để tìm một vật thể. "
                      "Nhận dạng giọng nói sẽ bắt đầu. "
                      "Hỏi những câu như tìm chai nước hoặc hãy chỉ tôi chỗ cái ghế  "
                      "Xoay camera xung quanh để bắt đầu nhận dạng. "
                      "Điện thoại sẽ rung khi tìm thấy vật và sẽ rung mạnh hơn khi đến gần vật. "
                      "Bạn cũng có thể chọn tính năng Xung Quanh để mô tả những gì camera nhìn thấy. "
                      "Nhấn biểu tượng loa để nghe mô tả môi trường qua trái, giữa hoặc phải. "
                      "Nhấn nút quay lại để trở về màn hình chính.",
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
                style: ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 28)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CameraViewWithBackButton()),
                  );
                },
                child: const Text("Tìm vật thể"),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 500,
              height: 100,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 28)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CameraDetectWithBackButton()),
                  );
                },
                child: const Text("Mô tả xung quanh"),
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

class _SupportedClassPopup extends StatefulWidget {
  final String paragraph;

  const _SupportedClassPopup({Key? key, required this.paragraph}) : super(key: key);

  @override
  State<_SupportedClassPopup> createState() => _SupportedClassPopupState();
}

class _SupportedClassPopupState extends State<_SupportedClassPopup> {
  late FlutterTts flutterTts;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    _speak();
  }

  Future<void> _speak() async {
    await flutterTts.setLanguage("vi-VN");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(widget.paragraph);
  }

  Future<void> _stopSpeaking() async {
    await flutterTts.stop();
  }

  @override
  void dispose() {
    _stopSpeaking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400, maxWidth: 350),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  await _stopSpeaking();
                  Navigator.of(context).pop();
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  child: Text(
                    widget.paragraph.replaceAll(",", "\n"),
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
