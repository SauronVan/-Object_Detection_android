import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:oh/main.dart';

class TermsPage extends StatefulWidget {
  const TermsPage({super.key});

  @override
  _TermsPageState createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> with WidgetsBindingObserver {
  ScrollController _scrollController = ScrollController();
  bool _isAtBottom = false;
  FlutterTts _flutterTts = FlutterTts();

  @override

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _flutterTts.setLanguage("en-US");
    _flutterTts.setSpeechRate(0.5);
    _readTerms();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _flutterTts.stop();
    } else if (state == AppLifecycleState.resumed) {
      _readTerms();
    }
  }

  void _scrollListener() {
    setState(() {
      _isAtBottom = _scrollController.position.pixels == _scrollController.position.maxScrollExtent;
    });
  }

  Future<void> _readTerms() async {
    await _flutterTts.speak(
        "By using Oh, you agree to the following terms of use. "
            "This app is designed to only assist users with object detection and environmental description. "
            "Oh is not always accurate and could misidentify objects or surroundings. "
            "Use with caution and do not depend or rely on Oh for information about your surroundings. "
            "It should not be used in situations where safety or health could be at risk. The app should not be used as any form of mobility device. "
            "The user is responsible for assessing the conditions in which Oh is used and understanding the functionalities of Oh app. "
            "No data is collected, and your privacy is respected and protected. "
            "The developer is not responsible for any accidents or injuries that occur while using the app or any misuse of the app's features. "
            "By accepting the terms of use, you acknowledge and agree to these conditions. "
            "Hope you have an enjoyable time using the app."
    );
  }

  Future<void> _acceptTerms(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('accepted_terms', true);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainMenu()));
  }

  Future<void> _cancel(BuildContext context) async {
    await _flutterTts.stop();
    SystemNavigator.pop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flutterTts.stop();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Terms and Conditions")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Text(
                  "By using Oh, you agree to the following terms of use.\n\n"
                      "This app is designed to only assist users with object detection and environmental description. "
                      "Oh is not always accurate and could misidentify objects or surroundings. "
                      "Use with caution and do not depend or rely on Oh for information about your surroundings. "
                      "It should not be used in situations where safety or health could be at risk. The app should not be used as any form of mobility device. "
                      "The user is responsible for assessing the conditions in which Oh is used and understanding the functionalities of the Oh app.\n\n"
                      "No data is collected, and your privacy is respected and protected.\n\n"
                      "The developer is not responsible for any accidents or injuries that occur while using the app or any misuse of the app's features.\n\n"
                      "By accepting the terms of use, you acknowledge and agree to these conditions.\n\n"
                      "Hope you have an enjoyable time using the app!",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isAtBottom ? () => _acceptTerms(context) : null,
              child: const Text("I Accept"),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _cancel(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
