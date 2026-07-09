import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ─── Color constants (matching AppColors) ────────────────────────────────────
const _primary = PdfColor.fromInt(0xFF4F7FFF);
const _primaryLight = PdfColor.fromInt(0xFFEEF3FF);
const _textPrimary = PdfColor.fromInt(0xFF1A1A2E);
const _textSecondary = PdfColor.fromInt(0xFF4A4A6A);
const _textTertiary = PdfColor.fromInt(0xFF9090A0);
const _border = PdfColor.fromInt(0xFFE0E4F0);
const _bgSubtle = PdfColor.fromInt(0xFFF5F7FF);
const _white = PdfColors.white;

// ─── BillPdfGenerator ─────────────────────────────────────────────────────────
/// Generates a PDF document for a bill summary.
///
/// Full bill mode: page 1 = full summary, subsequent pages = QR card per
/// member that has PromptPay and is owed money.
///
/// Per-member mode: page 1 = member summary, subsequent pages = QR card per
/// debt that has PromptPay.
class BillPdfGenerator {
  final Bill bill;
  final BillCalculation calc;
  final List<DebtTransaction> allDebts;

  BillPdfGenerator({
    required this.bill,
    required this.calc,
    required this.allDebts,
  });

  // ── Public entry points ──────────────────────────────────────────────────

  Future<Uint8List> generateFullBillPdf() async {
    final doc = pw.Document();
    final fonts = await _loadFonts();
    final logoImage = await _loadLogoImage();

    // Page 1: full summary
    doc.addPage(_buildFullSummaryPage(fonts, logoImage));

    // Subsequent pages: QR cards for members with PromptPay
    final qrRecipients = _qrRecipients;
    for (final r in qrRecipients) {
      final qrImage = await _fetchQrImage(r.member.promptpay!, r.totalOwed);
      doc.addPage(_buildQrPage(fonts, logoImage, r.member, r.totalOwed,
          qrImage: qrImage));
    }

    return doc.save();
  }

  Future<Uint8List> generateMemberPdf(BillMember member) async {
    final doc = pw.Document();
    final fonts = await _loadFonts();
    final logoImage = await _loadLogoImage();

    final memberSummary = calc.memberSummaries.firstWhere(
      (s) => s.member.id == member.id,
      orElse: () => MemberSummary(member: member, total: 0, items: []),
    );
    final memberDebts =
        allDebts.where((d) => d.from.id == member.id).toList();

    // Page 1: member summary
    doc.addPage(
        _buildMemberSummaryPage(fonts, logoImage, memberSummary, memberDebts));

    // Subsequent pages: QR cards for debts with PromptPay
    final debtsWithQr = memberDebts
        .where((d) => d.to.promptpay != null && d.to.promptpay!.isNotEmpty)
        .toList();
    for (final debt in debtsWithQr) {
      final qrImage = await _fetchQrImage(debt.to.promptpay!, debt.amount);
      doc.addPage(_buildQrPage(
        fonts,
        logoImage,
        debt.to,
        debt.amount,
        qrImage: qrImage,
        fromName: member.name,
      ));
    }

    return doc.save();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<({BillMember member, double totalOwed})> get _qrRecipients {
    final result = <({BillMember member, double totalOwed})>[];
    for (final m in bill.members) {
      if (m.promptpay == null || m.promptpay!.isEmpty) continue;
      final owed = allDebts
          .where((d) => d.to.id == m.id)
          .fold<double>(0, (sum, d) => sum + d.amount);
      if (owed > 0) result.add((member: m, totalOwed: owed));
    }
    return result;
  }

  /// Fetches QR code PNG from the PromptPay QR API.
  ///
  /// On web: uses the Netlify proxy `/promptpay-qr/<number>/<amount>.png`
  /// (relative to the app's origin, resolved via Uri.base which is web-only).
  ///
  /// On mobile/desktop: calls the public PromptPay QR API directly at
  /// `https://promptpay.io/<number>/<amount>.png`.
  ///
  /// Returns null if the fetch fails (QR section will be omitted gracefully).
  Future<pw.ImageProvider?> _fetchQrImage(
      String promptpay, double amount) async {
    try {
      final amountStr = amount.toStringAsFixed(2);
      Uri uri;
      if (kIsWeb) {
        // Uri.base is only available on web — gives the browser's current URL
        final base = Uri.base;
        final origin =
            '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';
        uri = Uri.parse('$origin/promptpay-qr/$promptpay/$amountStr.png');
      } else {
        // On mobile/desktop, call the public PromptPay QR API directly
        uri = Uri.parse(
            'https://promptpay.io/$promptpay/$amountStr.png');
      }
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      }
      debugPrint(
          '[BillPdfGenerator._fetchQrImage]: status ${response.statusCode} for $uri');
    } catch (e) {
      debugPrint('[BillPdfGenerator._fetchQrImage]: $e');
    }
    return null;
  }

  Future<_Fonts> _loadFonts() async {
    // Use a bundled font that supports Thai — NotoSansThai
    // The pdf package ships with Helvetica but it doesn't support Thai.
    // We load NotoSansThai from google_fonts cache or fall back to built-in.
    // Since we can't guarantee the font file path, we use the pdf built-in
    // font for Latin and embed NotoSansThai for Thai text.
    //
    // Strategy: load NotoSansThai TTF from assets if available, otherwise
    // fall back to pdf's built-in Helvetica (Thai chars will be boxes but
    // numbers/Latin will be fine).
    pw.Font? regular;
    pw.Font? bold;
    try {
      final regularData =
          await rootBundle.load('assets/fonts/NotoSansThai-Regular.ttf');
      final boldData =
          await rootBundle.load('assets/fonts/NotoSansThai-Bold.ttf');
      regular = pw.Font.ttf(regularData);
      bold = pw.Font.ttf(boldData);
    } catch (_) {
      // Font not bundled — use pdf built-in (Latin only)
      regular = pw.Font.helvetica();
      bold = pw.Font.helveticaBold();
    }
    return _Fonts(regular: regular, bold: bold);
  }

  Future<pw.ImageProvider?> _loadLogoImage() async {
    try {
      final data = await rootBundle.load('assets/images/logo.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  // ── Page builders ─────────────────────────────────────────────────────────

  pw.Page _buildFullSummaryPage(
      _Fonts fonts, pw.ImageProvider? logo) {
    final currency = bill.settings.currency;

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildHeader(fonts, logo),
          pw.SizedBox(height: 20),

          // Bill title
          pw.Row(
            children: [
              pw.Text(
                bill.title,
                style: pw.TextStyle(
                  font: fonts.bold,
                  fontSize: 20,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'สรุปบิลทั้งหมด',
            style: pw.TextStyle(
                font: fonts.regular, fontSize: 11, color: _textTertiary),
          ),
          pw.SizedBox(height: 16),

          // Grand total box
          _buildTotalBox(fonts, 'ยอดรวมทั้งสิ้น', calc.total, currency),
          pw.SizedBox(height: 20),

          // Members section
          _buildSectionTitle(fonts, 'ส่วนแบ่งแต่ละคน'),
          pw.SizedBox(height: 8),
          ...calc.memberSummaries.map((s) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 8,
                      height: 8,
                      decoration: pw.BoxDecoration(
                        color: _pdfColorFromHex(s.member.color),
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Text(
                        s.member.name,
                        style: pw.TextStyle(
                            font: fonts.regular,
                            fontSize: 12,
                            color: _textPrimary),
                      ),
                    ),
                    pw.Text(
                      '${formatNumber(s.total)} $currency',
                      style: pw.TextStyle(
                          font: fonts.bold,
                          fontSize: 12,
                          color: _textPrimary),
                    ),
                  ],
                ),
              )),

          if (allDebts.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Divider(color: _border),
            pw.SizedBox(height: 12),
            _buildSectionTitle(fonts, 'ใครโอนให้ใคร'),
            pw.SizedBox(height: 8),
            ...allDebts.map((d) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        d.from.name,
                        style: pw.TextStyle(
                            font: fonts.regular,
                            fontSize: 12,
                            color: _textPrimary),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Text(
                        '→',
                        style: pw.TextStyle(
                            font: fonts.regular,
                            fontSize: 12,
                            color: _textTertiary),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Expanded(
                        child: pw.Text(
                          d.to.name,
                          style: pw.TextStyle(
                              font: fonts.regular,
                              fontSize: 12,
                              color: _textPrimary),
                        ),
                      ),
                      pw.Text(
                        '${formatNumber(d.amount)} $currency',
                        style: pw.TextStyle(
                            font: fonts.bold,
                            fontSize: 12,
                            color: _textPrimary),
                      ),
                    ],
                  ),
                )),
          ],

          pw.Spacer(),
          _buildFooter(fonts),
        ],
      ),
    );
  }

  pw.Page _buildMemberSummaryPage(
    _Fonts fonts,
    pw.ImageProvider? logo,
    MemberSummary summary,
    List<DebtTransaction> memberDebts,
  ) {
    final currency = bill.settings.currency;
    final member = summary.member;

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildHeader(fonts, logo),
          pw.SizedBox(height: 20),

          // Bill title
          pw.Text(
            bill.title,
            style: pw.TextStyle(
                font: fonts.bold, fontSize: 16, color: _textSecondary),
          ),
          pw.SizedBox(height: 8),

          // Member name
          pw.Row(
            children: [
              pw.Container(
                width: 10,
                height: 10,
                decoration: pw.BoxDecoration(
                  color: _pdfColorFromHex(member.color),
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'สรุปของ ${member.name}',
                style: pw.TextStyle(
                    font: fonts.bold, fontSize: 14, color: _textPrimary),
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Items ordered
          if (summary.items.isNotEmpty) ...[
            _buildSectionTitle(fonts, 'รายการที่สั่ง'),
            pw.SizedBox(height: 6),
            ...summary.items.map((itemShare) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    children: [
                      pw.Text('• ',
                          style: pw.TextStyle(
                              font: fonts.regular,
                              fontSize: 11,
                              color: _textTertiary)),
                      pw.Expanded(
                        child: pw.Text(
                          itemShare.item.name,
                          style: pw.TextStyle(
                              font: fonts.regular,
                              fontSize: 12,
                              color: _textSecondary),
                        ),
                      ),
                      pw.Text(
                        '${formatNumber(itemShare.amount)} $currency',
                        style: pw.TextStyle(
                            font: fonts.regular,
                            fontSize: 12,
                            color: _textSecondary),
                      ),
                    ],
                  ),
                )),
            pw.SizedBox(height: 8),
            pw.Divider(color: _border),
            pw.SizedBox(height: 8),
          ],

          // Total
          _buildTotalBox(fonts, 'รวม (รวม VAT/SC)', summary.total, currency),

          // Debts
          if (memberDebts.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildSectionTitle(fonts, 'ต้องโอนให้'),
            pw.SizedBox(height: 8),
            ...memberDebts.map((d) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: _bgSubtle,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: _border),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Text(
                          '→ ',
                          style: pw.TextStyle(
                              font: fonts.regular,
                              fontSize: 12,
                              color: _textTertiary),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            d.to.name,
                            style: pw.TextStyle(
                                font: fonts.bold,
                                fontSize: 12,
                                color: _textPrimary),
                          ),
                        ),
                        pw.Text(
                          '${formatNumber(d.amount)} $currency',
                          style: pw.TextStyle(
                              font: fonts.bold,
                              fontSize: 12,
                              color: _textPrimary),
                        ),
                      ],
                    ),
                  ),
                )),
          ],

          pw.Spacer(),
          _buildFooter(fonts),
        ],
      ),
    );
  }

  pw.Page _buildQrPage(
    _Fonts fonts,
    pw.ImageProvider? logo,
    BillMember toMember,
    double amount, {
    pw.ImageProvider? qrImage,
    String? fromName,
  }) {
    final currency = bill.settings.currency;
    final promptpay = toMember.promptpay ?? '';

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          _buildHeader(fonts, logo),
          pw.SizedBox(height: 24),

          // Bill title
          pw.Text(
            bill.title,
            style: pw.TextStyle(
                font: fonts.bold, fontSize: 14, color: _textSecondary),
            textAlign: pw.TextAlign.center,
          ),
          if (fromName != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              '$fromName → ${toMember.name}',
              style: pw.TextStyle(
                  font: fonts.regular, fontSize: 12, color: _textTertiary),
              textAlign: pw.TextAlign.center,
            ),
          ],
          pw.SizedBox(height: 24),

          // QR code
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: _white,
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: _border, width: 1.5),
            ),
            child: qrImage != null
                ? pw.Image(qrImage, width: 220, height: 220)
                : pw.Container(
                    width: 220,
                    height: 220,
                    color: _bgSubtle,
                    child: pw.Center(
                      child: pw.Text(
                        'QR Code\n$promptpay',
                        style: pw.TextStyle(
                            font: fonts.regular,
                            fontSize: 12,
                            color: _textTertiary),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ),
          ),
          pw.SizedBox(height: 16),

          // Recipient name
          pw.Text(
            'PromptPay ของ ${toMember.name}',
            style: pw.TextStyle(
                font: fonts.bold, fontSize: 14, color: _textPrimary),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            promptpay,
            style: pw.TextStyle(
                font: fonts.regular, fontSize: 12, color: _textTertiary),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 16),

          // Amount badge
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: pw.BoxDecoration(
              color: _primaryLight,
              borderRadius: pw.BorderRadius.circular(24),
            ),
            child: pw.Text(
              '${formatNumber(amount)} $currency',
              style: pw.TextStyle(
                  font: fonts.bold, fontSize: 18, color: _primary),
            ),
          ),

          pw.Spacer(),
          _buildFooter(fonts),
        ],
      ),
    );
  }

  // ── Shared widgets ────────────────────────────────────────────────────────

  pw.Widget _buildHeader(_Fonts fonts, pw.ImageProvider? logo) {
    return pw.Row(
      children: [
        if (logo != null) ...[
          pw.Image(logo, width: 24, height: 24),
          pw.SizedBox(width: 8),
        ],
        pw.Text(
          'Kidtang',
          style:
              pw.TextStyle(font: fonts.bold, fontSize: 16, color: _primary),
        ),
        pw.Spacer(),
        pw.Text(
          _formatDate(bill.createdAt),
          style: pw.TextStyle(
              font: fonts.regular, fontSize: 10, color: _textTertiary),
        ),
      ],
    );
  }

  pw.Widget _buildTotalBox(
      _Fonts fonts, String label, double amount, String currency) {
    return pw.Container(
      width: double.infinity,
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: pw.BoxDecoration(
        color: _primaryLight,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
                font: fonts.bold, fontSize: 13, color: _primary),
          ),
          pw.Text(
            '${formatNumber(amount)} $currency',
            style: pw.TextStyle(
                font: fonts.bold, fontSize: 15, color: _primary),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle(_Fonts fonts, String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
          font: fonts.bold, fontSize: 11, color: _textTertiary),
    );
  }

  pw.Widget _buildFooter(_Fonts fonts) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(
        color: _primaryLight,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            'สร้างด้วย Kidtang — แอปหารค่าใช้จ่าย',
            style: pw.TextStyle(
                font: fonts.regular, fontSize: 10, color: _primary),
          ),
        ],
      ),
    );
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  static PdfColor _pdfColorFromHex(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      final value = int.parse(clean, radix: 16);
      return PdfColor.fromInt(0xFF000000 | value);
    } catch (_) {
      return _primary;
    }
  }

  static String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _Fonts {
  final pw.Font regular;
  final pw.Font bold;
  const _Fonts({required this.regular, required this.bold});
}
