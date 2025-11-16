import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class IdCardScanScreen extends StatefulWidget {
  const IdCardScanScreen({super.key});

  @override
  State<IdCardScanScreen> createState() => _IdCardScanScreenState();
}

class _IdCardScanScreenState extends State<IdCardScanScreen> {
  File? pickedImage;
  bool loading = false;

  final ImagePicker picker = ImagePicker();
  final textRecognizer = TextRecognizer();

  /// 🔥 Very strong USN regex (MOST COLLEGES use these patterns)
  final usnRegex = RegExp(
    r'\b([A-Z0-9]{2,4}[A-Z]{2}[0-9]{2,4})\b',
    caseSensitive: false,
  );

  Future<void> pickAndScan() async {
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);

    if (img == null) return;

    setState(() {
      pickedImage = File(img.path);
      loading = true;
    });

    // ---- OCR ----
    final input = InputImage.fromFile(pickedImage!);
    final result = await textRecognizer.processImage(input);
    final text = result.text;

    print("🔍 OCR OUTPUT:\n$text\n");

    // ----------------------------------------------------
    // 🧠 NAME EXTRACTION
    // ----------------------------------------------------
    String? extractedName;
    List<String> lines = text.split("\n");

    for (String line in lines) {
      if (line.toLowerCase().contains("name")) {
        extractedName = line.replaceAll(RegExp(r"name[: ]*", caseSensitive: false), "").trim();
      }
    }

    // If "name:" missing, fallback to 2-word capitalized name
    extractedName ??= lines.firstWhere(
          (l) => RegExp(r'^[A-Z][a-z]+ [A-Z][a-z]+').hasMatch(l),
      orElse: () => "",
    );

    // ----------------------------------------------------
    // 🔥 USN EXTRACTION (handles multi-line broken OCR)
    // ----------------------------------------------------
    String cleaned = text.replaceAll("\n", " ");

    String? extractedUSN;

    // Try full text first
    final match = usnRegex.firstMatch(cleaned);
    if (match != null) {
      extractedUSN = match.group(0);
    } else {
      // Then try line-by-line
      for (String line in lines) {
        final m = usnRegex.firstMatch(line);
        if (m != null) {
          extractedUSN = m.group(0);
          break;
        }
      }
    }

    extractedUSN = extractedUSN?.toUpperCase();

    // ----------------------------------------------------
    // 📸 Upload Picture to Firebase Storage
    // ----------------------------------------------------
    String? downloadUrl;
    try {
      final ref = FirebaseStorage.instance
          .ref("id_scans/${DateTime.now().millisecondsSinceEpoch}.jpg");

      await ref.putFile(pickedImage!);
      downloadUrl = await ref.getDownloadURL();
    } catch (e) {
      print("🔥 Image upload error: $e");
    }

    // ----------------------------------------------------
    // RETURN SCAN RESULT TO SIGNUP PAGE
    // ----------------------------------------------------
    Navigator.pop(context, {
      "name": extractedName ?? "",
      "usn": extractedUSN ?? "",
      "profilePic": downloadUrl,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan University ID")),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
          icon: const Icon(Icons.photo_library),
          label: const Text("Pick ID From Gallery"),
          onPressed: pickAndScan,
        ),
      ),
    );
  }
}
