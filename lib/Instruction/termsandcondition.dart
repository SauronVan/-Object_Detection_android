import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'Tutorial.dart';

class TermsPage extends StatefulWidget {
  const TermsPage({super.key});

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> with WidgetsBindingObserver {
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setLanguage("vi-VN");
    await _flutterTts.setSpeechRate(0.5);
    _readTerms();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _flutterTts.stop();
    } else if (state == AppLifecycleState.resumed) {
      _readTerms();
    }
  }

  Future<void> _readTerms() async {
    await _flutterTts.speak(
      "Bằng cách sử dụng ứng dụng Oh, bạn đồng ý với các điều khoản sử dụng sau. "
          "Ứng dụng này chỉ được thiết kế để hỗ trợ người dùng nhận dạng vật thể và mô tả môi trường. "
          "Oh không hoàn toàn chính xác và có thể nhận dạng sai. "
          "Sử dụng cẩn thận và không phụ thuộc hoàn toàn vào Oh trong tất cả tình huống, đặc biệt là những tình huống liên quan đến an toàn. "
          "Oh không được sử dụng như một thiết bị hỗ trợ di chuyển. "
          "Nhà phát triển sẽ không thu thập dữ liệu và quyền riêng tư của bạn sẽ được tôn trọng. "
          "Nhà phát triển sẽ không chịu trách nhiệm nếu có bất kỳ tai nạn nào xảy ra khi sử dụng Oh. "
          "Bằng cách chọn Tôi chấp nhận, bạn đồng ý với tất cả những điều khoản và quy định trên. "
          "Chúc bạn có trải nghiệm vui vẻ khi sử dụng Oh.",
    );
  }

  Future<void> _acceptTerms(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('accepted_terms', true);
    await prefs.setBool('shown_tutorial', false);

    await _flutterTts.stop();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TutorialPage()),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    await _flutterTts.stop();
    SystemNavigator.pop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Điều khoản và quy định")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: const Text(
                  "Bằng cách sử dụng ứng dụng Oh, bạn đồng ý với các điều khoản sử dụng sau. \n\n"
                      "Ứng dụng này chỉ được thiết kế để hỗ trợ người dùng nhận dạng vật thể và mô tả môi trường. "
                      "Oh không hoàn toàn chính xác và có thể nhận dạng sai. "
                      "Sử dụng cẩn thận và không phụ thuộc hoàn toàn vào Oh trong tất cả tình huống, đặc biệt là những tình huống liên quan đến an toàn. "
                      "Oh không được sử dụng như một thiết bị hỗ trợ di chuyển. \n\n"
                      "Nhà phát triển sẽ không thu thập dữ liệu và quyền riêng tư của bạn sẽ được tôn trọng. "
                      "Nhà phát triển sẽ không chịu trách nhiệm nếu có bất kỳ tai nạn nào xảy ra khi sử dụng Oh. \n\n"
                      "Bằng cách chọn \"Tôi chấp nhận\", bạn đồng ý với tất cả những điều khoản và quy định trên. \n\n"
                      "Chúc bạn có trải nghiệm vui vẻ khi sử dụng Oh.",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _acceptTerms(context),
              child: const Text("Tôi chấp nhận"),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _cancel(context),
              child: const Text("Từ chối", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
