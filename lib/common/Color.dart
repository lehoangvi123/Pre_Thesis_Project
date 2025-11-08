import 'package:flutter/material.dart';

/// App Color Scheme for Personal Expense Tracker
/// Defines consistent colors used throughout the application
class AppColors {
  // Primary Colors - Main brand colors
  static const Color primary = Color(0xFF2E7D32); // Green - represents money/finance
  static const Color primaryLight = Color(0xFF60AD5E);
  static const Color primaryDark = Color(0xFF005005);
  static const Color primaryVariant = Color(0xFF4CAF50);

  // Secondary Colors - Accent colors
  static const Color secondary = Color(0xFF1976D2); // Blue - represents trust/security
  static const Color secondaryLight = Color(0xFF63A4FF);
  static const Color secondaryDark = Color(0xFF004BA0);

  // Background Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F9FA);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Income/Expense Colors
  static const Color income = Color(0xFF4CAF50); // Green for income
  static const Color expense = Color(0xFFE53935); // Red for expenses
  static const Color savings = Color(0xFF3F51B5); // Indigo for savings

  // Category Colors for Charts and Categories
  static const Color categoryFood = Color(0xFFFF5722);
  static const Color categoryTransport = Color(0xFF2196F3);
  static const Color categoryShopping = Color(0xFFE91E63);
  static const Color categoryEntertainment = Color(0xFF9C27B0);
  static const Color categoryHealthcare = Color(0xFF009688);
  static const Color categoryEducation = Color(0xFF795548);
  static const Color categoryUtilities = Color(0xFF607D8B);
  static const Color categoryOther = Color(0xFF9E9E9E);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryLight, secondary],
  );

  static const LinearGradient incomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
  );

  static const LinearGradient expenseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF5350), Color(0xFFE53935)],
  );

  // Card and Component Colors
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x1A000000);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFBDBDBD);

  // Button Colors
  static const Color buttonPrimary = primary;
  static const Color buttonSecondary = Color(0xFFE0E0E0);
  static const Color buttonDisabled = Color(0xFFBDBDBD);

  // Input Field Colors
  static const Color inputBackground = Color(0xFFF8F9FA);
  static const Color inputBorder = Color(0xFFE0E0E0);
  static const Color inputFocusedBorder = primary;
  static const Color inputErrorBorder = error;

  // Chart Colors - For expense visualization
  static const List<Color> chartColors = [
    categoryFood,
    categoryTransport,
    categoryShopping,
    categoryEntertainment,
    categoryHealthcare,
    categoryEducation,
    categoryUtilities,
    categoryOther,
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF00BCD4), // Cyan
    Color(0xFF8BC34A), // Light Green
    Color(0xFFFF9800), // Orange
  ];

  // Dark Theme Colors (for future dark mode support)
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  // Helper method to get category color by category name
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'restaurant':
        return categoryFood;
      case 'transport':
      case 'transportation':
      case 'fuel':
      case 'car':
        return categoryTransport;
      case 'shopping':
      case 'clothes':
      case 'retail':
        return categoryShopping;
      case 'entertainment':
      case 'movies':
      case 'games':
        return categoryEntertainment;
      case 'healthcare':
      case 'medical':
      case 'pharmacy':
        return categoryHealthcare;
      case 'education':
      case 'books':
      case 'course':
        return categoryEducation;
      case 'utilities':
      case 'electricity':
      case 'water':
      case 'internet':
        return categoryUtilities;
      default:
        return categoryOther;
    }
  }

  // Helper method to get chart color by index
  static Color getChartColor(int index) {
    return chartColors[index % chartColors.length];
  }
}

/// Extension to add custom opacity methods
extension AppColorsExtension on Color {
  /// Returns the color with specified custom opacity
  Color withCustomOpacity(double opacity) {
    return Color.fromARGB(
      (255 * opacity).round(),
      red,
      green,
      blue,
    );
  }
}

/// Material Theme Data for the app
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.inputFocusedBorder, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.inputErrorBorder),
      ),
    ),
  );

  // Dark theme for future implementation
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
  );
}