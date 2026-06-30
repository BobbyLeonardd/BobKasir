import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.primaryLight,
          onPrimaryContainer: AppColors.onSurface,
          secondary: AppColors.primaryDark,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.surface3,
          onSecondaryContainer: AppColors.onSurface,
          error: AppColors.error,
          onError: Colors.white,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          surfaceContainerHighest: AppColors.surface2,
          outline: AppColors.surface3,
          outlineVariant: AppColors.surface3,
        ),
        scaffoldBackgroundColor: AppColors.surface2,
        textTheme: _textTheme(AppColors.onSurface),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.onSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          titleTextStyle: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.onSurface3,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: AppColors.surface,
          selectedIconTheme: IconThemeData(color: AppColors.primary),
          unselectedIconTheme: IconThemeData(color: AppColors.onSurface3),
          selectedLabelTextStyle: TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelTextStyle: TextStyle(
            color: AppColors.onSurface3,
            fontSize: 13,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: Colors.black.withValues(alpha: 0.08),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.surface3, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.surface3, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          labelStyle: const TextStyle(color: AppColors.onSurface2),
          hintStyle: const TextStyle(color: AppColors.onSurface3),
          errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surface3,
          selectedColor: AppColors.primaryLight,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.surface3,
          thickness: 1,
          space: 0,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: AppColors.surface,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          showDragHandle: true,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? AppColors.primary : AppColors.onSurface3),
          trackColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? AppColors.primaryLight : AppColors.surface3),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: AppColors.primaryDarkMode,
          onPrimary: AppColors.surfaceDark,
          primaryContainer: AppColors.primaryDarkModeLight,
          onPrimaryContainer: AppColors.onSurfaceDark,
          secondary: AppColors.primaryDarkModeDark,
          onSecondary: AppColors.onSurfaceDark,
          secondaryContainer: AppColors.surface3Dark,
          onSecondaryContainer: AppColors.onSurfaceDark,
          error: AppColors.errorDark,
          onError: AppColors.surfaceDark,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.onSurfaceDark,
          surfaceContainerHighest: AppColors.surface2Dark,
          outline: AppColors.surface3Dark,
          outlineVariant: AppColors.surface3Dark,
        ),
        scaffoldBackgroundColor: AppColors.surface2Dark,
        textTheme: _textTheme(AppColors.onSurfaceDark),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surfaceDark,
          foregroundColor: AppColors.onSurfaceDark,
          elevation: 0,
          scrolledUnderElevation: 1,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceDark,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surfaceDark,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceDark,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.surface3Dark, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.surface3Dark, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primaryDarkMode, width: 2),
          ),
        ),
        dividerTheme: const DividerThemeData(color: AppColors.surface3Dark, thickness: 1, space: 0),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: AppColors.surfaceDark,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          showDragHandle: true,
        ),
      );

  static TextTheme _textTheme(Color baseColor) => GoogleFonts.interTextTheme(
        TextTheme(
          displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: baseColor, height: 1.2),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: baseColor, height: 1.2),
          headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: baseColor, height: 1.3),
          headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: baseColor, height: 1.3),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: baseColor, height: 1.4),
          titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: baseColor, height: 1.5),
          bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: baseColor, height: 1.5),
          bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: baseColor, height: 1.5),
          labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: baseColor, height: 1.3),
          labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: baseColor, height: 1.3),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: baseColor, height: 1.4),
        ),
      );
}
