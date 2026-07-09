import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/services/web_image_saver.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'package:path_provider/path_provider.dart';

import 'bill_pdf_generator.dart';

enum _DownloadMode { fullBill, memberSummary }

/// Shows a bottom-sheet dialog that lets the user choose:
///   • สรุปทั้งบิล  → PDF with full summary + QR pages for all members with PromptPay
///   • สรุปรายบุคคล → user picks a member → PDF with member summary + QR pages for their debts
void showDownloadSummaryDialog({
  required BuildContext context,
  required Bill bill,
  required BillCalculation calc,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DownloadSummarySheet(bill: bill, calc: calc),
  );
}

class _DownloadSummarySheet extends StatefulWidget {
  final Bill bill;
  final BillCalculation calc;

  const _DownloadSummarySheet({required this.bill, required this.calc});

  @override
  State<_DownloadSummarySheet> createState() => _DownloadSummarySheetState();
}

class _DownloadSummarySheetState extends State<_DownloadSummarySheet> {
  _DownloadMode _mode = _DownloadMode.fullBill;
  String? _selectedMemberId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.bill.members.isNotEmpty) {
      _selectedMemberId = widget.bill.members.first.id;
    }
  }

  List<DebtTransaction> get _allDebts =>
      simplifyDebts(widget.calc.memberSummaries, widget.bill.members, null);

  /// Members that have PromptPay AND are owed money by at least one other member.
  List<({BillMember member, double totalOwed})> get _qrRecipients {
    final allDebts = _allDebts;
    final result = <({BillMember member, double totalOwed})>[];
    for (final m in widget.bill.members) {
      if (m.promptpay == null || m.promptpay!.isEmpty) continue;
      final owed = allDebts
          .where((d) => d.to.id == m.id)
          .fold<double>(0, (sum, d) => sum + d.amount);
      if (owed > 0) {
        result.add((member: m, totalOwed: owed));
      }
    }
    return result;
  }

  List<DebtTransaction> _debtsWithQrForMember(String memberId) {
    return _allDebts
        .where((d) =>
            d.from.id == memberId &&
            d.to.promptpay != null &&
            d.to.promptpay!.isNotEmpty)
        .toList();
  }

  Future<void> _download() async {
    if (_saving) return;
    setState(() => _saving = true);

    final bill = widget.bill;
    final calc = widget.calc;
    final allDebts = _allDebts;
    final mode = _mode;
    final selectedMemberId = _selectedMemberId;

    Uint8List? pdfBytes;
    String fileName = 'kidtang_summary';

    try {
      final generator = BillPdfGenerator(
        bill: bill,
        calc: calc,
        allDebts: allDebts,
      );

      if (mode == _DownloadMode.fullBill) {
        pdfBytes = await generator.generateFullBillPdf();
        fileName = 'kidtang_${_sanitize(bill.title)}_summary';
      } else if (selectedMemberId != null) {
        final member =
            bill.members.firstWhere((m) => m.id == selectedMemberId);
        pdfBytes = await generator.generateMemberPdf(member);
        fileName =
            'kidtang_${_sanitize(bill.title)}_${_sanitize(member.name)}';
      }
    } catch (e) {
      debugPrint('[DownloadSummaryDialog._download]: $e');
    }

    if (!mounted) return;

    // PDF generation failed — show error and re-enable button
    if (pdfBytes == null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'เกิดข้อผิดพลาด กรุณาลองใหม่',
            style: TextStyle(fontFamily: 'NotoSansThai'),
          ),
          backgroundColor: AppColors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppRadii.md))),
        ),
      );
      return;
    }

    // Capture messenger before pop (context may be invalid after pop)
    final messenger = ScaffoldMessenger.of(context);

    // Trigger the actual download / file save
    bool success = false;
    if (kIsWeb) {
      success = downloadPdfOnWeb(pdfBytes, '$fileName.pdf');
    } else {
      success = await _savePdfNative(pdfBytes, '$fileName.pdf');
    }

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success ? 'ดาวน์โหลด PDF สำเร็จ 🎉' : 'เกิดข้อผิดพลาด กรุณาลองใหม่',
          style: const TextStyle(fontFamily: 'NotoSansThai'),
        ),
        backgroundColor: success ? AppColors.emerald500 : AppColors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md)),
      ),
    );
  }

  /// Saves PDF bytes to the app documents directory on mobile/desktop.
  /// Never called on web (guarded by kIsWeb above).
  Future<bool> _savePdfNative(Uint8List bytes, String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return true;
    } catch (e) {
      debugPrint('[DownloadSummaryDialog._savePdfNative]: $e');
      return false;
    }
  }

  static String _sanitize(String s) =>
      s.replaceAll(RegExp(r'[^\w\u0E00-\u0E7F]'), '_').toLowerCase();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bill = widget.bill;
    final members = bill.members;

    final qrRecipients = _qrRecipients;

    // For member mode: count QR pages (debts with PromptPay)
    int memberQrCount = 0;
    if (_selectedMemberId != null) {
      memberQrCount = _debtsWithQrForMember(_selectedMemberId!).length;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'ดาวน์โหลดสรุปบิล (PDF)',
                style: GoogleFonts.sarabun(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'เลือกประเภทสรุปที่ต้องการดาวน์โหลด',
                style: GoogleFonts.sarabun(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),

              // Mode selector
              _ModeCard(
                title: 'สรุปทั้งบิล',
                subtitle:
                    'PDF สรุปรวม + QR พร้อมเพย์ (${qrRecipients.length} หน้า QR)',
                icon: Icons.receipt_long_rounded,
                selected: _mode == _DownloadMode.fullBill,
                isDark: isDark,
                onTap: () => setState(() => _mode = _DownloadMode.fullBill),
              ),
              const SizedBox(height: 8),
              _ModeCard(
                title: 'สรุปรายบุคคล',
                subtitle: 'PDF สรุปของคนที่เลือก + QR ของคนที่ต้องโอนให้',
                icon: Icons.person_rounded,
                selected: _mode == _DownloadMode.memberSummary,
                isDark: isDark,
                onTap: () =>
                    setState(() => _mode = _DownloadMode.memberSummary),
              ),

              // Member picker (only for per-member mode)
              if (_mode == _DownloadMode.memberSummary) ...[
                const SizedBox(height: 16),
                Text(
                  'เลือกสมาชิก',
                  style: GoogleFonts.sarabun(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: members.map((m) {
                    final isSelected = m.id == _selectedMemberId;
                    final color = colorFromHex(m.color);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedMemberId = m.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.15)
                              : (isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.bgSubtle),
                          borderRadius: BorderRadius.circular(AppRadii.xl),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : (isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              m.name,
                              style: GoogleFonts.sarabun(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? color
                                    : (isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 20),

              // PDF page count info
              _PdfPageInfo(
                mode: _mode,
                qrRecipientsCount: qrRecipients.length,
                memberQrCount: memberQrCount,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Download button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _download,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.picture_as_pdf_rounded,
                          size: 18, color: Colors.white),
                  label: Text(
                    _saving ? 'กำลังสร้าง PDF...' : 'ดาวน์โหลด PDF',
                    style: GoogleFonts.sarabun(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _saving ? AppColors.neutral400 : AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.xl),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mode Card ────────────────────────────────────────────────────────────────
class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : (isDark ? AppColors.surfaceDark : AppColors.bgSubtle),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.sarabun(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.sarabun(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected
                  ? AppColors.primary
                  : (isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PDF Page Info ────────────────────────────────────────────────────────────
class _PdfPageInfo extends StatelessWidget {
  final _DownloadMode mode;
  final int qrRecipientsCount;
  final int memberQrCount;
  final bool isDark;

  const _PdfPageInfo({
    required this.mode,
    required this.qrRecipientsCount,
    required this.memberQrCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final int totalPages = mode == _DownloadMode.fullBill
        ? 1 + qrRecipientsCount
        : 1 + memberQrCount;

    final String detail = mode == _DownloadMode.fullBill
        ? '1 หน้าสรุปรวม + $qrRecipientsCount หน้า QR พร้อมเพย์'
        : '1 หน้าสรุปส่วนตัว + $memberQrCount หน้า QR พร้อมเพย์';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf_rounded,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PDF $totalPages หน้า',
                  style: GoogleFonts.sarabun(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  detail,
                  style: GoogleFonts.sarabun(
                    fontSize: 11,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
