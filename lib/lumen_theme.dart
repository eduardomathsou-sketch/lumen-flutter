import 'package:flutter/material.dart';

/// Paleta e tipografia da loja: fundo claro, preto profundo, dourado nos detalhes,
/// Montserrat no texto e Bodoni Moda nos títulos e preços.
class Lumen {
  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF111111);
  static const text = Color(0xFF444444);
  static const muted = Color(0xFF6B7280);
  static const faint = Color(0xFF9CA3AF);
  static const border = Color(0x1A111111);
  static const gold = Color(0xFFCBA96B);
  static const goldDeep = Color(0xFF8C6D3F);
  static const sale = Color(0xFFEF4444);
  static const footer = Color(0xFF111111);

  static const sans = 'Montserrat';
  static const display = 'Bodoni';

  static BorderRadius get radius => BorderRadius.circular(8);
  static BoxDecoration card({Color color = surface}) => BoxDecoration(
    color: color,
    borderRadius: radius,
    border: Border.all(color: border, width: .8),
  );

  /// Rótulo de seção: pequeno, em caixa alta.
  static const label = TextStyle(
    fontFamily: sans,
    color: text,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
  );

  static TextStyle displayStyle(double size, {Color color = ink, FontWeight weight = FontWeight.w400}) =>
      TextStyle(
        fontFamily: display,
        color: color,
        fontSize: size,
        fontWeight: weight,
        height: 1.1,
      );
}

ThemeData lumenTheme() {
  // Paleta neutra (preto, branco e cinzas): sem isso o Flutter inventa tons
  // azulados para os "containers" (ex.: o círculo do perfil saía ciano).
  final scheme = ColorScheme.fromSeed(
    seedColor: Lumen.ink,
    dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
    brightness: Brightness.light,
    primary: Lumen.ink,
    primaryContainer: const Color(0xFFF3EEE7),
    onPrimaryContainer: Lumen.ink,
    secondaryContainer: const Color(0xFFF3EADB),
    onSecondaryContainer: Lumen.ink,
    onPrimary: Colors.white,
    secondary: Lumen.gold,
    surface: Lumen.surface,
    onSurface: Lumen.ink,
    error: Lumen.sale,
    outline: const Color(0x33111111),
    outlineVariant: Lumen.border,
  );
  final shape = RoundedRectangleBorder(borderRadius: Lumen.radius);
  const buttonText = TextStyle(
    fontFamily: Lumen.sans,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: .4,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: Lumen.sans);
  return base.copyWith(
    scaffoldBackgroundColor: Lumen.background,
    textTheme: base.textTheme.copyWith(
      displaySmall: Lumen.displayStyle(36),
      headlineLarge: Lumen.displayStyle(34),
      headlineMedium: Lumen.displayStyle(30),
      headlineSmall: Lumen.displayStyle(26),
      titleLarge: const TextStyle(
        fontFamily: Lumen.sans,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Lumen.ink,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xF2FFFFFF),
      foregroundColor: Lumen.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: .5,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: Lumen.sans,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Lumen.ink,
      ),
    ),
    cardTheme: CardThemeData(
      color: Lumen.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: Lumen.radius,
        side: const BorderSide(color: Lumen.border, width: .8),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Lumen.ink,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE5E7EB),
        disabledForegroundColor: Lumen.faint,
        minimumSize: const Size(48, 48),
        shape: shape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Lumen.ink,
        side: const BorderSide(color: Lumen.ink, width: .8),
        minimumSize: const Size(48, 48),
        shape: shape,
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Lumen.ink, textStyle: buttonText),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: Lumen.surface,
      selectedColor: Lumen.ink,
      side: const BorderSide(color: Lumen.border),
      shape: shape,
      // Selecionado = fundo preto e texto branco; os demais, branco com texto preto.
      labelStyle: TextStyle(
        fontFamily: Lumen.sans,
        fontWeight: FontWeight.w600,
        color: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : Lumen.ink,
        ),
      ),
      checkmarkColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Lumen.surface,
      border: OutlineInputBorder(borderRadius: Lumen.radius, borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: Lumen.radius, borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: Lumen.radius, borderSide: const BorderSide(color: Lumen.ink, width: 1.2)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Lumen.ink,
      contentTextStyle: const TextStyle(fontFamily: Lumen.sans, color: Colors.white),
    ),
    dividerTheme: const DividerThemeData(color: Lumen.border),
  );
}
