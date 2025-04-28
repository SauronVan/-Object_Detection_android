import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class Instruction {
  static void showParagraphPopup(BuildContext context, {required String paragraph}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: _ParagraphPopup(paragraph: paragraph),
      ),
    );
  }
}

class _ParagraphPopup extends StatefulWidget {
  final String paragraph;

  const _ParagraphPopup({Key? key, required this.paragraph}) : super(key: key);

  @override
  State<_ParagraphPopup> createState() => _ParagraphPopupState();
}

class _ParagraphPopupState extends State<_ParagraphPopup> {
  late FlutterTts flutterTts;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    _startSpeaking();
  }

  Future<void> _startSpeaking() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(widget.paragraph);
  }

  Future<void> _stopSpeaking() async {
    await flutterTts.stop();
  }

  @override
  void dispose() {
    _stopSpeaking();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              widget.paragraph,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async {
                await _stopSpeaking();
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
