import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oh/main.dart';


class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 300), _speakTutorial);
  }

  Future<void> _speakTutorial() async {
    await _flutterTts.setLanguage("vi-VN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(
      "Hướng dẫn sử dụng"
          "Nhấn Tìm Vật để tìm một vật thể. "
          "Nhận dạng giọng nói sẽ bắt đầu. "
          "Hỏi những câu như tìm chai nước hoặc hãy chỉ tôi chỗ cái ghế "
          "Xoay camera xung quanh để bắt đầu nhận dạng. "
          "Điện thoại sẽ rung khi tìm thấy vật và sẽ rung mạnh hơn khi đến gần vật. "
          "Bạn cũng có thể chọn tính năng Xung Quanh để mô tả những gì camera nhìn thấy. "
          "Nhấn biểu tượng loa để nghe mô tả môi trường qua trái, giữa hoặc phải. "
          "Nhấn nút quay lại để trở về màn hình chính.",
    );
  }


  Future<void> _continueToMain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('shown_tutorial', true);
    await _flutterTts.stop();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainMenu()),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hướng Dẫn Sử Dụng")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  "Chào mừng bạn đến với Oh!\n\n"
                      "Nhấn Tìm Vật để tìm một vật thể. \n\n"
                      "Nhận dạng giọng nói sẽ bắt đầu. \n\n"
                      "Hỏi những câu như tìm chai nước hoặc ghế ở đâu. \n\n"
                      "Xoay camera xung quanh để bắt đầu nhận dạng. \n\n"
                      "Điện thoại sẽ rung khi tìm thấy vật và sẽ rung mạnh hơn khi đến gần vật. \n\n"
                      "Bạn cũng có thể chọn tính năng Xung Quanh để mô tả những gì camera nhìn thấy. \n\n"
                      "Nhấn biểu tượng loa để nghe mô tả môi trường qua trái, giữa hoặc phải. \n\n"
                      "Nhấn nút quay lại để trở về màn hình chính.\n\n",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _continueToMain,
              child: const Text("Tiếp tục"),
            ),
          ],
        ),
      ),
    );
  }
}

