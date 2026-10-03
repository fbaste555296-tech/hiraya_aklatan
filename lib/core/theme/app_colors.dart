import 'package:flutter/material.dart';

/// App color palette based on the Hiraya Aklatan logo
/// Primary: Deep crimson red, Accent: Warm gold, Neutral: Warm cream
class AppColors {
  AppColors._();

  // Brand colors (3 main colors from logo)
  static const Color primary = Color(0xFFB3261E); // Deep crimson red
  static const Color accent = Color(0xFFF2B233); // Warm gold
  static const Color neutral = Color(0xFFFFF8EC); // Warm cream

  // Text color
  static const Color textPrimary = Color(0xFF2B2118); // Near-black

  // Status colors (ONLY for status badges and error/success messages)
  static const Color statusApproved = Color(0xFF2E7D32); // Green
  static const Color statusPending = Color(0xFFF57C00); // Orange
  static const Color statusRejected = Color(0xFFD32F2F); // Red

  // Grayscale (derived from text color)
  static const Color textSecondary = Color(0xFF5C5147);
  static const Color textDisabled = Color(0xFF9E968A);
  static const Color divider = Color(0xFFE5E0D8);
  static const Color background = neutral;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFFFF4DB);

  // Semantic colors (derived from primary)
  static const Color error = primary;
  static const Color success = statusApproved;
  static const Color warning = statusPending;
}
