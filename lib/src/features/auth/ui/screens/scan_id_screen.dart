import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class ScanIDScreen extends StatefulWidget {
  const ScanIDScreen({super.key});

  @override
  State<ScanIDScreen> createState() => _ScanIDScreenState();
}

class _ScanIDScreenState extends State<ScanIDScreen> {
  bool _scanning = false;

  Future<void> _scanID() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return;

    setState(() => _scanning = true);

    final input = InputImage.fromFilePath(image.path);
    final textRecognizer = TextRecognizer();

    final result = await textRecognizer.processImage(input);
    final rawText = result.text;

    // ---------- Extract Data ----------
    final extracted = {
      "name": _extractName(rawText),
      "usn": _extractUSN(rawText),
      "batch": _extractBatch(rawText),
      "institution": _extractInstitution(rawText),
    };

    textRecognizer.close();

    Navigator.pop(context, extracted);
  }

  // --------- EXTRACTORS ----------
  String _extractName(String text) {
    final lines = text.split("\n");
    return lines.firstWhere(
          (line) => line.contains(RegExp(r"[A-Za-z]+")),
      orElse: () => "Unknown Name",
    );
  }

  String _extractUSN(String text) {
    final match = RegExp(r"\b[A-Za-z0-9]{6,12}\b").firstMatch(text);
    return match?.group(0) ?? "Unknown USN";
  }

  String _extractBatch(String text) {
    final match = RegExp(r"\b(20\d{2})\b").firstMatch(text);
    return match?.group(0) ?? "N/A";
  }

  String _extractInstitution(String text) {
    final inst = RegExp(r"(College|University|Institute).+", caseSensitive: false)
        .firstMatch(text);
    return inst?.group(0) ?? "Unknown Institution";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan ID Card")),
      body: Center(
        child: _scanning
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
          icon: const Icon(Icons.camera_alt),
          label: const Text("Capture ID"),
          onPressed: _scanID,
        ),
      ),
    );
  }
}
