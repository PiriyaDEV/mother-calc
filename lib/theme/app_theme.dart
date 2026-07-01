import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Light Brand ───────────────────────────────────────────────
  static const primaryDeepNavy = Color(0xFF0B1E3D);
  static const primaryBlue = Color(0xFF2D5BFF);
  static const accentSky = Color(0xFF6EC6FF);
  static const accentIce = Color(0xFFBFE3FF);
  static const accentAqua = Color(0xFF7FE0D6);

  // ── Light Neutrals ────────────────────────────────────────────
  static const neutral50 = Color(0xFFF5F8FC);
  static const neutral100 = Color(0xFFE9EEF6);
  static const neutral400 = Color(0xFF9AA7BD);
  static const neutral600 = Color(0xFF5C6B85);
  static const neutral900 = Color(0xFF10162B);
  static const surfaceWhite = Color(0xFFFFFFFF);

  // ── Dark Brand ────────────────────────────────────────────────
  static const primaryBlueDark = Color(0xFF5B82FF);
  static const accentSkyDark = Color(0xFF7FD0FF);
  static const accentIceDark = Color(0xFF1C2C49);
  static const accentAquaDark = Color(0xFF5FC9BD);

  // ── Dark Neutrals ─────────────────────────────────────────────
  static const bgDark = Color(0xFF0A0F1E);
  static const surfaceDark = Color(0xFF121A2E);
  static const borderDark = Color(0xFF26314F);
  static const neutral400Dark = Color(0xFF7C89A8);
  static const neutral600Dark = Color(0xFFA8B4CC);
  static const neutral900Dark = Color(0xFFF2F5FA);

  // ── Light surface/bg aliases (backward compat) ────────────────
  static const bgLight = neutral50;
  static const surfaceLight = surfaceWhite;
  static const borderLight = neutral100;
  static const textPrimaryLight = neutral900;
  static const textSecondaryLight = neutral600;
  static const textTertiaryLight = neutral400;

  // ── Dark text aliases (backward compat) ───────────────────────
  static const textPrimaryDark = neutral900Dark;
  static const textSecondaryDark = neutral600Dark;
  static const textTertiaryDark = neutral400Dark;

  // ── Primary aliases (backward compat) ────────────────────────
  static const primary = primaryBlue;
  static const primaryDark = Color(0xFF1A3FCC);
  static const primaryLight = accentSky;
  static const primaryFaint = accentIce;

  // ── Member avatar palette ─────────────────────────────────────
  static const List<Color> memberColors = [
    Color(0xFF2D5BFF),
    Color(0xFF6EC6FF),
    Color(0xFF7FE0D6),
    Color(0xFF0B1E3D),
    Color(0xFF34C77B),
    Color(0xFF5FC9BD),
    Color(0xFF5B82FF),
    Color(0xFF7FD0FF),
    Color(0xFF9AA7BD),
    Color(0xFF5C6B85),
  ];

  // ── Semantic: success ─────────────────────────────────────────
  static const emerald = Color(0xFF34C77B);
  static const emeraldLight = Color(0xFFD1FAE5);
  static const emeraldDark = Color(0xFF3DDB8C);
  static const emeraldText = Color(0xFF27A566);

  // ── Emerald/blue scale (bill payment-status UI) — distinct shades
  // from `emerald`/`primaryBlue` above, not aliases of them.
  static const emerald50 = Color(0xFFECFDF5);
  static const emerald100 = Color(0xFFD1FAE5);
  static const emerald200 = Color(0xFFA7F3D0);
  static const emerald500 = Color(0xFF10B981);
  static const emerald600 = Color(0xFF059669);
  static const emerald700 = Color(0xFF065F46);
  static const blue400 = Color(0xFF4366f4);
  static const blue500 = Color(0xFF6b8aff);

  // ── Semantic: error ───────────────────────────────────────────
  static const red = Color(0xFFFF5C5C);
  static const redDark = Color(0xFFFF7A7A);

  // ── Semantic: warning ─────────────────────────────────────────
  static const amber = Color(0xFFFFB23E);
  static const amberDark = Color(0xFFFFC25F);
  static const amberLight = Color(0xFFFFF3DC);
  static const amberText = Color(0xFFCC8A00);

  // ── Faint tonal backgrounds for icon badges ───────────────────
  static const amberFaint = Color(0xFFFFF7E8);
  static const redFaint = Color(0xFFFFEEEE);
  static const greenFaint = Color(0xFFEEFBF4);

  // ── Shadow tokens ─────────────────────────────────────────────
  static const shadowSubtle = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
  ];
  static const shadowCard = [
    BoxShadow(color: Color(0x142D5BFF), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const shadowFloat = [
    BoxShadow(color: Color(0x1F2D5BFF), blurRadius: 32, offset: Offset(0, 12)),
  ];
  static const shadowCardDark = [
    BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
}

class AppGradients {
  static const backgroundLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8F2FF), Color(0xFFCFE3FF), Color(0xFFA9C8FF)],
  );

  static const backgroundDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B132B), Color(0xFF101E3D), Color(0xFF16284F)],
  );

  static const primaryButtonLight = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF2D5BFF), Color(0xFF1A3FCC)],
  );

  static const primaryButtonDark = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF5B82FF), Color(0xFF3D5FE0)],
  );
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

class AppRadii {
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 20.0;
  static const double lg = 28.0;
  static const double xl = 20.0;
  static const double full = 999.0;
}

class ThemeColors {
  static Color bg(bool isDark) => isDark ? AppColors.bgDark : AppColors.bgLight;
  static Color surface(bool isDark) => isDark ? AppColors.surfaceDark : AppColors.surfaceWhite;
  static Color border(bool isDark) => isDark ? AppColors.borderDark : AppColors.borderLight;
  static Color textPrimary(bool isDark) => isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  static Color textSecondary(bool isDark) => isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  static Color textTertiary(bool isDark) => isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
  static Color primary(bool isDark) => isDark ? AppColors.primaryBlueDark : AppColors.primaryBlue;
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.accentSky,
        surface: AppColors.surfaceWhite,
        error: AppColors.red,
        onPrimary: Colors.white,
        onSurface: AppColors.neutral900,
        outline: AppColors.neutral100,
      ),
      scaffoldBackgroundColor: AppColors.bgLight,
      textTheme: _buildTextTheme(AppColors.neutral900, AppColors.neutral600),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.notoSansThai(
          color: AppColors.neutral900,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.neutral600),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceWhite,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.neutral400,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: const BorderSide(color: AppColors.neutral100),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: const BorderSide(color: AppColors.neutral100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: const BorderSide(color: AppColors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.notoSansThai(
          color: AppColors.neutral400,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          minimumSize: const Size(double.infinity, 48),
          textStyle: GoogleFonts.notoSansThai(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.neutral900,
          side: const BorderSide(color: AppColors.neutral100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          minimumSize: const Size(double.infinity, 48),
          textStyle: GoogleFonts.notoSansThai(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        shadowColor: const Color(0x142D5BFF),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.neutral100,
        thickness: 1,
        space: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primaryBlue : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primaryBlue.withValues(alpha: 0.4)
              : AppColors.neutral100,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primaryBlue,
        thumbColor: AppColors.primaryBlue,
        overlayColor: Color(0x142D5BFF),
        inactiveTrackColor: AppColors.neutral100,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryBlueDark,
        secondary: AppColors.accentSkyDark,
        surface: AppColors.surfaceDark,
        error: AppColors.redDark,
        onPrimary: Colors.white,
        onSurface: AppColors.neutral900Dark,
        outline: AppColors.borderDark,
      ),
      scaffoldBackgroundColor: AppColors.bgDark,
      textTheme: _buildTextTheme(AppColors.neutral900Dark, AppColors.neutral600Dark),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgDark.withValues(alpha: 0.95),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.notoSansThai(
          color: AppColors.neutral900Dark,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.neutral600Dark),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primaryBlueDark,
        unselectedItemColor: AppColors.neutral400Dark,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: const BorderSide(color: AppColors.primaryBlueDark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: const BorderSide(color: AppColors.redDark),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.notoSansThai(
          color: AppColors.neutral400Dark,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlueDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          minimumSize: const Size(double.infinity, 48),
          textStyle: GoogleFonts.notoSansThai(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.neutral900Dark,
          side: const BorderSide(color: AppColors.borderDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          minimumSize: const Size(double.infinity, 48),
          textStyle: GoogleFonts.notoSansThai(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
        space: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primaryBlueDark
              : AppColors.neutral400Dark,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primaryBlueDark.withValues(alpha: 0.4)
              : AppColors.borderDark,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primaryBlueDark,
        thumbColor: AppColors.primaryBlueDark,
        overlayColor: Color(0x145B82FF),
        inactiveTrackColor: AppColors.borderDark,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
    return TextTheme(
      displayLarge: GoogleFonts.anuphan(
        fontSize: 32, fontWeight: FontWeight.w700, height: 1.2, color: primaryColor),
      headlineMedium: GoogleFonts.anuphan(
        fontSize: 24, fontWeight: FontWeight.w700, height: 1.25, color: primaryColor),
      titleLarge: GoogleFonts.anuphan(
        fontSize: 20, fontWeight: FontWeight.w600, height: 1.3, color: primaryColor),
      titleMedium: GoogleFonts.notoSansThai(
        fontSize: 17, fontWeight: FontWeight.w600, height: 1.35, color: primaryColor),
      titleSmall: GoogleFonts.notoSansThai(
        fontSize: 15, fontWeight: FontWeight.w600, height: 1.35, color: primaryColor),
      bodyLarge: GoogleFonts.notoSansThai(
        fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: primaryColor),
      bodyMedium: GoogleFonts.notoSansThai(
        fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: secondaryColor),
      bodySmall: GoogleFonts.notoSansThai(
        fontSize: 12, fontWeight: FontWeight.w400, height: 1.4, color: secondaryColor),
      labelLarge: GoogleFonts.notoSansThai(
        fontSize: 14, fontWeight: FontWeight.w600, height: 1.3, color: primaryColor),
      labelSmall: GoogleFonts.notoSansThai(
        fontSize: 12, fontWeight: FontWeight.w400, height: 1.4, color: secondaryColor),
    );
  }
}
