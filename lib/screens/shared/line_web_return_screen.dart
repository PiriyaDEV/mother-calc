import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

/// Shown after a LINE web login completes in a plain Safari tab instead of
/// the installed home-screen PWA. iOS never hands an external OAuth
/// redirect back to a standalone PWA instance — this tells the user to
/// switch back to it manually; the session itself already carried over via
/// shared origin storage (see AuthProvider._recoverSessionFromOtherTab).
class LineWebReturnScreen extends StatelessWidget {
  const LineWebReturnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = context.watch<LocaleProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppGradients.backgroundDark : AppGradients.backgroundLight,
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primaryBlue,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l.t('login_line_return_success'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sarabun(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${l.t('login_line_return_body')}${l.t('login_line_return_close')}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sarabun(
                      fontSize: 15,
                      height: 1.5,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
