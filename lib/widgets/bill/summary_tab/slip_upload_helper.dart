import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

Future<void> pickSlipAndMarkPaid(
  BuildContext context, {
  required BillsStore billsStore,
  required Bill bill,
  required String memberId,
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
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.t('slip_upload_title'),
              style: GoogleFonts.notoSansThai(
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
              style: GoogleFonts.notoSansThai(
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
                  borderRadius: BorderRadius.circular(12)),
              tileColor: isDark
                  ? const Color(0xFF1F2937)
                  : const Color(0xFFF9FAFB),
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.blue400),
              title: Text(l.t('slip_from_gallery'),
                  style: GoogleFonts.notoSansThai(fontSize: 14)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              tileColor: isDark
                  ? const Color(0xFF1F2937)
                  : const Color(0xFFF9FAFB),
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.blue400),
              title: Text(l.t('slip_take_photo'),
                  style: GoogleFonts.notoSansThai(fontSize: 14)),
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

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        l.t('slip_confirm_title'),
        style: GoogleFonts.notoSansThai(
            fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: kIsWeb
                ? Image.network(
                    image.path,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(image.path),
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            l.t('slip_confirm_msg'),
            style: GoogleFonts.notoSansThai(fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.t('slip_cancel'), style: GoogleFonts.notoSansThai()),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald500),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.t('slip_confirm_btn'),
              style: GoogleFonts.notoSansThai(
                  fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );

  if (confirmed != true) return;
  if (!context.mounted) return;

  await billsStore.toggleMemberPaid(bill.id, memberId);
}
