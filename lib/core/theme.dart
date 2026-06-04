import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Paleta élite (de MlbAnalizisPremium.html) ────────────────────────────────
const kBg       = Color(0xFF0a0c0f);
const kSurface  = Color(0xFF111418);
const kSurface2 = Color(0xFF181c22);
const kBorder   = Color(0x12FFFFFF);   // rgba(255,255,255,0.07)
const kAccent   = Color(0xFFe8ff3a);   // amarillo-verde principal
const kAccent2  = Color(0xFFff4757);   // rojo visitante
const kAccent3  = Color(0xFF3ae8ff);   // cyan
const kText     = Color(0xFFf0f2f5);
const kMuted    = Color(0xFF6b7280);
const kGreen    = Color(0xFF22c55e);
const kRed      = Color(0xFFef4444);
const kGold     = Color(0xFFf59e0b);

// Compatibilidad con código anterior
const kPurple     = kAccent;
const kPurpleDark = Color(0xFFd4e835);
const kCard       = kSurface2;

// ── Tipografías ───────────────────────────────────────────────────────────────
TextStyle bebasNeue(double size, {Color color = kText, double? letterSpacing}) =>
    GoogleFonts.bebasNeue(fontSize: size, color: color, letterSpacing: letterSpacing ?? 1.0);

TextStyle dmSans(double size, {Color color = kText, FontWeight weight = FontWeight.w400}) =>
    GoogleFonts.dmSans(fontSize: size, color: color, fontWeight: weight);

TextStyle jetMono(double size, {Color color = kText, FontWeight weight = FontWeight.w400}) =>
    GoogleFonts.jetBrainsMono(fontSize: size, color: color, fontWeight: weight);

// ── Tema global ───────────────────────────────────────────────────────────────
ThemeData buildTheme() => ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: kBg,
      colorScheme: const ColorScheme.dark(
        primary: kAccent,
        secondary: kAccent3,
        surface: kSurface,
      ),
      cardTheme: const CardThemeData(
        color: kSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: kBorder),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: kSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.dmSans(
          color: kText,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: .3,
        ),
        iconTheme: const IconThemeData(color: kText),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: kSurface,
        selectedItemColor: kAccent,
        unselectedItemColor: kMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 11),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kAccent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kAccent, width: 1.5),
        ),
        labelStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 14),
      ),
      textTheme: TextTheme(
        bodyLarge:  GoogleFonts.dmSans(color: kText),
        bodyMedium: GoogleFonts.dmSans(color: kText),
        bodySmall:  GoogleFonts.dmSans(color: kMuted),
      ),
    );
