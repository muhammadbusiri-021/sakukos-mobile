import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet warna Mode Gelap (Dark Slate)
abstract final class SakuKosDarkColors {
  static const Color scaffold = Color(0xFF0F172A); // Dark Slate
  static const Color card = Color(0xFF1E293B); // Charcoal
  static const Color border = Color(0xFF334155); // Outline halus gelap
  static const Color emerald = Color(0xFF10B981); // Emerald Green
  static const Color rose = Color(0xFFF43F5E); // Muted Rose
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
}

/// Palet warna Mode Terang (Soft Slate)
abstract final class SakuKosLightColors {
  static const Color scaffold = Color(0xFFF8FAFC); // Soft Slate
  static const Color card = Color(0xFFFFFFFF); // Putih Bersih
  static const Color border = Color(0xFFE2E8F0); // Slate Halus
  static const Color emerald = Color(0xFF059669); // Emerald Kontras
  static const Color rose = Color(0xFFE11D48); // Rose Coral Lembut
  static const Color textPrimary = Color(0xFF0F172A); // Slate Gelap
  static const Color textSecondary = Color(0xFF64748B); // Muted Slate
}

/// Extension tema kustom untuk menyediakan palet warna SakuKos secara adaptif.
@immutable
class SakuKosPalette extends ThemeExtension<SakuKosPalette> {
  final Color scaffold;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color emerald;
  final Color rose;

  const SakuKosPalette({
    required this.scaffold,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.emerald,
    required this.rose,
  });

  static const dark = SakuKosPalette(
    scaffold: SakuKosDarkColors.scaffold,
    card: SakuKosDarkColors.card,
    border: SakuKosDarkColors.border,
    textPrimary: SakuKosDarkColors.textPrimary,
    textSecondary: SakuKosDarkColors.textSecondary,
    emerald: SakuKosDarkColors.emerald,
    rose: SakuKosDarkColors.rose,
  );

  static const light = SakuKosPalette(
    scaffold: SakuKosLightColors.scaffold,
    card: SakuKosLightColors.card,
    border: SakuKosLightColors.border,
    textPrimary: SakuKosLightColors.textPrimary,
    textSecondary: SakuKosLightColors.textSecondary,
    emerald: SakuKosLightColors.emerald,
    rose: SakuKosLightColors.rose,
  );

  /// Mengambil palet aktif dari context secara aman.
  static SakuKosPalette of(BuildContext context) {
    return Theme.of(context).extension<SakuKosPalette>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? SakuKosPalette.dark
            : SakuKosPalette.light);
  }

  @override
  SakuKosPalette copyWith({
    Color? scaffold,
    Color? card,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? emerald,
    Color? rose,
  }) {
    return SakuKosPalette(
      scaffold: scaffold ?? this.scaffold,
      card: card ?? this.card,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      emerald: emerald ?? this.emerald,
      rose: rose ?? this.rose,
    );
  }

  @override
  SakuKosPalette lerp(ThemeExtension<SakuKosPalette>? other, double t) {
    if (other is! SakuKosPalette) return this;
    return SakuKosPalette(
      scaffold: Color.lerp(scaffold, other.scaffold, t) ?? scaffold,
      card: Color.lerp(card, other.card, t) ?? card,
      border: Color.lerp(border, other.border, t) ?? border,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      emerald: Color.lerp(emerald, other.emerald, t) ?? emerald,
      rose: Color.lerp(rose, other.rose, t) ?? rose,
    );
  }
}

/// Controller sederhana berbasis [ValueNotifier<ThemeMode>] untuk beralih mode tema.
class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier([super.value = ThemeMode.dark]);

  /// Beralih antara Dark Mode dan Light Mode.
  void toggleTheme() {
    value = value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  bool get isDarkMode => value == ThemeMode.dark;
}

/// Instance global untuk kontrol tema di seluruh aplikasi.
final themeNotifier = ThemeNotifier();

/// Konstanta warna untuk kompatibilitas ke belakang (Dark Slate default).
abstract final class SakuKosColors {
  static const Color scaffold = SakuKosDarkColors.scaffold;
  static const Color card = SakuKosDarkColors.card;
  static const Color border = SakuKosDarkColors.border;
  static const Color emerald = SakuKosDarkColors.emerald;
  static const Color rose = SakuKosDarkColors.rose;
  static const Color textPrimary = SakuKosDarkColors.textPrimary;
  static const Color textSecondary = SakuKosDarkColors.textSecondary;
}

/// Tema Gelap Kustom SakuKos.
ThemeData sakuKosDarkTheme() {
  const p = SakuKosPalette.dark;
  final baseText = GoogleFonts.plusJakartaSansTextTheme(
    ThemeData.dark().textTheme,
  );

  return ThemeData.dark().copyWith(
    extensions: const [p],
    scaffoldBackgroundColor: p.scaffold,
    colorScheme: const ColorScheme.dark().copyWith(
      primary: p.emerald,
      secondary: p.emerald,
      error: p.rose,
      surface: p.card,
      onSurface: p.textPrimary,
      outline: p.border,
    ),
    cardTheme: CardThemeData(
      color: p.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.border, width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.scaffold,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: baseText.titleLarge?.copyWith(
        color: p.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: p.textPrimary),
    ),
    dividerTheme: DividerThemeData(
      color: p.border,
      thickness: 1,
    ),
    textTheme: baseText.apply(
      bodyColor: p.textPrimary,
      displayColor: p.textPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.emerald, width: 2),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.emerald,
      foregroundColor: p.scaffold,
    ),
  );
}

/// Tema Terang Kustom SakuKos.
ThemeData sakuKosLightTheme() {
  const p = SakuKosPalette.light;
  final baseText = GoogleFonts.plusJakartaSansTextTheme(
    ThemeData.light().textTheme,
  );

  return ThemeData.light().copyWith(
    extensions: const [p],
    scaffoldBackgroundColor: p.scaffold,
    colorScheme: const ColorScheme.light().copyWith(
      primary: p.emerald,
      secondary: p.emerald,
      error: p.rose,
      surface: p.card,
      onSurface: p.textPrimary,
      outline: p.border,
    ),
    cardTheme: CardThemeData(
      color: p.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.border, width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.scaffold,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: baseText.titleLarge?.copyWith(
        color: p.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: p.textPrimary),
    ),
    dividerTheme: DividerThemeData(
      color: p.border,
      thickness: 1,
    ),
    textTheme: baseText.apply(
      bodyColor: p.textPrimary,
      displayColor: p.textPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.emerald, width: 2),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.emerald,
      foregroundColor: Colors.white,
    ),
  );
}

/// Alias tema default untuk kompatibilitas mundur.
ThemeData sakuKosTheme() => sakuKosDarkTheme();
