import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;

  const PasswordField({
    super.key,
    required this.controller,
    required this.hint,
    required this.isDark,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      style: GoogleFonts.notoSansThai(fontSize: 14),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: GoogleFonts.notoSansThai(
          fontSize: 14,
          color: AppColors.textTertiaryLight,
        ),
        filled: true,
        fillColor:
            widget.isDark ? AppColors.borderDark : AppColors.neutral50,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(
            color: widget.isDark
                ? AppColors.borderDark
                : AppColors.neutral100,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(
            color: widget.isDark
                ? AppColors.borderDark
                : AppColors.neutral100,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscure = !_obscure),
          child: Icon(
            _obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 18,
            color: AppColors.textTertiaryLight,
          ),
        ),
      ),
    );
  }
}
