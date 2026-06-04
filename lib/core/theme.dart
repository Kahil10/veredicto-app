import 'package:flutter/material.dart';

const kPurple = Color(0xFFa78bfa);
const kPurpleDark = Color(0xFF7c3aed);
const kBg = Color(0xFF0f0f1a);
const kSurface = Color(0xFF1a1a2e);
const kCard = Color(0xFF1e1e35);
const kText = Color(0xFFf1f5f9);
const kMuted = Color(0xFF94a3b8);

ThemeData buildTheme() => ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: kBg,
      colorScheme: const ColorScheme.dark(
        primary: kPurple,
        secondary: kPurple,
        surface: kSurface,
      ),
      cardTheme: const CardThemeData(
        color: kCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: kSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: kText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: .3,
        ),
        iconTheme: IconThemeData(color: kText),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: kSurface,
        selectedItemColor: kPurple,
        unselectedItemColor: kMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2d2d4e)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2d2d4e)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPurple, width: 1.5),
        ),
        labelStyle: const TextStyle(color: kMuted),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: kText),
        bodyMedium: TextStyle(color: kText),
        bodySmall: TextStyle(color: kMuted),
      ),
    );
