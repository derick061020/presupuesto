import 'package:flutter/material.dart';

/// Sistema de diseño: paleta, gradientes y helpers visuales compartidos.
class AppTheme {
  // Gradientes de marca (uno por pestaña, todos en armonía).
  static const daily = [Color(0xFF11998E), Color(0xFF38EF7D)]; // teal -> verde
  static const monthly = [Color(0xFF4E54C8), Color(0xFF8F94FB)]; // índigo -> violeta
  static const savings = [Color(0xFF2193B0), Color(0xFF6DD5ED)]; // azul -> cian
  static const warn = [Color(0xFFF7971E), Color(0xFFFFD200)]; // ámbar
  static const danger = [Color(0xFFFF512F), Color(0xFFDD2476)]; // rojo -> magenta

  static const seed = Color(0xFF11998E);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: b);
    final isDark = b == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF0E1512) : const Color(0xFFF3F6F4),
      textTheme: Typography.material2021(platform: TargetPlatform.android)
          .black
          .apply(
            bodyColor: scheme.onSurface,
            displayColor: scheme.onSurface,
          ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            isDark ? const Color(0xFF15201C) : Colors.white,
        indicatorColor: seed.withValues(alpha: 0.18),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? const Color(0xFF16211D) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}

/// Gradiente lineal estándar (de arriba-izq a abajo-der).
LinearGradient appGradient(List<Color> colors) => LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
