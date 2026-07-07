import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/auth_provider.dart';
import 'package:kidtang_flutter/services/google_web_button.dart';
// import 'package:kidtang_flutter/services/ios_install_prompt.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _googleLoading = false;
  String? _error;
  // bool _showIosInstallBanner = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    // Surfaces an error left behind by a LINE web login redirect, if any —
    // that flow tears down the whole app, so it can't return one directly.
    _error = context.read<AuthProvider>().consumeLineWebCallbackError();

    // Show iOS install banner if running in Safari on iOS and not already installed
    // if (isIosNotStandalone) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     if (mounted) setState(() => _showIosInstallBanner = true);
    //   });
    // }

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

    // On web, errors from Google sign-in come back via AuthProvider's
    // notifyListeners() (the GIS popup result lands on onCurrentUserChanged,
    // not a return value) — listen here to surface them.
    if (kIsWeb) context.read<AuthProvider>().addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    final error = context.read<AuthProvider>().consumeGoogleWebCallbackError();
    if (error != null && mounted) setState(() => _error = error);
  }

  @override
  void dispose() {
    if (kIsWeb) context.read<AuthProvider>().removeListener(_onAuthChanged);
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _googleLoading = true;
      _error = null;
    });
    final err = await context.read<AuthProvider>().signInWithGoogle();
    if (mounted) {
      setState(() {
        _googleLoading = false;
        _error = err;
      });
    }
  }

  // iOS Safari doesn't let a web app trigger "Add to Home Screen" itself —
  // this walks the user through the manual Share-sheet steps instead.
  // void _showIosInstallInstructions() {
  //     final l = context.read<LocaleProvider>();
  //   showDialog(
  //     context: context,
  //     barrierDismissible: true,
  //     builder: (dialogContext) {
  //       final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
  //       return Dialog(
  //         backgroundColor: Colors.transparent,
  //         insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
  //         child: Container(
  //           padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
  //           decoration: BoxDecoration(
  //             color: isDark ? AppColors.surfaceDark : Colors.white,
  //             borderRadius: BorderRadius.circular(20),
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 l.t('login_install_prompt'),
  //                 style: GoogleFonts.notoSansThai(
  //                   fontSize: 17,
  //                   fontWeight: FontWeight.bold,
  //                   color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
  //                 ),
  //               ),
  //               const SizedBox(height: 4),
  //               Text(
  //                 l.t('login_install_sub'),
  //                 style: GoogleFonts.notoSansThai(
  //                   fontSize: 13,
  //                   color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
  //                 ),
  //               ),
  //               const SizedBox(height: 24),
  //               _InstallStep(
  //                 number: 1,
  //                 icon: Icons.ios_share,
  //                 text: l.t('login_pwa_tap_share'),
  //                 isDark: isDark,
  //               ),
  //               const SizedBox(height: 16),
  //               _InstallStep(
  //                 number: 2,
  //                 icon: Icons.add_box_outlined,
  //                 text: l.t('login_pwa_scroll'),
  //                 isDark: isDark,
  //               ),
  //               const SizedBox(height: 16),
  //               _InstallStep(
  //                 number: 3,
  //                 icon: Icons.check_circle_outline,
  //                 text: l.t('login_pwa_tap_add'),
  //                 isDark: isDark,
  //               ),
  //               const SizedBox(height: 24),
  //               SizedBox(
  //                 width: double.infinity,
  //                 child: TextButton(
  //                   onPressed: () => Navigator.pop(dialogContext),
  //                   style: TextButton.styleFrom(
  //                     padding: const EdgeInsets.symmetric(vertical: 14),
  //                     backgroundColor: AppColors.primaryBlue.withValues(alpha: isDark ? 0.16 : 0.08),
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(12),
  //                     ),
  //                   ),
  //                   child: Text(
  //                     l.t('login_got_it'),
  //                     style: GoogleFonts.notoSansThai(
  //                       fontWeight: FontWeight.w600,
  //                       color: AppColors.primaryBlue,
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = context.watch<LocaleProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient background ──────────────────────────────
          Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              gradient: isDark ? AppGradients.backgroundDark : AppGradients.backgroundLight,
            ),
          ),

          // ── Decorative blobs ─────────────────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: _Blob(
              size: 260,
              color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.18 : 0.10),
            ),
          ),
          Positioned(
            top: 120,
            left: -100,
            child: _Blob(
              size: 200,
              color: AppColors.accentSky.withValues(alpha: isDark ? 0.12 : 0.08),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: _Blob(
              size: 220,
              color: AppColors.primaryDeepNavy.withValues(alpha: isDark ? 0.20 : 0.06),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -80,
            child: _Blob(
              size: 180,
              color: AppColors.accentSky.withValues(alpha: isDark ? 0.10 : 0.06),
            ),
          ),

          // ── Content ──────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),

                        // Logo with glow
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 32,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // App name
                        Text(
                          'Kidtang',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.t('login_tagline'),
                          style: GoogleFonts.notoSansThai(
                            fontSize: 15,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Feature pills
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _FeaturePill(label: '💸 หารบิล', isDark: isDark),
                            _FeaturePill(label: '👥 จัดกลุ่ม', isDark: isDark),
                            _FeaturePill(label: '📊 สรุปยอด', isDark: isDark),
                          ],
                        ),

                        const SizedBox(height: 52),

                        // LINE button
                        // _SocialButton(
                        //   onTap: _lineLoading || _googleLoading
                        //       ? null
                        //       : _signInWithLine,
                        //   isLoading: _lineLoading,
                        //   gradient: const LinearGradient(
                        //     colors: [Color(0xFF06C755), Color(0xFF00A843)],
                        //     begin: Alignment.topLeft,
                        //     end: Alignment.bottomRight,
                        //   ),
                        //   icon: Image.asset(
                        //     'assets/images/line-logo.png',
                        //     width: 22,
                        //     height: 22,
                        //   ),
                        //   label: 'เข้าสู่ระบบด้วย LINE',
                        //   labelColor: Colors.white,
                        //   shadowColor: const Color(0xFF06C755),
                        // ),
                        // const SizedBox(height: 14),

                        // Google button. On web this renders Google
                        // Identity Services' own button — clicking it opens
                        // Google's account chooser as a popup/overlay on
                        // this same page (no redirect through Supabase's
                        // domain). The result lands on the
                        // onCurrentUserChanged listener wired up in
                        // AuthProvider, not a return value here. Native
                        // platforms keep the app's own styled button, which
                        // calls signInWithGoogle() directly.
                        if (kIsWeb)
                          Center(
                            child: renderGoogleSignInButton(
                              clientId: context.read<AuthProvider>().googleWebClientId,
                              onCredential: (idToken, nonce) => context
                                  .read<AuthProvider>()
                                  .handleGoogleWebCredential(idToken, nonce),
                            ),
                          )
                        else
                          _SocialButton(
                            onTap: _googleLoading
                                ? null
                                : _signInWithGoogle,
                            isLoading: _googleLoading,
                            backgroundColor: isDark
                                ? AppColors.surfaceDark
                                : Colors.white,
                            icon: Image.asset(
                              'assets/images/google-logo.png',
                              width: 22,
                              height: 22,
                            ),
                            label: l.t('login_with_google'),
                            labelColor: isDark
                                ? Colors.white
                                : const Color(0xFF111827),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.neutral100,
                              width: 1.5,
                            ),
                          ),

                        // Error
                        if (_error != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.red.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              _error!,
                              style: GoogleFonts.notoSansThai(
                                  fontSize: 13, color: AppColors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],

                        // iOS Add to Home Screen banner (ปิดการแสดงผลชั่วคราว)
                        // if (_showIosInstallBanner) ...[
                        //   const SizedBox(height: 20),
                        //   Material(
                        //     color: Colors.transparent,
                        //     borderRadius: BorderRadius.circular(16),
                        //     child: InkWell(
                        //       onTap: _showIosInstallInstructions,
                        //       borderRadius: BorderRadius.circular(16),
                        //       child: Container(
                        //         width: double.infinity,
                        //         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        //         decoration: BoxDecoration(
                        //           color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.16 : 0.08),
                        //           borderRadius: BorderRadius.circular(16),
                        //           border: Border.all(
                        //             color: AppColors.primaryBlue.withValues(alpha: 0.18),
                        //           ),
                        //         ),
                        //         child: Row(
                        //           children: [
                        //             Container(
                        //               width: 34,
                        //               height: 34,
                        //               decoration: BoxDecoration(
                        //                 color: AppColors.primaryBlue,
                        //                 borderRadius: BorderRadius.circular(10),
                        //               ),
                        //               child: const Icon(
                        //                 Icons.ios_share,
                        //                 size: 17,
                        //                 color: Colors.white,
                        //               ),
                        //             ),
                        //             const SizedBox(width: 12),
                        //             Expanded(
                        //               child: Column(
                        //                 crossAxisAlignment: CrossAxisAlignment.start,
                        //                 children: [
                        //                   Text(
                        //                     'บันทึกไปที่หน้าจอหลัก',
                        //                     style: GoogleFonts.notoSansThai(
                        //                       fontSize: 13,
                        //                       fontWeight: FontWeight.w600,
                        //                       color: isDark
                        //                           ? AppColors.textPrimaryDark
                        //                           : AppColors.textPrimaryLight,
                        //                     ),
                        //                   ),
                        //                   const SizedBox(height: 2),
                        //                   Text(
                        //                     'แตะเพื่อดูวิธี Add to Home Screen',
                        //                     style: GoogleFonts.notoSansThai(
                        //                       fontSize: 11,
                        //                       color: isDark
                        //                           ? AppColors.textSecondaryDark
                        //                           : AppColors.textSecondaryLight,
                        //                     ),
                        //                   ),
                        //                 ],
                        //               ),
                        //             ),
                        //             const Icon(
                        //               Icons.chevron_right,
                        //               size: 20,
                        //               color: AppColors.primaryBlue,
                        //             ),
                        //             GestureDetector(
                        //               onTap: () => setState(() => _showIosInstallBanner = false),
                        //               child: Padding(
                        //                 padding: const EdgeInsets.all(4),
                        //                 child: Icon(
                        //                   Icons.close,
                        //                   size: 16,
                        //                   color: isDark
                        //                       ? AppColors.textTertiaryDark
                        //                       : AppColors.textTertiaryLight,
                        //                 ),
                        //               ),
                        //             ),
                        //           ],
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                        // ],

                        const SizedBox(height: 40),
                        Text(
                          l.t('login_first_time'),
                          style: GoogleFonts.notoSansThai(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── iOS install step ──────────────────────────────────────────
// class _InstallStep extends StatelessWidget {
//   final int number;
//   final IconData icon;
//   final String text;
//   final bool isDark;

//   const _InstallStep({
//     required this.number,
//     required this.icon,
//     required this.text,
//     required this.isDark,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           width: 28,
//           height: 28,
//           alignment: Alignment.center,
//           decoration: BoxDecoration(
//             color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.18 : 0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Text(
//             '$number',
//             style: GoogleFonts.notoSansThai(
//               fontSize: 13,
//               fontWeight: FontWeight.w700,
//               color: AppColors.primaryBlue,
//             ),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Padding(
//             padding: const EdgeInsets.only(top: 4),
//             child: Text(
//               text,
//               style: GoogleFonts.notoSansThai(
//                 fontSize: 14,
//                 color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(width: 8),
//         Icon(icon, size: 20, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
//       ],
//     );
//   }
// }

// ── Decorative blob ───────────────────────────────────────────
class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── Feature pill ──────────────────────────────────────────────
class _FeaturePill extends StatelessWidget {
  final String label;
  final bool isDark;
  const _FeaturePill({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : AppColors.neutral100,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Text(
        label,
        style: GoogleFonts.notoSansThai(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}

// ── Social button ─────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final Color? backgroundColor;
  final Widget icon;
  final String label;
  final Color labelColor;
  final BoxBorder? border;

  const _SocialButton({
    required this.onTap,
    required this.isLoading,
    this.backgroundColor,
    required this.icon,
    required this.label,
    required this.labelColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: isDisabled
                ? (backgroundColor ?? Colors.grey).withValues(alpha: 0.5)
                : backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: border,
            boxShadow: border == null
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: isLoading
                  ? Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: labelColor,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        icon,
                        const SizedBox(width: 12),
                        Text(
                          label,
                          style: GoogleFonts.notoSansThai(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: labelColor,
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

// ignore: unused_element
double _deg(double deg) => deg * math.pi / 180;
