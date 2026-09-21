import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryRed = Color(0xFF4A7C59);
  static const Color primaryRedDark = Color(0xFF386345);
  static const Color primaryRedLight = Color(0xFF639673);

  static const Color backgroundBlack = Color(0xFF1B1E23);
  static const Color surfaceDark = Color(0xFF22262C);
  static const Color surfaceMedium = Color(0xFF2B3038);
  static const Color surfaceLight = Color(0xFF353B45);
  static const Color borderColor = Color(0xFF3E4552);

  static const Color textPrimary = Color(0xFFE2E4E9);
  static const Color textSecondary = Color(0xFF9EA4B0);
  static const Color textMuted = Color(0xFF727885);
  static const Color textDisabled = Color(0xFF535863);

  static const Color successGreen = Color(0xFF4A7C59);
  static const Color warningOrange = Color(0xFFD98E32);
  static const Color errorRed = Color(0xFFCF5C56);
  static const Color infoBlue = Color(0xFF5B8CB8);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryRed,
        primaryContainer: primaryRedDark,
        secondary: primaryRedLight,
        surface: surfaceDark,
        surfaceContainerHighest: surfaceMedium,
        surfaceContainerHigh: surfaceLight,
        outline: borderColor,
        outlineVariant: borderColor,
        onPrimary: Color(0xFFFFFFFF),
        onSecondary: Color(0xFFFFFFFF),
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        onError: Color(0xFFFFFFFF),
        error: errorRed,
        errorContainer: Color(0xFF3B1E1E),
      ),
      scaffoldBackgroundColor: backgroundBlack,
      cardColor: surfaceDark,
      dividerColor: borderColor,
      focusColor: primaryRed.withValues(alpha: 0.2),
      hoverColor: surfaceMedium,
      highlightColor: primaryRed.withValues(alpha: 0.1),
      splashColor: primaryRed.withValues(alpha: 0.15),
      fontFamily: 'Consolas',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Consolas',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Consolas',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Consolas',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineLarge: TextStyle(fontFamily: 'Consolas', 
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.2,
        ),
        headlineMedium: TextStyle(fontFamily: 'Consolas', 
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(fontFamily: 'Consolas', 
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(fontFamily: 'Consolas', 
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(fontFamily: 'Consolas', 
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleSmall: TextStyle(fontFamily: 'Consolas', 
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        bodyLarge: TextStyle(fontFamily: 'Consolas', 
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(fontFamily: 'Consolas', 
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodySmall: TextStyle(fontFamily: 'Consolas', 
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textMuted,
        ),
        labelLarge: TextStyle(fontFamily: 'Consolas', 
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        labelMedium: TextStyle(fontFamily: 'Consolas', 
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(fontFamily: 'Consolas', 
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textMuted,
          letterSpacing: 0.5,
        ),
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(fontFamily: 'Consolas', 
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: borderColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: const RoundedRectangleBorder(), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16), textStyle: const TextStyle(fontFamily: 'Consolas', fontWeight: FontWeight.bold))),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          textStyle: const TextStyle(fontFamily: 'Consolas', 
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderColor, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          textStyle: const TextStyle(fontFamily: 'Consolas', 
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryRed,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontFamily: 'Consolas', 
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: primaryRed, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintStyle: const TextStyle(fontFamily: 'Consolas', color: textMuted, fontSize: 13),
        labelStyle: const TextStyle(fontFamily: 'Consolas', color: textSecondary, fontSize: 13),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: textPrimary,
        unselectedLabelColor: textMuted,
        indicatorColor: primaryRed,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontFamily: 'Consolas', fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Consolas', fontSize: 12, fontWeight: FontWeight.w400),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        indicatorColor: primaryRed.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontFamily: 'Consolas', fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary);
          }
          return const TextStyle(fontFamily: 'Consolas', fontSize: 11, fontWeight: FontWeight.w400, color: textMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryRed, size: 22);
          }
          return const IconThemeData(color: textMuted, size: 22);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 0,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        dense: true,
        iconColor: textSecondary,
        textColor: textPrimary,
        titleTextStyle: TextStyle(fontFamily: 'Consolas', fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
        subtitleTextStyle: TextStyle(fontFamily: 'Consolas', fontSize: 11, fontWeight: FontWeight.w400, color: textMuted),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: surfaceLight,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: borderColor),
        ),
        textStyle: const TextStyle(fontFamily: 'Consolas', fontSize: 11, color: textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: borderColor, width: 1),
        ),
        titleTextStyle: const TextStyle(fontFamily: 'Consolas', fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        contentTextStyle: const TextStyle(fontFamily: 'Consolas', fontSize: 13, color: textSecondary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: borderColor, width: 1),
        ),
        textStyle: const TextStyle(fontFamily: 'Consolas', fontSize: 12, color: textPrimary),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surfaceDark),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: const BorderSide(color: borderColor, width: 1),
            ),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryRed,
        linearTrackColor: surfaceMedium,
        circularTrackColor: surfaceMedium,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryRed,
        inactiveTrackColor: surfaceMedium,
        thumbColor: primaryRed,
        overlayColor: primaryRed.withValues(alpha: 0.2),
        valueIndicatorColor: primaryRed,
        valueIndicatorTextStyle: const TextStyle(fontFamily: 'Consolas', color: textPrimary, fontSize: 11),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryRed;
          return textDisabled;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryRed.withValues(alpha: 0.5);
          return surfaceLight;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryRed;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(textPrimary),
        side: const BorderSide(color: borderColor, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryRed;
          return textDisabled;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceMedium,
        selectedColor: primaryRed.withValues(alpha: 0.3),
        disabledColor: surfaceLight,
        labelStyle: const TextStyle(fontFamily: 'Consolas', fontSize: 11, color: textPrimary),
        secondaryLabelStyle: const TextStyle(fontFamily: 'Consolas', fontSize: 11, color: textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) return surfaceMedium;
          if (states.contains(WidgetState.selected)) return primaryRed.withValues(alpha: 0.1);
          return Colors.transparent;
        }),
        headingRowColor: WidgetStatePropertyAll(surfaceMedium),
        headingTextStyle: const TextStyle(fontFamily: 'Consolas', fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
        dataTextStyle: const TextStyle(fontFamily: 'Consolas', fontSize: 12, color: textPrimary),
        dividerThickness: 1,
        columnSpacing: 24,
        horizontalMargin: 12,
      ),
    );
  }

  static ThemeData get lightTheme {
    return darkTheme;
  }
}

extension ColorExtension on Color {
  Color withValues({required double alpha}) {
    return withValues(alpha: alpha.clamp(0.0, 1.0));
  }
}

