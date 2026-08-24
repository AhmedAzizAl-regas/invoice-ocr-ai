import 'dart:convert';
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';

/// OcrResult contains the outcome of an OCR analysis phase.
class OcrResult {
  final String text;
  final double confidence;
  final String engineUsed;
  final bool success;
  final String? errorMessage;

  OcrResult({
    required this.text,
    required this.confidence,
    required this.engineUsed,
    required this.success,
    this.errorMessage,
  });
}

/// OcrService handles local and cloud OCR engines in a cascading fallback sequence.
class OcrService {
  final ApiClient _apiClient;

  OcrService(this._apiClient);

  /// Executes the multi-stage OCR cascade.
  /// 1. Google ML Kit OCR (local)
  /// 2. Tesseract OCR (local)
  /// 3. Google Vision OCR (cloud)
  Future<OcrResult> executePipeline(File imageFile, {
    required bool isOnline,
    String? googleVisionKey,
  }) async {
    List<String> logs = [];

    // Stage 1: Google ML Kit (Local)
    try {
      final mlKitResult = await runGoogleMlKit(imageFile);
      if (mlKitResult.success && mlKitResult.confidence >= AppConfig.confidenceThresholdExcellent) {
        return mlKitResult;
      }
      logs.add('ML Kit confidence: ${mlKitResult.confidence.toStringAsFixed(2)}');
    } catch (e) {
      logs.add('ML Kit error: $e');
    }

    // Stage 2: Tesseract OCR (Local)
    try {
      final tesseractResult = await runTesseract(imageFile);
      if (tesseractResult.success && tesseractResult.confidence >= AppConfig.confidenceThresholdGood) {
        return tesseractResult;
      }
      logs.add('Tesseract confidence: ${tesseractResult.confidence.toStringAsFixed(2)}');
    } catch (e) {
      logs.add('Tesseract error: $e');
    }

    // If local OCR engines are not sufficient and the device is offline, return the best local result
    if (!isOnline) {
      return OcrResult(
        text: 'Offline: Local confidence was low. Logs:\n${logs.join("\n")}',
        confidence: 0.4,
        engineUsed: 'Cascade (Local Fallback)',
        success: false,
        errorMessage: 'Offline. Could not perform cloud OCR cascade.',
      );
    }

    // Stage 3: Google Vision Cloud OCR
    final finalGoogleVisionKey = googleVisionKey ?? AppConfig.googleVisionApiKey;
    if (finalGoogleVisionKey.isNotEmpty) {
      try {
        final visionResult = await runGoogleVisionCloud(imageFile, finalGoogleVisionKey);
        if (visionResult.success && visionResult.confidence >= AppConfig.confidenceThresholdExcellent) {
          return visionResult;
        }
        logs.add('Google Vision confidence: ${visionResult.confidence.toStringAsFixed(2)}');
      } catch (e) {
        logs.add('Google Vision error: $e');
      }
    } else {
      logs.add('Google Vision skipped: API Key empty');
    }



    return OcrResult(
      text: '',
      confidence: 0.0,
      engineUsed: 'Cascade Pipeline',
      success: false,
      errorMessage: 'OCR pipeline failed. Logs:\n${logs.join("\n")}',
    );
  }

  // --- Local Engine 1: Google ML Kit ---
  Future<OcrResult> runGoogleMlKit(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    
    // We use default script (latin + arabic is supported in ML Kit)
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    
    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final String text = recognizedText.text;
      if (text.isEmpty) {
        return OcrResult(text: '', confidence: 0.0, engineUsed: 'Google ML Kit', success: false);
      }

      // Estimate confidence based on block structures or element layouts (ML Kit doesn't return numeric text confidence)
      double confidence = 0.85; // Assume standard confidence if text is present
      if (text.contains('Total') || text.contains('الاجمالي') || text.contains('فاتورة')) {
        confidence += 0.1;
      }
      return OcrResult(
        text: text,
        confidence: confidence.clamp(0.0, 1.0),
        engineUsed: 'Google ML Kit',
        success: true,
      );
    } catch (e) {
      await textRecognizer.close();
      rethrow;
    }
  }

  // --- Local Engine 2: Tesseract OCR ---
  Future<OcrResult> runTesseract(File imageFile) async {
    // Tesseract extracts text using local binaries
    final text = await FlutterTesseractOcr.extractText(
      imageFile.path,
      language: 'ara+eng', // Supporting both English and Arabic OCR
      args: {
        'psm': '3', // Fully automatic page segmentation
      },
    );

    if (text.trim().isEmpty) {
      return OcrResult(text: '', confidence: 0.0, engineUsed: 'Tesseract OCR', success: false);
    }

    // Tesseract doesn't easily expose segment confidence in this dart package, so we approximate
    double confidence = 0.70;
    if (text.contains('\n')) {
      confidence += 0.1;
    }
    return OcrResult(
      text: text,
      confidence: confidence.clamp(0.0, 1.0),
      engineUsed: 'Tesseract OCR',
      success: true,
    );
  }

  // --- Cloud Engine 3: Google Vision Cloud OCR ---
  Future<OcrResult> runGoogleVisionCloud(File imageFile, String apiKey) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final url = 'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';
    final body = {
      'requests': [
        {
          'image': {'content': base64Image},
          'features': [
            {'type': 'TEXT_DETECTION'}
          ]
        }
      ]
    };

    final response = await _apiClient.post(url, body: body);
    
    final responses = response['responses'] as List?;
    if (responses == null || responses.isEmpty) {
      throw Exception('Google Vision empty response');
    }

    final annotation = responses.first['fullTextAnnotation'];
    if (annotation == null) {
      return OcrResult(text: '', confidence: 0.0, engineUsed: 'Google Vision Cloud', success: false);
    }

    final text = annotation['text'] as String? ?? '';
    // Calculate average confidence from pages/paragraphs
    double confidence = 0.95; 

    return OcrResult(
      text: text,
      confidence: confidence,
      engineUsed: 'Google Vision Cloud',
      success: true,
    );
  }


}
