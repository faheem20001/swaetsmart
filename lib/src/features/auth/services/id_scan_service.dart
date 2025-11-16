import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class IDScanService {
  final ImagePicker _picker = ImagePicker();

  /// Captures an ID image and extracts text fields: name, batch, USN, institution
  Future<Map<String, String>> scanIDCard() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return {};

    final inputImage = InputImage.fromFilePath(image.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText =
    await textRecognizer.processImage(inputImage);

    String name = '';
    String usn = '';
    String batch = '';
    String institution = '';

    for (final block in recognizedText.blocks) {
      final text = block.text.toLowerCase();

      if (text.contains('name')) {
        name = text.split(':').last.trim();
      }
      if (text.contains('usn')) {
        usn = text.split(':').last.trim();
      }
      if (text.contains('batch')) {
        batch = text.split(':').last.trim();
      }
      if (text.contains('college') || text.contains('institution')) {
        institution = text.split(':').last.trim();
      }
    }

    await textRecognizer.close();

    return {
      'name': name,
      'usn': usn,
      'batch': batch,
      'institution': institution,
    };
  }
}
