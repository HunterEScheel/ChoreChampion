import 'package:flutter/material.dart';

/// Breakpoint for phone vs tablet layout.
const double kTabletBreakpoint = 600;

/// Difficulty tier colors.
const Map<String, Color> difficultyColors = {
  'easy': Color(0xFF4CAF50),
  'medium': Color(0xFFFF9800),
  'hard': Color(0xFFF44336),
  'flexible': Color(0xFF9E9E9E),
};

Color difficultyColor(String difficulty) =>
    difficultyColors[difficulty] ?? Colors.grey;

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF5C6BC0), // indigo accent
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}
