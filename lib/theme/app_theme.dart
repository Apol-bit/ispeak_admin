import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors
  static const Color primaryColor = Color(0xFF1D4ED8);

  // Secondary colors
  static const Color accentColor = Color(0xFF3B82F6);

  // Light mode
  static const Color backgroundColor = Color(0xFFF9FAFB);
  static const Color textPrimary = Color(0xFF1D4ED8);

  // Dark mode
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFE2E8F0);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkSidebar = Color(0xFF1E3A8A);

  // Typography
  static const String fontFamily = 'Inter';
}

class ThemeProvider extends InheritedWidget {
  final bool isDarkMode;

  const ThemeProvider({
    super.key,
    required this.isDarkMode,
    required super.child,
  });

  static ThemeProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
  }

  // Convenience color getters — use these in screens instead of raw ternaries
  Color get cardColor       => isDarkMode ? AppTheme.darkSurface      : Colors.white;
  Color get borderColor     => isDarkMode ? AppTheme.darkBorder        : const Color(0xFFE5E7EB);
  Color get bodyTextColor   => isDarkMode ? AppTheme.darkTextPrimary   : Colors.black87;
  Color get subtleTextColor => isDarkMode ? AppTheme.darkTextSecondary : Colors.grey;
  Color get headingColor    => isDarkMode ? AppTheme.darkTextPrimary   : AppTheme.textPrimary;
  Color get scaffoldColor   => isDarkMode ? AppTheme.darkBackground    : AppTheme.backgroundColor;
  Color get tableHeadColor  => isDarkMode ? AppTheme.darkTextPrimary   : Colors.black87;

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) =>
      isDarkMode != oldWidget.isDarkMode;
}