import 'package:flutter/services.dart' show rootBundle;

class SupportedClass {
  static Future<List<String>> loadLabels() async {
    final labelsString = await rootBundle.loadString('assets/labels.txt');
    final lines = labelsString.split('\n');

    return lines.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }
}
