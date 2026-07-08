import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'slip_ocr_service.dart';

/// Mobile implementation — uses Google ML Kit on-device OCR.
///
/// ML Kit's Latin script recognizer handles digits, English keywords (THB,
/// Amount, Total) and common Thai bank slip patterns well enough for amount
/// extraction. Thai characters in keywords like "บาท" / "จำนวนเงิน" may not
/// be recognized perfectly, but the numeric amount and ฿ / THB patterns are
/// reliably captured.
Future<SlipOcrResult> scanSlipAmountImpl(String imagePath) async {
  // Latin script covers digits, ฿ symbol, THB, and English amount labels.
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  try {
    final inputImage = InputImage.fromFile(File(imagePath));
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    final lines = <String>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isNotEmpty) lines.add(text);
      }
    }

    debugPrint('[SlipOcrService] OCR lines: $lines');

    final amount = parseAmountFromSlipText(lines);

    return SlipOcrResult(
      amount: amount,
      rawLines: lines,
      ocrSucceeded: true,
    );
  } catch (e) {
    debugPrint('[SlipOcrService.scanSlipAmountImpl]: $e');
    return const SlipOcrResult(
      amount: null,
      rawLines: [],
      ocrSucceeded: false,
    );
  } finally {
    textRecognizer.close();
  }
}
