// Conditional import: ML Kit only works on mobile (Android/iOS).
// On web, we use a stub that always returns null.
import 'slip_ocr_service_stub.dart'
    if (dart.library.io) 'slip_ocr_service_mobile.dart';

/// Result of scanning a payment slip image.
class SlipOcrResult {
  /// The amount parsed from the slip, or null if not found.
  final double? amount;

  /// All raw text lines extracted from the slip (for debugging / display).
  final List<String> rawLines;

  /// Whether OCR succeeded at all (even if amount wasn't found).
  final bool ocrSucceeded;

  const SlipOcrResult({
    required this.amount,
    required this.rawLines,
    required this.ocrSucceeded,
  });
}

/// Scans a payment slip image and extracts the transfer amount.
///
/// Returns [SlipOcrResult] with the parsed amount (or null if not found).
/// On web, always returns a result with ocrSucceeded=false.
Future<SlipOcrResult> scanSlipAmount(String imagePath) =>
    scanSlipAmountImpl(imagePath);

/// Parses a Thai PromptPay / bank transfer slip text and extracts the amount.
///
/// Handles common formats from major Thai banks:
///   - ฿1,234.56
///   - 1,234.56 บาท
///   - THB 1,234.56
///   - จำนวนเงิน 1,234.56
///   - ยอดโอน 1,234.56
///   - Amount 1,234.56
///   - 1234.56 (plain number near amount keywords)
double? parseAmountFromSlipText(List<String> lines) {
  // Patterns ordered by specificity (most specific first)
  final patterns = [
    // ฿ symbol directly before number
    RegExp(r'฿\s*([\d,]+(?:\.\d{1,2})?)'),
    // THB prefix
    RegExp(r'THB\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
    // บาท suffix
    RegExp(r'([\d,]+(?:\.\d{1,2})?)\s*บาท'),
    // จำนวนเงิน / ยอดโอน / ยอดเงิน / จำนวน keyword on same line
    RegExp(
        r'(?:จำนวนเงิน|ยอดโอน|ยอดเงิน|จำนวน|Amount|Total)\s*[:\s]?\s*([\d,]+(?:\.\d{1,2})?)',
        caseSensitive: false),
  ];

  final fullText = lines.join('\n');

  for (final pattern in patterns) {
    final match = pattern.firstMatch(fullText);
    if (match != null) {
      final raw = match.group(1)!.replaceAll(',', '');
      final value = double.tryParse(raw);
      if (value != null && value > 0) {
        return value;
      }
    }
  }

  // Fallback: look for the largest number that looks like a money amount
  // (has exactly 2 decimal places) across all lines
  double? bestCandidate;
  final moneyPattern = RegExp(r'\b([\d,]+\.\d{2})\b');
  for (final line in lines) {
    for (final match in moneyPattern.allMatches(line)) {
      final raw = match.group(1)!.replaceAll(',', '');
      final value = double.tryParse(raw);
      if (value != null && value > 0) {
        // Prefer the largest value (usually the transfer total)
        if (bestCandidate == null || value > bestCandidate) {
          bestCandidate = value;
        }
      }
    }
  }
  return bestCandidate;
}
