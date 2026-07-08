import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/services/web_image_saver.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'bill_summary_image.dart';

enum _DownloadMode { fullBill, memberSummary }

/// Shows a bottom-sheet dialog that lets the user choose:
///   • สรุปทั้งบิล  → renders BillFullSummaryImage + QR cards for all members with PromptPay
///   • สรุปรายบุคคล → user picks a member → renders BillMemberSummaryImage + QR cards for their debts
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

  // Keys for RepaintBoundary capture
  final GlobalKey _fullSummaryKey = GlobalKey();
  final List<GlobalKey> _qrKeys = [];
  final GlobalKey _memberSummaryKey = GlobalKey();
  final List<GlobalKey> _memberQrKeys = [];

  @override
  void initState() {
    super.initState();
    // Pre-select first member
    if (widget.bill.members.isNotEmpty) {
      _selectedMemberId = widget.bill.members.first.id;
    }
  }

  List<DebtTransaction> get _allDebts =>
      simplifyDebts(widget.calc.memberSummaries, widget.bill.members, null);

  /// Members that have PromptPay AND are owed money by at least one other member.
  /// These are the people whose QR codes need to be shared.
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

  List<DebtTransaction> _debtsForMember(String memberId) {
    return _allDebts.where((d) => d.from.id == memberId).toList();
  }

  MemberSummary _summaryForMember(String memberId) {
    final member = widget.bill.members.firstWhere((m) => m.id == memberId);
    return widget.calc.memberSummaries.firstWhere(
      (s) => s.member.id == memberId,
      orElse: () => MemberSummary(member: member, total: 0, items: []),
    );
  }

  Future<Uint8List?> _captureWidget(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[DownloadSummaryDialog._captureWidget]: $e');
      return null;
    }
  }

  Future<bool> _saveBytesNative(Uint8List bytes, String name) async {
    final result = await ImageGallerySaverPlus.saveImage(
      Uint8List.fromList(bytes),
      quality: 100,
      name: name,
    );
    return result['isSuccess'] == true || result['filePath'] != null;
  }

  Future<bool> _saveBytesWeb(Uint8List bytes, String name,
      {bool share = false, String shareTitle = 'สรุปบิล Kidtang'}) async {
    if (share) {
      return shareImageOnWeb(bytes, '$name.png', shareTitle);
    }
    return downloadImageOnWeb(bytes, '$name.png');
  }

  Future<void> _download({bool shareOnWeb = false}) async {
    if (_saving) return;
    setState(() => _saving = true);

    int saved = 0;
    int failed = 0;
    final ts = DateTime.now().millisecondsSinceEpoch;

    Future<bool> saveBytes(Uint8List bytes, String name) {
      if (kIsWeb) {
        return _saveBytesWeb(bytes, name,
            share: shareOnWeb, shareTitle: 'สรุปบิล ${widget.bill.title}');
      }
      return _saveBytesNative(bytes, name);
    }

    try {
      if (_mode == _DownloadMode.fullBill) {
        // 1. Full summary image
        final summaryBytes = await _captureWidget(_fullSummaryKey);
        if (summaryBytes != null) {
          final ok = await saveBytes(summaryBytes, 'kidtang_summary_$ts');
          ok ? saved++ : failed++;
        } else {
          failed++;
        }

        // 2. QR cards for each member with PromptPay (web: download each separately)
        for (int i = 0; i < _qrKeys.length; i++) {
          final bytes = await _captureWidget(_qrKeys[i]);
          if (bytes != null) {
            final ok = await saveBytes(bytes, 'kidtang_qr_${i}_$ts');
            ok ? saved++ : failed++;
          } else {
            failed++;
          }
        }
      } else {
        // Per-member mode
        // 1. Member summary image
        final summaryBytes = await _captureWidget(_memberSummaryKey);
        if (summaryBytes != null) {
          final ok = await saveBytes(summaryBytes, 'kidtang_member_summary_$ts');
          ok ? saved++ : failed++;
        } else {
          failed++;
        }

        // 2. QR cards for each debt that has PromptPay
        for (int i = 0; i < _memberQrKeys.length; i++) {
          final bytes = await _captureWidget(_memberQrKeys[i]);
          if (bytes != null) {
            final ok = await saveBytes(bytes, 'kidtang_qr_${i}_$ts');
            ok ? saved++ : failed++;
          } else {
            failed++;
          }
        }
      }
    } catch (e) {
      debugPrint('[DownloadSummaryDialog._download]: $e');
      failed++;
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failed == 0
              ? (kIsWeb && shareOnWeb
                  ? 'แชร์รูปสำเร็จ 🎉'
                  : 'บันทึก $saved รูปแล้ว 🎉')
              : 'บันทึกสำเร็จ $saved รูป, ล้มเหลว $failed รูป',
          style: const TextStyle(fontFamily: 'NotoSansThai'),
        ),
        backgroundColor:
            failed == 0 ? AppColors.emerald500 : AppColors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bill = widget.bill;
    final calc = widget.calc;
    final members = bill.members;

    // Rebuild QR key lists based on current mode
    final qrRecipients = _qrRecipients;

    // For full bill mode: one QR per member that is owed money and has PromptPay
    while (_qrKeys.length < qrRecipients.length) {
      _qrKeys.add(GlobalKey());
    }

    // For member mode: one QR per debt that has PromptPay
    List<DebtTransaction> memberDebts = [];
    MemberSummary? memberSummary;
    if (_selectedMemberId != null) {
      memberDebts = _debtsForMember(_selectedMemberId!)
          .where((d) => d.to.promptpay != null && d.to.promptpay!.isNotEmpty)
          .toList();
      memberSummary = _summaryForMember(_selectedMemberId!);
    }
    while (_memberQrKeys.length < memberDebts.length) {
      _memberQrKeys.add(GlobalKey());
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
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'ดาวน์โหลดสรุปบิล',
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
                'เลือกประเภทสรุปที่ต้องการบันทึก',
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
                    'รูปสรุปรวม + QR พร้อมเพย์ (${qrRecipients.length} QR)',
                icon: Icons.receipt_long_rounded,
                selected: _mode == _DownloadMode.fullBill,
                isDark: isDark,
                onTap: () => setState(() => _mode = _DownloadMode.fullBill),
              ),
              const SizedBox(height: 8),
              _ModeCard(
                title: 'สรุปรายบุคคล',
                subtitle: 'รูปสรุปของคนที่เลือก + QR ของคนที่ต้องโอนให้',
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
                      onTap: () =>
                          setState(() => _selectedMemberId = m.id),
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
                          borderRadius:
                              BorderRadius.circular(AppRadii.xl),
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

              // Preview section (off-screen render targets)
              // We use Offstage so widgets are laid out but not visible
              if (_mode == _DownloadMode.fullBill) ...[
                Offstage(
                  child: RepaintBoundary(
                    key: _fullSummaryKey,
                    child: BillFullSummaryImage(
                      bill: bill,
                      calc: calc,
                      allDebts: _allDebts,
                    ),
                  ),
                ),
                ...List.generate(qrRecipients.length, (i) {
                  final r = qrRecipients[i];
                  return Offstage(
                    child: RepaintBoundary(
                      key: _qrKeys[i],
                      child: BillQrCardImage(
                        bill: bill,
                        toMember: r.member,
                        amount: r.totalOwed,
                      ),
                    ),
                  );
                }),
              ] else if (_mode == _DownloadMode.memberSummary &&
                  _selectedMemberId != null &&
                  memberSummary != null) ...[
                Offstage(
                  child: RepaintBoundary(
                    key: _memberSummaryKey,
                    child: BillMemberSummaryImage(
                      bill: bill,
                      summary: memberSummary,
                      memberDebts: _debtsForMember(_selectedMemberId!),
                    ),
                  ),
                ),
                ...List.generate(memberDebts.length, (i) {
                  final debt = memberDebts[i];
                  final selectedMember = members.firstWhere(
                      (m) => m.id == _selectedMemberId,
                      orElse: () => members.first);
                  return Offstage(
                    child: RepaintBoundary(
                      key: _memberQrKeys[i],
                      child: BillQrCardImage(
                        bill: bill,
                        toMember: debt.to,
                        amount: debt.amount,
                        fromName: selectedMember.name,
                      ),
                    ),
                  );
                }),
              ],

              // Image count info
              _ImageCountInfo(
                mode: _mode,
                membersWithQrCount: qrRecipients.length,
                memberDebtsWithQrCount: memberDebts.length,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Download button — mobile: save to gallery, web: download file or share
              if (!kIsWeb)
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
                        : const Icon(Icons.download_rounded,
                            size: 18, color: Colors.white),
                    label: Text(
                      _saving ? 'กำลังบันทึก...' : 'บันทึกรูปภาพ',
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
              // Web buttons: Download + Share (if Web Share API available)
              if (kIsWeb) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : () => _download(shareOnWeb: false),
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download_rounded,
                            size: 18, color: Colors.white),
                    label: Text(
                      _saving ? 'กำลังดาวน์โหลด...' : 'ดาวน์โหลดรูปภาพ',
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
                if (webShareSupported) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : () => _download(shareOnWeb: true),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: Text(
                        'แชร์รูปภาพ',
                        style: GoogleFonts.sarabun(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.xl),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
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
                    : (isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight),
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

// ─── Image Count Info ─────────────────────────────────────────────────────────
class _ImageCountInfo extends StatelessWidget {
  final _DownloadMode mode;
  final int membersWithQrCount;
  final int memberDebtsWithQrCount;
  final bool isDark;

  const _ImageCountInfo({
    required this.mode,
    required this.membersWithQrCount,
    required this.memberDebtsWithQrCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final int totalImages = mode == _DownloadMode.fullBill
        ? 1 + membersWithQrCount
        : 1 + memberDebtsWithQrCount;

    final String detail = mode == _DownloadMode.fullBill
        ? '1 รูปสรุปรวม + $membersWithQrCount รูป QR พร้อมเพย์'
        : '1 รูปสรุปส่วนตัว + $memberDebtsWithQrCount รูป QR พร้อมเพย์';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.photo_library_rounded,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'จะบันทึก $totalImages รูป',
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
