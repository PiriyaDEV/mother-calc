import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Primary Blue (Clubhouse blue-light palette) ───────────────
  static const primary = Color(0xFF2F6FED);          // main action blue
  static const primaryHover = Color(0xFF1E5AD1);     // hover / pressed
  static const primaryLight = Color(0xFFEAF1FF);     // very light blue bg
  static const accent = Color(0xFF5B9BFF);           // secondary highlight / avatar ring

  // ── Background & Surface ──────────────────────────────────────
  static const bgLight = Color(0xFFF5F8FF);          // app background (light)
  static const bgSubtle = Color(0xFFF5F8FF);         // alias for bgLight
  static const surface = Color(0xFFFFFFFF);          // cards / sheets (light)
  static const surfaceWhite = Color(0xFFFFFFFF);     // cards / sheets
  static const borderLight = Color(0xFFE3ECFB);      // 1px dividers / card borders

  // ── Text (Light) ──────────────────────────────────────────────
  static const textPrimaryLight = Color(0xFF101828);
  static const textSecondaryLight = Color(0xFF5B6472);
  static const textTertiaryLight = Color(0xFF98A2B3);

  // ── Dark Mode ─────────────────────────────────────────────────
  static const bgDark = Color(0xFF0A0F1E);
  static const surfaceDark = Color(0xFF121A2E);
  static const borderDark = Color(0xFF26314F);
  static const primaryBlueDark = Color(0xFF5B9BFF);  // accent blue in dark

  // ── Text (Dark) ───────────────────────────────────────────────
  static const textPrimaryDark = Color(0xFFF2F5FA);
  static const textSecondaryDark = Color(0xFFA8B4CC);
  static const textTertiaryDark = Color(0xFF6B7A99);

  // ── Semantic: Success ─────────────────────────────────────────
  static const emerald = Color(0xFF22C55E);
  static const emeraldLight = Color(0xFFDCFCE7);
  static const emeraldDark = Color(0xFF4ADE80);
  static const emeraldText = Color(0xFF16A34A);

  static const emerald50 = Color(0xFFECFDF5);
  static const emerald100 = Color(0xFFD1FAE5);
  static const emerald200 = Color(0xFFA7F3D0);
  static const emerald500 = Color(0xFF22C55E);
  static const emerald600 = Color(0xFF16A34A);
  static const emerald700 = Color(0xFF15803D);

  // ── Semantic: Error ───────────────────────────────────────────
  static const red = Color(0xFFEF4444);
  static const redDark = Color(0xFFF87171);
  static const redFaint = Color(0xFFFEF2F2);

  // ── Semantic: Warning ─────────────────────────────────────────
  static const amber = Color(0xFFF59E0B);
  static const amberDark = Color(0xFFFBBF24);
  static const amberLight = Color(0xFFFEF3C7);
  static const amberText = Color(0xFFD97706);
  static const amberFaint = Color(0xFFFFFBEB);
  static const amberBorder = Color(0xFFFDE68A);
  static const amber50 = Color(0xFFFFFBEB);
  static const amber500 = Color(0xFFF59E0B);
  static const amber600 = Color(0xFFD97706);
  static const orange50 = Color(0xFFFFF7ED);

  // ── Blue scale (analytics UI) ─────────────────────────────────
  static const blue400 = Color(0xFF60A5FA);
  static const blue500 = Color(0xFF3B82F6);

  // ── Violet / Purple (stats card accent) ──────────────────────
  static const violet = Color(0xFF8B5CF6);
  static const violetFaint = Color(0xFFEDE9FE);

  // ── Faint tonal backgrounds ───────────────────────────────────
  static const greenFaint = Color(0xFFEEFBF4);

  // ── Member avatar palette ─────────────────────────────────────
  static const List<Color> memberColors = [
    Color(0xFF2F6FED),
    Color(0xFF5B9BFF),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
  ];

  // ── Backward-compat aliases ───────────────────────────────────
  static const primaryBlue = primary;
  static const primaryDeepNavy = Color(0xFF0B1E3D);
  static const primaryDark = primaryHover;
  static const primaryFaint = primaryLight;
  static const accentSky = accent;
  static const accentIce = primaryLight;
  static const accentAqua = Color(0xFF14B8A6);
  static const accentSkyDark = primaryBlueDark;
  static const accentIceDark = Color(0xFF1C2C49);
  static const accentAquaDark = Color(0xFF2DD4BF);
  static const neutral50 = bgLight;
  static const neutral100 = borderLight;
  static const neutral400 = textTertiaryLight;
  static const neutral600 = textSecondaryLight;
  static const neutral900 = textPrimaryLight;
  static const neutral400Dark = textTertiaryDark;
  static const neutral600Dark = textSecondaryDark;
  static const neutral900Dark = textPrimaryDark;
  static const surfaceLight = surfaceWhite;

  // ── Shadow tokens (subtle only — Clubhouse style) ─────────────
  static const shadowSubtle = [
    BoxShadow(
      color: Color(0x0D101828),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];
  static const shadowCard = [
    BoxShadow(
      color: Color(0x0D101828),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  // Keep float for any remaining uses — same subtle style
  static const shadowFloat = [
    BoxShadow(
      color: Color(0x14101828),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
  static const shadowCardDark = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
}

/// Centralized shadow tokens — Clubhouse style: very subtle only.
class AppShadows {
  static const BoxShadow card = BoxShadow(
    color: Color(0x0D101828),
    blurRadius: 8,
    offset: Offset(0, 2),
  );
  static const BoxShadow subtle = BoxShadow(
    color: Color(0x0A101828),
    blurRadius: 2,
    offset: Offset(0, 1),
  );
  static const BoxShadow float = BoxShadow(
    color: Color(0x14101828),
    blurRadius: 12,
    offset: Offset(0, 4),
  );
}

/// Gradients kept for backward compat but should not be used in new UI.
/// New screens use flat backgrounds.
class AppGradients {
  // Flat backgrounds — use these instead of gradients
  static const backgroundLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.bgLight, AppColors.bgLight],
  );

  static const backgroundDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.bgDark, AppColors.bgDark],
  );

  // Kept for any remaining uses — solid color, no gradient
  static const primaryButtonLight = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primary, AppColors.primary],
  );

  static const primaryButtonDark = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primaryBlueDark, AppColors.primaryBlueDark],
  );
}

class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
}

class AppRadii {
  static const double xs = 6.0;
  static const double sm = 12.0;    // inputs — 12px per spec
  static const double md = 16.0;    // cards — 16px per spec
  static const double lg = 20.0;    // sheets / dialogs
  static const double xl = 24.0;
  static const double full = 999.0; // pills / avatars / buttons

  // Semantic aliases
  static const double card = md;       // 16
  static const double sheet = lg;      // 20
  static const double navBar = 28.0;   // floating nav bar pill
  static const double dialog = lg;     // 20
}

/// Centralized animation tokens.
class AppMotion {
  static const Duration press = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);
  static const Duration page = Duration(milliseconds: 280);
  static const Duration skeleton = Duration(milliseconds: 1400);

  static const Curve standard = Curves.easeInOut;
  static const Curve decelerate = Curves.easeOut;
  static const Curve accelerate = Curves.easeIn;
  static const Curve spring = Curves.elasticOut;

  static const double pressScaleCard = 0.97;
  static const double pressScaleNav = 0.88;
  static const double pressScaleButton = 0.96;
}

class ThemeColors {
  static Color bg(bool isDark) =>
      isDark ? AppColors.bgDark : AppColors.bgLight;
  static Color surface(bool isDark) =>
      isDark ? AppColors.surfaceDark : AppColors.surfaceWhite;
  static Color border(bool isDark) =>
      isDark ? AppColors.borderDark : AppColors.borderLight;
  static Color textPrimary(bool isDark) =>
      isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  static Color textSecondary(bool isDark) =>
      isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  static Color textTertiary(bool isDark) =>
      isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
  static Color primary(bool isDark) =>
      isDark ? AppColors.primaryBlueDark : AppColors.primary;
}

class AppTheme {
  static const _pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
      TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
    },
  );

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      pageTransitionsTheme: _pageTransitionsTheme,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surfaceWhite,
        error: AppColors.red,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimaryLight,
        outline: AppColors.borderLight,
      ),
      scaffoldBackgroundColor: AppColors.bgLight,
      textTheme: _buildTextTheme(
          AppColors.textPrimaryLight, AppColors.textSecondaryLight),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.sarabun(
          color: AppColors.textPrimaryLight,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme:
            const IconThemeData(color: AppColors.textSecondaryLight),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceWhite,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiaryLight,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide:
              const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide:
              const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: const BorderSide(color: AppColors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide:
              const BorderSide(color: AppColors.red, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.sarabun(
          color: AppColors.textTertiaryLight,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: GoogleFonts.sarabun(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: GoogleFonts.sarabun(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          textStyle: GoogleFonts.sarabun(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceWhite,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.borderLight,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary,
        thumbColor: AppColors.primary,
        overlayColor: Color(0x142F6FED),
        inactiveTrackColor: AppColors.borderLight,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryLight,
        selectedColor: AppColors.primary,
        labelStyle: GoogleFonts.sarabun(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.full),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.dialog),
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      pageTransitionsTheme: _pageTransitionsTheme,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryBlueDark,
        secondary: AppColors.accent,
        surface: AppColors.surfaceDark,
        error: AppColors.redDark,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimaryDark,
        outline: AppColors.borderDark,
      ),
      scaffoldBackgroundColor: AppColors.bgDark,
      textTheme: _buildTextTheme(
          AppColors.textPrimaryDark, AppColors.textSecondaryDark),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.sarabun(
          color: AppColors.textPrimaryDark,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme:
            const IconThemeData(color: AppColors.textSecondaryDark),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primaryBlueDark,
        unselectedItemColor: AppColors.textTertiaryDark,
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
          borderSide: const BorderSide(
              color: AppColors.primaryBlueDark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: const BorderSide(color: AppColors.redDark),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide:
              const BorderSide(color: AppColors.redDark, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.sarabun(
          color: AppColors.textTertiaryDark,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlueDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: GoogleFonts.sarabun(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlueDark,
          side: const BorderSide(
              color: AppColors.primaryBlueDark, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: GoogleFonts.sarabun(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlueDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          textStyle: GoogleFonts.sarabun(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: const BorderSide(color: AppColors.borderDark),
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
              : AppColors.textTertiaryDark,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primaryBlueDark.withValues(alpha: 0.35)
              : AppColors.borderDark,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primaryBlueDark,
        thumbColor: AppColors.primaryBlueDark,
        overlayColor: Color(0x145B9BFF),
        inactiveTrackColor: AppColors.borderDark,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.accentIceDark,
        selectedColor: AppColors.primaryBlueDark,
        labelStyle: GoogleFonts.sarabun(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryBlueDark,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.full),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.dialog),
        ),
      ),
    );
  }

  // ── Font helpers ─────────────────────────────────────────────────────────
  // Sarabun: clean geometric Thai+Latin sans-serif — closest match to
  // Clubhouse's Inter aesthetic while fully supporting Thai script.
  static TextStyle _display(Color c) => GoogleFonts.sarabun(
      fontSize: 28, fontWeight: FontWeight.w700, height: 1.3, color: c);
  static TextStyle _h1(Color c) => GoogleFonts.sarabun(
      fontSize: 22, fontWeight: FontWeight.w600, height: 1.3, color: c);
  static TextStyle _h2(Color c) => GoogleFonts.sarabun(
      fontSize: 18, fontWeight: FontWeight.w600, height: 1.35, color: c);
  static TextStyle _titleMd(Color c) => GoogleFonts.sarabun(
      fontSize: 17, fontWeight: FontWeight.w600, height: 1.4, color: c);
  static TextStyle _titleSm(Color c) => GoogleFonts.sarabun(
      fontSize: 15, fontWeight: FontWeight.w600, height: 1.4, color: c);
  static TextStyle _bodyLg(Color c) => GoogleFonts.sarabun(
      fontSize: 15, fontWeight: FontWeight.w400, height: 1.5, color: c);
  static TextStyle _bodyMd(Color c) => GoogleFonts.sarabun(
      fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: c);
  static TextStyle _bodySm(Color c) => GoogleFonts.sarabun(
      fontSize: 13, fontWeight: FontWeight.w400, height: 1.4, color: c);
  static TextStyle _labelLg(Color c) => GoogleFonts.sarabun(
      fontSize: 14, fontWeight: FontWeight.w600, height: 1.3, color: c);
  static TextStyle _labelSm(Color c) => GoogleFonts.sarabun(
      fontSize: 12, fontWeight: FontWeight.w500, height: 1.4, color: c);

  static TextTheme _buildTextTheme(
      Color primaryColor, Color secondaryColor) {
    return TextTheme(
      // Display — 28px bold
      displayLarge: _display(primaryColor),
      // H1 — 22px semibold
      headlineMedium: _h1(primaryColor),
      // H2 — 18px semibold
      titleLarge: _h2(primaryColor),
      // Title — 17px semibold
      titleMedium: _titleMd(primaryColor),
      // Subtitle — 15px semibold
      titleSmall: _titleSm(primaryColor),
      // Body — 15px regular
      bodyLarge: _bodyLg(primaryColor),
      // Body medium — 14px regular
      bodyMedium: _bodyMd(secondaryColor),
      // Caption — 13px regular
      bodySmall: _bodySm(secondaryColor),
      // Label large — 14px semibold
      labelLarge: _labelLg(primaryColor),
      // Label small — 12px medium
      labelSmall: _labelSm(secondaryColor),
    );
  }
}
