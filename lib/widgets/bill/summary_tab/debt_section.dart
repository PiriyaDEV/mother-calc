import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'package:kidtang_flutter/widgets/shared/member_avatar.dart';
import 'slip_upload_helper.dart';

class DebtSection extends StatelessWidget {
  final List<DebtTransaction> debts;
  final BillMember selectedMember;
  final String? currentUserId;
  final Bill bill;
  final BillsStore billsStore;
  final String currency;
  final bool isDark;
  final String? expandedQrMemberId;
  final ValueChanged<String> onToggleQr;

  const DebtSection({
    super.key,
    required this.debts,
    required this.selectedMember,
    required this.currentUserId,
    required this.bill,
    required this.billsStore,
    required this.currency,
    required this.isDark,
    required this.expandedQrMemberId,
    required this.onToggleQr,
  });

  @override
  Widget build(BuildContext context) {
      final l = context.watch<LocaleProvider>();
    final isMe = selectedMember.userId == currentUserId;
    final title = isMe
        ? l.t('summary_i_owe')
        : '${selectedMember.name} ต้องโอนให้';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.notoSansThai(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        if (debts.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.emerald200),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.emerald600, size: 18),
                const SizedBox(width: 8),
                Text(
                  isMe
                      ? l.t('summary_no_debt_me')
                      : '${selectedMember.name} ไม่ต้องโอนให้ใคร',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 13,
                    color: AppColors.emerald700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          ...debts.map((debt) => _DebtCard(
                debt: debt,
                bill: bill,
                billsStore: billsStore,
                currency: currency,
                isDark: isDark,
                isQrExpanded: expandedQrMemberId == debt.to.id,
                onToggleQr: () => onToggleQr(debt.to.id),
              )),
      ],
    );
  }
}

class _DebtCard extends StatefulWidget {
  final DebtTransaction debt;
  final Bill bill;
  final BillsStore billsStore;
  final String currency;
  final bool isDark;
  final bool isQrExpanded;
  final VoidCallback onToggleQr;

  const _DebtCard({
    required this.debt,
    required this.bill,
    required this.billsStore,
    required this.currency,
    required this.isDark,
    required this.isQrExpanded,
    required this.onToggleQr,
  });

  @override
  State<_DebtCard> createState() => _DebtCardState();
}

class _DebtCardState extends State<_DebtCard> {
  final GlobalKey _qrKey = GlobalKey();
  bool _savingQr = false;

  Future<void> _saveQrToGallery() async {
    if (_savingQr) return;
    setState(() => _savingQr = true);
    final l = context.read<LocaleProvider>();
    try {
      final boundary = _qrKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final result = await ImageGallerySaverPlus.saveImage(
        Uint8List.fromList(bytes),
        quality: 100,
        name:
            'kidtang_qr_${widget.debt.to.name}_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      final success =
          result['isSuccess'] == true || result['filePath'] != null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? l.t('debt_save_qr_success') : l.t('debt_save_qr_fail'),
            style: const TextStyle(fontFamily: 'NotoSansThai'),
          ),
          backgroundColor:
              success ? AppColors.emerald500 : AppColors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.t('debt_save_qr_fail_msg')),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingQr = false);
    }
  }

  @override
  Widget build(BuildContext context) {
      final l = context.watch<LocaleProvider>();
    final debt = widget.debt;
    final bill = widget.bill;
    final billsStore = widget.billsStore;
    final currency = widget.currency;
    final isDark = widget.isDark;
    final isQrExpanded = widget.isQrExpanded;
    final onToggleQr = widget.onToggleQr;
    final isPaid = bill.paidMemberIds.contains(debt.from.id);
    final fromColor = colorFromHex(debt.from.color);
    final toColor = colorFromHex(debt.to.color);
    final hasPromptPay =
        debt.to.promptpay != null && debt.to.promptpay!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isPaid
            ? AppColors.emerald50
            : (isDark ? AppColors.surfaceDark : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPaid
              ? AppColors.emerald200
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                MemberAvatar(
                    name: debt.from.name,
                    color: fromColor,
                    size: 32,
                    avatarUrl: debt.from.profile?.avatarUrl),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
                MemberAvatar(
                    name: debt.to.name,
                    color: toColor,
                    size: 32,
                    avatarUrl: debt.to.profile?.avatarUrl),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.to.name,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      if (hasPromptPay)
                        Text(
                          l.t('debt_promptpay').replaceAll('{pp}', debt.to.promptpay ?? ''),
                          style: GoogleFonts.notoSansThai(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatNumber(debt.amount),
                      style: GoogleFonts.notoSansThai(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isPaid
                            ? AppColors.emerald600
                            : (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight),
                        decoration:
                            isPaid ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      currency,
                      style: GoogleFonts.notoSansThai(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
                if (hasPromptPay) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onToggleQr,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isQrExpanded
                            ? AppColors.blue400.withValues(alpha: 0.1)
                            : (isDark
                                ? const Color(0xFF374151)
                                : const Color(0xFFF3F4F6)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.qr_code_rounded,
                        size: 18,
                        color: isQrExpanded
                            ? AppColors.blue400
                            : (isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // QR expand
          if (isQrExpanded && hasPromptPay) ...[
            Divider(
                height: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  RepaintBoundary(
                    key: _qrKey,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFE5E7EB)),
                            ),
                            child: CachedNetworkImage(
                              imageUrl:
                                  'https://promptpay.io/${debt.to.promptpay}/${debt.amount.toStringAsFixed(2)}.png',
                              width: 180,
                              height: 180,
                              placeholder: (context, url) => const SizedBox(
                                width: 180,
                                height: 180,
                                child: Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const SizedBox(
                                width: 180,
                                height: 180,
                                child: Icon(Icons.qr_code_2_rounded,
                                    size: 48,
                                    color: Color(0xFF9CA3AF)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l.t('debt_scan_qr').replaceAll('{name}', debt.to.name),
                            style: GoogleFonts.notoSansThai(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            debt.to.promptpay!,
                            style: GoogleFonts.notoSansThai(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/logo.png',
                                  width: 22,
                                  height: 22,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Kidtang',
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!kIsWeb)
                    GestureDetector(
                      onTap: _saveQrToGallery,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: _savingQr
                              ? AppColors.neutral400
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_savingQr)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            else
                              const Icon(Icons.download_rounded,
                                  size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              _savingQr
                                  ? l.t('summary_saving_qr')
                                  : l.t('summary_save_qr'),
                              style: GoogleFonts.notoSansThai(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Paid toggle
          if (bill.isCompleted || bill.status == 'pending_payment') ...[
            Divider(
                height: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    isPaid
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: isPaid
                        ? AppColors.emerald500
                        : AppColors.textTertiaryLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isPaid ? 'จ่ายแล้ว' : l.t('summary_not_paid_label'),
                    style: GoogleFonts.notoSansThai(
                      fontSize: 13,
                      color: isPaid
                          ? AppColors.emerald600
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                    ),
                  ),
                  const Spacer(),
                  Builder(
                    builder: (ctx) => GestureDetector(
                      onTap: () async {
                        if (!isPaid) {
                          await pickSlipAndMarkPaid(
                            ctx,
                            billsStore: billsStore,
                            bill: bill,
                            memberId: debt.from.id,
                          );
                        } else {
                          await billsStore.toggleMemberPaid(
                              bill.id, debt.from.id);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? (isDark
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFF3F4F6))
                              : AppColors.emerald500,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isPaid)
                              const Icon(Icons.upload_rounded,
                                  size: 14, color: Colors.white),
                            if (isPaid)
                              Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            const SizedBox(width: 4),
                            Text(
                              isPaid ? 'ยกเลิก' : l.t('summary_upload_slip'),
                              style: GoogleFonts.notoSansThai(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isPaid
                                    ? (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight)
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
