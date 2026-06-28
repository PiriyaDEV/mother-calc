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

class _LoginScreenState extends State<LoginScreen> {
  bool _lineLoading = false;
  bool _googleLoading = false;
  String? _error;

  Future<void> _signInWithLine() async {
    setState(() { _lineLoading = true; _error = null; });
    final err = await context.read<AuthProvider>().signInWithLine();
    if (mounted) setState(() { _lineLoading = false; _error = err; });
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _googleLoading = true; _error = null; });
    final err = await context.read<AuthProvider>().signInWithGoogle();
    if (mounted) setState(() { _googleLoading = false; _error = err; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/images/logo.png", width: 88, height: 88),
                const SizedBox(height: 20),
                Text("Kidtang",
                    style: GoogleFonts.notoSansThai(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    )),
                const SizedBox(height: 8),
                Text("\u0e41\u0e1a\u0e48\u0e07\u0e04\u0e48\u0e32\u0e43\u0e0a\u0e49\u0e08\u0e48\u0e32\u0e22\u0e07\u0e48\u0e32\u0e22\u0e46 \u0e01\u0e31\u0e1a\u0e40\u0e1e\u0e37\u0e48\u0e2d\u0e19",
                    style: GoogleFonts.notoSansThai(
                      fontSize: 14,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    )),
                const SizedBox(height: 52),
                _SocialButton(
                  onTap: _lineLoading || _googleLoading ? null : _signInWithLine,
                  isLoading: _lineLoading,
                  backgroundColor: const Color(0xFF06C755),
                  icon: _LineIcon(),
                  label: "\u0e40\u0e02\u0e49\u0e32\u0e2a\u0e39\u0e48\u0e23\u0e30\u0e1a\u0e1a\u0e14\u0e49\u0e27\u0e22 LINE",
                  labelColor: Colors.white,
                ),
                const SizedBox(height: 14),
                _SocialButton(
                  onTap: _lineLoading || _googleLoading ? null : _signInWithGoogle,
                  isLoading: _googleLoading,
                  backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
                  icon: _GoogleIcon(),
                  label: "\u0e40\u0e02\u0e49\u0e32\u0e2a\u0e39\u0e48\u0e23\u0e30\u0e1a\u0e1a\u0e14\u0e49\u0e27\u0e22 Google",
                  labelColor: isDark ? Colors.white : const Color(0xFF111827),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
                    width: 1.5,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.red.withOpacity(0.25)),
                    ),
                    child: Text(_error!,
                        style: GoogleFonts.notoSansThai(fontSize: 13, color: AppColors.red),
                        textAlign: TextAlign.center),
                  ),
                ],
                const SizedBox(height: 40),
                Text(
                  "\u0e01\u0e32\u0e23\u0e40\u0e02\u0e49\u0e32\u0e2a\u0e39\u0e48\u0e23\u0e30\u0e1a\u0e1a\u0e04\u0e23\u0e31\u0e49\u0e07\u0e41\u0e23\u0e01 \u0e23\u0e30\u0e1a\u0e1a\u0e08\u0e30\u0e2a\u0e23\u0e49\u0e32\u0e07\u0e1a\u0e31\u0e0d\u0e0a\u0e35\u0e43\u0e2b\u0e49\u0e42\u0e14\u0e22\u0e2d\u0e31\u0e15\u0e42\u0e19\u0e21\u0e31\u0e15\u0e34",
                  style: GoogleFonts.notoSansThai(
                    fontSize: 12,
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final Color backgroundColor;
  final Widget icon;
  final String label;
  final Color labelColor;
  final BoxBorder? border;

  const _SocialButton({
    required this.onTap,
    required this.isLoading,
    required this.backgroundColor,
    required this.icon,
    required this.label,
    required this.labelColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: onTap == null ? backgroundColor.withOpacity(0.5) : backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: border,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: isLoading
                  ? Center(
                      child: SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: labelColor),
                      ))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        icon,
                        const SizedBox(width: 10),
                        Text(label,
                            style: GoogleFonts.notoSansThai(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: labelColor,
                            )),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LineIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/line-logo.png',
      width: 22,
      height: 22,
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/google-logo.png',
      width: 22,
      height: 22,
    );
  }
}