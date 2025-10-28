import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
/// 💰 Currency Formatter for Vietnamese Dong (VND)
class CurrencyFormatter {
  /// Format amount to VND with proper formatting
  /// Example: 10000000 → "10,000,000 ₫"
  static String formatVND(double amount, {bool showSymbol = true}) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    final formatted = formatter.format(amount.round());
    return showSymbol ? '$formatted ₫' : formatted;
  }

  /// Format with sign prefix (+ for income, - for expense)
  /// Example: 10000000 → "+10,000,000 ₫"
  static String formatVNDWithSign(double amount, bool isIncome, {bool showSymbol = true}) {
    final sign = isIncome ? '+' : '-';
    final absAmount = amount.abs();
    return '$sign${formatVND(absAmount, showSymbol: showSymbol)}';
  }

  /// Parse VND string back to double
  /// Example: "10,000,000" → 10000000.0
  static double parseVND(String vndString) {
    // Remove all non-numeric characters except decimal point
    final cleaned = vndString.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Format for input field (no symbol, with thousand separators)
  /// Example: 10000000 → "10,000,000"
  static String formatForInput(double amount) {
    return formatVND(amount, showSymbol: false);
  }

  /// Format compact (for large numbers)
  /// Example: 10000000 → "10M ₫"
  static String formatCompactVND(double amount) {
    if (amount >= 1000000000) {
      // Billions
      return '${(amount / 1000000000).toStringAsFixed(1)}B ₫';
    } else if (amount >= 1000000) {
      // Millions
      return '${(amount / 1000000).toStringAsFixed(1)}M ₫';
    } else if (amount >= 1000) {
      // Thousands
      return '${(amount / 1000).toStringAsFixed(1)}K ₫';
    }
    return formatVND(amount);
  }
}

/// 🔢 Number Input Formatter for TextField
/// Automatically formats input with thousand separators
class VNDInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-numeric characters
    final numericString = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (numericString.isEmpty) {
      return TextEditingValue.empty;
    }

    // Parse to number and format
    final number = int.tryParse(numericString);
    if (number == null) {
      return oldValue;
    }

    // Format with thousand separators
    final formatted = NumberFormat('#,###', 'vi_VN').format(number);

    // Calculate new cursor position
    final cursorPosition = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}