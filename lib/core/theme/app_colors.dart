import 'package:flutter/material.dart';

class AppColors {
  // Primary brand palette - Subtle refined slate & graphite
  static const Color primary = Color(0xFF546E7A); // Sophisticated cool slate
  static const Color primaryDark = Color(0xFF37474F);
  static const Color primarySoft = Color(0xFF78909C);
  static const Color secondary = Color(0xFF6B7280); // Cashmere slate grey
  static const Color accent = Color(0xFF8D99AE); // Balanced warm slate

  // Surface & Background - Dark Mode (Deep Obsidian & Graphite)
  static const Color darkBackground = Color(0xFF12161A);
  static const Color darkSurface = Color(0xFF1A2027);
  static const Color darkCard = Color(0xFF222A33);
  static const Color darkCardBorder = Color(0xFF2E3844);
  static const Color darkInput = Color(0xFF27303B);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Surface & Background - Light Mode (Soft Mist & Elevated Slate)
  static const Color lightBackground = Color(0xFFF6F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE2E8F0);
  static const Color lightInput = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Status & Priority
  static const Color success = Color(0xFF5A8E75);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFE11D48);
  static const Color info = Color(0xFF64748B);

  // PDF annotation colors
  static const List<Color> annotationColors = [
    Color(0xFFEAB308), // highlight yellow
    Color(0xFF22C55E), // green
    Color(0xFF3B82F6), // blue
    Color(0xFFF97316), // orange
    Color(0xFFEC4899), // pink
    Color(0xFF8B5CF6), // violet
  ];

  // Curated Note Background Colors (Dark & Light adapted)
  static const List<NoteColorPalette> noteColorPalettes = [
    NoteColorPalette(
      name: 'Default',
      lightColor: Color(0xFFFFFFFF),
      darkColor: Color(0xFF1E2230),
      accentColor: Color(0xFF6366F1),
    ),
    NoteColorPalette(
      name: 'Soft Lavender',
      lightColor: Color(0xFFF1EEE8),
      darkColor: Color(0xFF35302C),
      accentColor: Color(0xFF927B68),
    ),
    NoteColorPalette(
      name: 'Cool Grey',
      lightColor: Color(0xFFE9EDF0),
      darkColor: Color(0xFF2B343D),
      accentColor: Color(0xFF718397),
    ),
    NoteColorPalette(
      name: 'Warm Coral',
      lightColor: Color(0xFFF8EAE5),
      darkColor: Color(0xFF492D29),
      accentColor: Color(0xFFA87867),
    ),
    NoteColorPalette(
      name: 'Golden Sun',
      lightColor: Color(0xFFF7F0DD),
      darkColor: Color(0xFF463B24),
      accentColor: Color(0xFFC6944F),
    ),
    NoteColorPalette(
      name: 'Sky Breeze',
      lightColor: Color(0xFFE7F0F2),
      darkColor: Color(0xFF253A40),
      accentColor: Color(0xFF7695A2),
    ),
    NoteColorPalette(
      name: 'Rose Quartz',
      lightColor: Color(0xFFF3E9EB),
      darkColor: Color(0xFF432C33),
      accentColor: Color(0xFFAC7783),
    ),
  ];
}

class NoteColorPalette {
  final String name;
  final Color lightColor;
  final Color darkColor;
  final Color accentColor;

  const NoteColorPalette({
    required this.name,
    required this.lightColor,
    required this.darkColor,
    required this.accentColor,
  });

  Color getColor(bool isDark) => isDark ? darkColor : lightColor;
}
