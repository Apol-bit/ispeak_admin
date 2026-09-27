import 'package:flutter/material.dart';

class AppTheme {
  static const filterBlue = Color(0xFF3D6BFF);
  static const lightFilterBorder = Color(0xFFE6E8EE);
  static const lightFilterText = Color(0xFF5B6472);
  static const darkAction = Color(0xFF93B4FF);
  static const darkDestructive = Color(0xFFFF9B91);

  static ThemeData materialTheme(bool dark) {
    final brightness = dark ? Brightness.dark : Brightness.light;
    final surface = dark ? darkSurface : Colors.white;
    final text = dark ? darkTextPrimary : const Color(0xFF1B1F2A);
    final muted = dark ? darkTextSecondary : lightFilterText;
    final border = dark ? darkBorder : lightFilterBorder;
    final action = dark ? darkAction : primaryColor;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: filterBlue,
            brightness: brightness,
          ).copyWith(
            primary: action,
            secondary: action,
            surface: surface,
            onSurface: text,
            onSurfaceVariant: muted,
            outline: border,
            surfaceTint: Colors.transparent,
          ),
      scaffoldBackgroundColor: dark ? darkBackground : backgroundColor,
      iconTheme: IconThemeData(color: muted),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: text,
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: text,
          fontFamily: fontFamily,
          fontSize: 14,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: action),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: muted),
        helperStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: muted),
        prefixIconColor: muted,
        suffixIconColor: muted,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: filterBlue, width: 2),
        ),
      ),
    );
  }

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

class ThemeProvider extends StatelessWidget {
  final Widget child;
  final bool isDarkMode;

  const ThemeProvider({
    super.key,
    required this.isDarkMode,
    required this.child,
  });

  static ThemeProvider? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_AdminThemeScope>()
        ?.theme;
  }

  Color get filterTextColor =>
      isDarkMode ? const Color(0xFFCBD5E1) : AppTheme.lightFilterText;
  Color get filterBorderColor =>
      isDarkMode ? AppTheme.darkBorder : AppTheme.lightFilterBorder;
  Color get actionColor =>
      isDarkMode ? AppTheme.darkAction : AppTheme.primaryColor;
  Color get destructiveColor =>
      isDarkMode ? AppTheme.darkDestructive : Colors.red.shade700;
  Color categoryColor(String type) => switch (type) {
    'Challenge' => isDarkMode ? Colors.purple.shade200 : Colors.purple.shade700,
    'GuidedTask' => isDarkMode ? Colors.blue.shade200 : AppTheme.primaryColor,
    _ => isDarkMode ? Colors.green.shade200 : Colors.green.shade700,
  };

  // Convenience color getters — use these in screens instead of raw ternaries
  Color get cardColor => isDarkMode ? AppTheme.darkSurface : Colors.white;
  Color get borderColor =>
      isDarkMode ? AppTheme.darkBorder : const Color(0xFFE5E7EB);
  Color get bodyTextColor =>
      isDarkMode ? AppTheme.darkTextPrimary : Colors.black87;
  Color get subtleTextColor =>
      isDarkMode ? AppTheme.darkTextSecondary : AppTheme.lightFilterText;
  Color get headingColor =>
      isDarkMode ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get scaffoldColor =>
      isDarkMode ? AppTheme.darkBackground : AppTheme.backgroundColor;
  Color get tableHeadColor =>
      isDarkMode ? AppTheme.darkTextPrimary : Colors.black87;

  @override
  Widget build(BuildContext context) => _AdminThemeScope(
    theme: this,
    child: Theme(data: AppTheme.materialTheme(isDarkMode), child: child),
  );
}

class _AdminThemeScope extends InheritedWidget {
  final ThemeProvider theme;
  const _AdminThemeScope({required this.theme, required super.child});
  @override
  bool updateShouldNotify(_AdminThemeScope oldWidget) =>
      theme.isDarkMode != oldWidget.theme.isDarkMode;
}
