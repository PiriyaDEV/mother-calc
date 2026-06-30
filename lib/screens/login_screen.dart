import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _lineLoading = false;
  bool _googleLoading = false;
  String? _error;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInWithLine() async {
    setState(() {
      _lineLoading = true;
      _error = null;
    });
    final err = await context.read<AuthProvider>().signInWithLine();
    if (mounted) {
      setState(() {
        _lineLoading = false;
        _error = err;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                          'แบ่งค่าใช้จ่ายง่ายๆ กับเพื่อน',
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
                        _SocialButton(
                          onTap: _lineLoading || _googleLoading
                              ? null
                              : _signInWithLine,
                          isLoading: _lineLoading,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF06C755), Color(0xFF00A843)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          icon: Image.asset(
                            'assets/images/line-logo.png',
                            width: 22,
                            height: 22,
                          ),
                          label: 'เข้าสู่ระบบด้วย LINE',
                          labelColor: Colors.white,
                          shadowColor: const Color(0xFF06C755),
                        ),
                        const SizedBox(height: 14),

                        // Google button
                        _SocialButton(
                          onTap: _lineLoading || _googleLoading
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
                          label: 'เข้าสู่ระบบด้วย Google',
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

                        const SizedBox(height: 40),
                        Text(
                          'การเข้าสู่ระบบครั้งแรก ระบบจะสร้างบัญชีให้โดยอัตโนมัติ',
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
  final Gradient? gradient;
  final Color? backgroundColor;
  final Widget icon;
  final String label;
  final Color labelColor;
  final BoxBorder? border;
  final Color? shadowColor;

  const _SocialButton({
    required this.onTap,
    required this.isLoading,
    this.gradient,
    this.backgroundColor,
    required this.icon,
    required this.label,
    required this.labelColor,
    this.border,
    this.shadowColor,
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
            gradient: isDisabled
                ? null
                : gradient,
            color: gradient == null
                ? (isDisabled
                    ? (backgroundColor ?? Colors.grey).withValues(alpha: 0.5)
                    : backgroundColor)
                : null,
            borderRadius: BorderRadius.circular(16),
            border: border,
            boxShadow: shadowColor != null && !isDisabled
                ? [
                    BoxShadow(
                      color: shadowColor!.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : border == null
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
