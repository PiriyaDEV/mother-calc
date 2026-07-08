import 'slip_ocr_service.dart';

/// Web stub — ML Kit is not available on web.
Future<SlipOcrResult> scanSlipAmountImpl(String imagePath) async {
  return const SlipOcrResult(
    amount: null,
    rawLines: [],
    ocrSucceeded: false,
  );
}
