import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:firebase_storage/firebase_storage.dart';

class IdCardScanScreen extends StatefulWidget {
  const IdCardScanScreen({super.key});

  @override
  State<IdCardScanScreen> createState() => _IdCardScanScreenState();
}

class _IdCardScanScreenState extends State<IdCardScanScreen> {
  File? pickedImage;
  bool loading = false;

  final picker = ImagePicker();
  final textRecognizer = TextRecognizer();
  final barcodeScanner = BarcodeScanner(
    formats: [BarcodeFormat.qrCode, BarcodeFormat.code128, BarcodeFormat.code39],
  );

  // Strong USN regex (VTU + Other colleges)
  final usnRegex = RegExp(
    r'[A-Za-z0-9]{3,4}[A-Za-z]{2}[0-9]{3,4}',
    caseSensitive: false,
  );

  Future<void> pickAndScan() async {
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;

    setState(() {
      pickedImage = File(img.path);
      loading = true;
    });

    final inputImage = InputImage.fromFilePath(img.path);

    // -------------------------------------------------------------------
    // 1️⃣ BARCODE SCAN TO GET USN (MOST ACCURATE)
    // -------------------------------------------------------------------
    String? extractedUSN;

    try {
      final barcodes = await barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        for (Barcode b in barcodes) {
          String? raw = b.rawValue;
          if (raw != null) {
            final match = usnRegex.firstMatch(raw);
            if (match != null) {
              extractedUSN = match.group(0)!.toUpperCase();
              print("🎯 USN FOUND IN BARCODE: $extractedUSN");
              break;
            }
          }
        }
      }
    } catch (e) {
      print("⚠ Barcode scan error: $e");
    }

    // -------------------------------------------------------------------
    // 2️⃣ OCR TO GET NAME
    // -------------------------------------------------------------------
    final textResult = await textRecognizer.processImage(inputImage);
    final fullText = textResult.text;
    final lines = fullText.split("\n");

    String? extractedName;

    for (String line in lines) {
      if (line.toLowerCase().contains("name")) {
        extractedName = line.replaceAll(RegExp(r"name[: ]*", caseSensitive: false), "").trim();
      }
    }

    extractedName ??= lines.firstWhere(
          (l) => RegExp(r'^[A-Za-z ]{3,}$').hasMatch(l) && l.trim().split(" ").length >= 2,
      orElse: () => "",
    );

    // -------------------------------------------------------------------
    // 3️⃣ IF BARCODE FAILED → TRY OCR FOR USN
    // -------------------------------------------------------------------
    if (extractedUSN == null) {
      final cleaned = fullText.replaceAll("\n", " ");
      final match = usnRegex.firstMatch(cleaned);
      if (match != null) {
        extractedUSN = match.group(0)!.toUpperCase();
        print("🔄 USN FOUND BY OCR: $extractedUSN");
      }
    }

    // -------------------------------------------------------------------
    // 4️⃣ Upload image to Firebase
    // -------------------------------------------------------------------
    String? url;
    try {
      final ref = FirebaseStorage.instance
          .ref("id_scans/${DateTime.now().millisecondsSinceEpoch}.jpg");
      await ref.putFile(File(img.path));
      url = await ref.getDownloadURL();
    } catch (e) {
      print("🔥 Upload error: $e");
    }

    setState(() {
      loading = false;
    });

    Navigator.pop(context, {
      "name": extractedName ?? "",
      "usn": extractedUSN ?? "",
      "profilePic": url,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan ID Card")),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
          icon: const Icon(Icons.camera_alt),
          label: const Text("Pick ID from Gallery"),
          onPressed: pickAndScan,
        ),
      ),
    );
  }
}
