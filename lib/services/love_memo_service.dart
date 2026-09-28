import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart';

class LoveMemoService {
  final model = FirebaseAI.vertexAI().generativeModel(model: 'gemini-2.5-flash-lite');

  Future<String> generateMemo(String topic) async {
    try {
      final prompt = 'Write a short, highly romantic virtual love letter focusing on $topic. Keep it under 3 sentences.';
      final response = await model.generateContent([Content.text(prompt)]);
      
      if (response.text != null && response.text!.trim().isNotEmpty) {
        return response.text!.trim();
      } else {
        return "My love for you leaves me speechless...";
      }
    } catch (e) {
      return "Even though my heart is full, I couldn't find the right words right now... (Error: $e)";
    }
  }

  Future<Uint8List?> generateImageScenario(Uint8List referenceImage, String scenario) async {
    try {
      final imagen = FirebaseAI.vertexAI().imagenModel(model: 'imagen-3.0-capability-001');

      final inlineImage = ImagenInlineImage(bytesBase64Encoded: referenceImage, mimeType: 'image/jpeg');

      final subject = ImagenSubjectReference(
        image: inlineImage,
        referenceId: 1,
        subjectType: ImagenSubjectReferenceType.person,
      );

      final response = await imagen.editImage(
        [subject],
        '$scenario [1]',
      );

      if (response.images.isNotEmpty) {
        return response.images.first.bytesBase64Encoded;
      }
      return null;
    } catch (e) {
      print("Imagen generation failed: $e");
      return null;
    }
  }
}
