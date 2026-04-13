import 'package:flutter/material.dart';

import 'app_border_radius.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  const AppTheme._();

  static TextTheme _buildTextTheme({
    required Color primaryText,
    required Color secondaryText,
  }) {
    return TextTheme(
      displayLarge: AppTextStyles.titleLarge.copyWith(color: primaryText),
      titleLarge: AppTextStyles.titleLarge.copyWith(color: primaryText),
      titleMedium: AppTextStyles.titleMedium.copyWith(color: primaryText),
      titleSmall: AppTextStyles.titleSmall.copyWith(color: primaryText),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: primaryText),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: primaryText),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: secondaryText),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.warmSand,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.orange,
        brightness: Brightness.light,
        primary: AppColors.orange,
        secondary: AppColors.coral,
        surface: AppColors.warmCard,
      ),
      textTheme: _buildTextTheme(
        primaryText: AppColors.darkText,
        secondaryText: AppColors.mutedText,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.warmSand,
        foregroundColor: AppColors.darkText,
        titleTextStyle: AppTextStyles.titleMedium,
      ),
      cardTheme: CardThemeData(
        color: AppColors.warmCard,
        elevation: 2,
        shadowColor: AppColors.lightShadow,
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.lg),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.warmCard,
        border: OutlineInputBorder(
          borderRadius: AppBorderRadius.md,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.md,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.md,
          borderSide: const BorderSide(color: AppColors.orange),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.md),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.mutedText,
        backgroundColor: AppColors.warmCard,
      ),
      dividerColor: AppColors.border,
    );
  }

  static ThemeData get dark {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.orange,
      onPrimary: AppColors.white,
      secondary: AppColors.coral,
      onSecondary: AppColors.white,
      error: AppColors.danger,
      onError: AppColors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkScaffold,
      colorScheme: scheme,
      textTheme: _buildTextTheme(
        primaryText: AppColors.darkTextPrimary,
        secondaryText: AppColors.darkTextSecondary,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.darkScaffold,
        foregroundColor: AppColors.darkTextPrimary,
        titleTextStyle: AppTextStyles.titleMedium.copyWith(
          color: AppColors.darkTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 3,
        shadowColor: AppColors.darkShadow,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.lg,
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceSoft,
        labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
        hintStyle: const TextStyle(color: AppColors.darkTextSecondary),
        border: OutlineInputBorder(
          borderRadius: AppBorderRadius.md,
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.md,
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.md,
          borderSide: const BorderSide(color: AppColors.orange),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.md),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          side: const BorderSide(color: AppColors.darkBorder),
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.md),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.darkTextSecondary,
        backgroundColor: AppColors.darkSurface,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceSoft,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.darkTextPrimary,
        ),
      ),
      dividerColor: AppColors.darkBorder,
    );
  }
}
