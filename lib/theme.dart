import 'package:flutter/material.dart';

class NotesTheme {
  static const Color ink = Color(0xFF27313B);
  static const Color mint = Color(0xFF75B6A2);
  static const Color cream = Color(0xFFF7F3EC);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: mint, brightness: Brightness.light),
        scaffoldBackgroundColor: cream,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0),
        cardTheme: CardThemeData(elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
        inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white.withOpacity(.72), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: mint, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF111817),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0),
      );
}

class NoteColor {
  static const colors = <Color>[Color(0xFFFFE3A3), Color(0xFFCDEFE3), Color(0xFFDDE5FF), Color(0xFFFFD9DF), Color(0xFFE8D9FF)];
}