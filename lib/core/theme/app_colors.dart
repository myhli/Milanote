import 'package:flutter/material.dart';

/// Curated color tokens for Studio Dark and Studio Light modes.
/// Designed specifically for visual artists to keep artworks prominent.
abstract class AppColors {
  // Studio Dark Palette (Charcoal / Deep Slate)
  static const Color darkCanvasBackground = Color(0xFF141416);
  static const Color darkSurface = Color(0xFF1E1F23);
  static const Color darkSurfaceElevated = Color(0xFF282A30);
  static const Color darkBorder = Color(0xFF32353D);
  static const Color darkBorderSubtle = Color(0xFF262830);
  static const Color darkTextPrimary = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextMuted = Color(0xFF6B7280);
  static const Color darkGridDot = Color(0xFF2C2F38);

  // Studio Light Palette (Clean Soft Off-White)
  static const Color lightCanvasBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF0F2F5);
  static const Color lightBorder = Color(0xFFE2E4E9);
  static const Color lightBorderSubtle = Color(0xFFECEEF2);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF4B5563);
  static const Color lightTextMuted = Color(0xFF9CA3AF);
  static const Color lightGridDot = Color(0xFFD6DAE2);

  // Accent Colors (Tasteful, non-distracting)
  static const Color accentPrimary = Color(0xFF3B82F6); // Studio Indigo/Blue
  static const Color accentHover = Color(0xFF2563EB);
  static const Color accentSuccess = Color(0xFF10B981); // Emerald (for autosave saved indicator)
  static const Color accentWarning = Color(0xFFF59E0B);
  static const Color accentDanger = Color(0xFFEF4444);

  // Card Pastel Palettes (for Note Cards & Tags)
  static const Color noteDefault = Color(0xFFFFFFFF);
  static const Color noteYellow = Color(0xFFFEF3C7);
  static const Color noteGreen = Color(0xFFD1FAE5);
  static const Color noteBlue = Color(0xFFDBEAFE);
  static const Color notePeach = Color(0xFFFFEDD5);
  static const Color notePurple = Color(0xFFEDE9FE);
  static const Color noteGray = Color(0xFFF3F4F6);
}
