import 'package:flutter/material.dart';

class Sl {
  static const primary = Color(0xFF0D3B2E);
  static const primaryLight = Color(0xFF1A5C47);
  static const accent = Color(0xFFF5C518);
  static const accentHover = Color(0xFFE0B010);
  static const bg = Color(0xFF0A1F18);
  static const card = Color(0xFF122A22);
  static const text = Color(0xFFE8F0EC);
  static const muted = Color(0xFF8FA89A);
  static const border = Color(0xFF1E4A3A);
  static const success = Color(0xFF2ECC71);
  static const danger = Color(0xFFE74C3C);
  static const pending = Color(0xFFF39C12);
  static const frameOuter = Color(0xFF04110C);
  static const topbarEnd = Color(0xFF1A5C47);
  static const tabbar = Color(0xFF0D2A22);

  static ThemeData theme() {
    final scheme = ColorScheme.dark(
      surface: bg,
      primary: accent,
      onPrimary: primary,
      secondary: primaryLight,
      onSurface: text,
      error: danger,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: 'Segoe UI',
      dividerColor: border,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: text,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: primary,
        labelStyle: const TextStyle(color: muted),
        hintStyle: const TextStyle(color: muted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accent),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
    );
  }

  static void toast(BuildContext context, String message, {String kind = 'info'}) {
    final style = switch (kind) {
      'success' => (const Color(0xFF163C2C), const Color(0xFFB8F0C8), const Color(0x8C2ECC71)),
      'error' => (const Color(0xFF3A1C1C), const Color(0xFFFF6B6B), const Color(0xA6E74C3C)),
      'warning' => (const Color(0xFF3A3314), const Color(0xFFFFE082), const Color(0xA6F1C40F)),
      'bonus' => (const Color(0xFF3A3214), const Color(0xFFFFE9A8), const Color(0x8CF5C518)),
      _ => (card, text, border),
    };
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: style.$1,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: style.$3),
        ),
        content: Text(message, style: TextStyle(color: style.$2, fontWeight: FontWeight.w600, height: 1.35)),
      ),
    );
  }
}
