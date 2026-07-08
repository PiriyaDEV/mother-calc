import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/services/slip_ocr_service.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

/// Tolerance for amount comparison: ±1 baht to handle rounding differences.
const double _amountTolerance = 1.0;

Future<void> pickSlipAndMarkPaid(
  BuildContext context, {
  required BillsStore billsStore,
  required Bill bill,
  required String memberId,
  /// The expected amount this member should pay (used for OCR verification).
  double? expectedAmount,
}) async {
  final l = context.read<LocaleProvider>();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final source = await showDialog<ImageSource>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.t('slip_upload_title'),
              style: GoogleFonts.sarabun(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.t('slip_upload_sub'),
              style: GoogleFonts.sarabun(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md)),
              tileColor: isDark
                  ? AppColors.surfaceDark
                  : AppColors.bgSubtle,
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.blue400),
              title: Text(l.t('slip_from_gallery'),
                  style: GoogleFonts.sarabun(fontSize: 14)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md)),
              tileColor: isDark
                  ? AppColors.surfaceDark
                  : AppColors.bgSubtle,
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.blue400),
              title: Text(l.t('slip_take_photo'),
                  style: GoogleFonts.sarabun(fontSize: 14)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    ),
  );

  if (source == null) return;
  if (!context.mounted) return;

  final picker = ImagePicker();
  final XFile? image = await picker.pickImage(
    source: source,
    maxWidth: 1920,
    imageQuality: 85,
  );
  if (image == null) return;
  if (!context.mounted) return;

  // ── OCR: scan the slip for the transfer amount ──────────────────────────
  SlipOcrResult? ocrResult;
  if (!kIsWeb && expectedAmount != null) {
    // Show scanning indicator
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                'กำลังตรวจสอบสลิป...',
                style: GoogleFonts.sarabun(fontSize: 13),
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md)),
        ),
      );
    }

    ocrResult = await scanSlipAmount(image.path);

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  if (!context.mounted) return;

  // ── Determine OCR verification status ───────────────────────────────────
  _OcrStatus ocrStatus = _OcrStatus.skipped;
  if (ocrResult != null && expectedAmount != null) {
    if (!ocrResult.ocrSucceeded) {
      ocrStatus = _OcrStatus.failed;
    } else if (ocrResult.amount == null) {
      ocrStatus = _OcrStatus.amountNotFound;
    } else {
      final diff = (ocrResult.amount! - expectedAmount).abs();
      ocrStatus = diff <= _amountTolerance
          ? _OcrStatus.matched
          : _OcrStatus.mismatch;
    }
  }

  // ── Confirmation dialog with OCR result ─────────────────────────────────
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => _SlipConfirmDialog(
      image: image,
      isDark: isDark,
      ocrStatus: ocrStatus,
      ocrAmount: ocrResult?.amount,
      expectedAmount: expectedAmount,
      l: l,
    ),
  );

  if (confirmed != true) return;
  if (!context.mounted) return;

  await billsStore.toggleMemberPaid(bill.id, memberId);
}

// ── OCR status enum ──────────────────────────────────────────────────────────
enum _OcrStatus {
  /// OCR was not run (web or no expectedAmount provided).
  skipped,
  /// OCR ran but failed to process the image.
  failed,
  /// OCR ran but couldn't find an amount in the text.
  amountNotFound,
  /// OCR found an amount that matches the expected amount (within tolerance).
  matched,
  /// OCR found an amount but it doesn't match the expected amount.
  mismatch,
}

// ── Confirmation dialog ──────────────────────────────────────────────────────
class _SlipConfirmDialog extends StatelessWidget {
  final XFile image;
  final bool isDark;
  final _OcrStatus ocrStatus;
  final double? ocrAmount;
  final double? expectedAmount;
  final LocaleProvider l;

  const _SlipConfirmDialog({
    required this.image,
    required this.isDark,
    required this.ocrStatus,
    required this.ocrAmount,
    required this.expectedAmount,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final isMismatch = ocrStatus == _OcrStatus.mismatch;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl)),
      title: Text(
        l.t('slip_confirm_title'),
        style: GoogleFonts.sarabun(
            fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slip preview
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: kIsWeb
                ? Image.network(
                    image.path,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(image.path),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(height: 12),

          // OCR result banner
          _OcrResultBanner(
            ocrStatus: ocrStatus,
            ocrAmount: ocrAmount,
            expectedAmount: expectedAmount,
            isDark: isDark,
          ),

          const SizedBox(height: 8),
          Text(
            isMismatch
                ? 'ยอดเงินในสลิปไม่ตรงกับยอดที่ต้องจ่าย\nต้องการยืนยันต่อหรือไม่?'
                : l.t('slip_confirm_msg'),
            style: GoogleFonts.sarabun(
              fontSize: 13,
              color: isMismatch ? AppColors.red : null,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.t('slip_cancel'), style: GoogleFonts.sarabun()),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor:
                isMismatch ? AppColors.red : AppColors.emerald500,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            isMismatch ? 'ยืนยันต่อไป' : l.t('slip_confirm_btn'),
            style: GoogleFonts.sarabun(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ── OCR result banner ────────────────────────────────────────────────────────
class _OcrResultBanner extends StatelessWidget {
  final _OcrStatus ocrStatus;
  final double? ocrAmount;
  final double? expectedAmount;
  final bool isDark;

  const _OcrResultBanner({
    required this.ocrStatus,
    required this.ocrAmount,
    required this.expectedAmount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (ocrStatus == _OcrStatus.skipped) return const SizedBox.shrink();

    final (IconData icon, Color color, String message) = switch (ocrStatus) {
      _OcrStatus.matched => (
          Icons.check_circle_rounded,
          AppColors.emerald500,
          'ยอดเงินตรงกัน ✓  ฿${_fmt(ocrAmount!)}',
        ),
      _OcrStatus.mismatch => (
          Icons.warning_rounded,
          AppColors.red,
          'ยอดในสลิป ฿${_fmt(ocrAmount!)}  ≠  ยอดที่ต้องจ่าย ฿${_fmt(expectedAmount!)}',
        ),
      _OcrStatus.amountNotFound => (
          Icons.help_outline_rounded,
          AppColors.amber,
          'ไม่พบยอดเงินในสลิป — กรุณาตรวจสอบด้วยตนเอง',
        ),
      _OcrStatus.failed => (
          Icons.error_outline_rounded,
          AppColors.neutral400,
          'ไม่สามารถอ่านสลิปได้ — กรุณาตรวจสอบด้วยตนเอง',
        ),
      _ => (
          Icons.info_outline_rounded,
          AppColors.neutral400,
          '',
        ),
    };

    if (message.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.sarabun(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}
