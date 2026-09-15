import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const Color brandGreen = Color(0xFF0F6B35);
  static const Color brandGreenDark = Color(0xFF084D27);
  static const Color brandGreenLight = Color(0xFFE8F5EC);

  // Backgrounds
  static const Color background = Color(0xFFF7F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF2F4F2);

  // Text
  static const Color textPrimary = Color(0xFF1B1F1D);
  static const Color textSecondary = Color(0xFF6B746F);
  static const Color textTertiary = Color(0xFF9AA19D);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Borders
  static const Color border = Color(0xFFE1E5E2);
  static const Color borderStrong = Color(0xFFCCD2CE);

  // Letter tiles
  static const Color tileBackground = Color(0xFFFFE8B0);
  static const Color tileBorder = Color(0xFFE3C67D);
  static const Color tileText = Color(0xFF342B18);

  // Game status
  static const Color success = Color(0xFF2E8B57);
  static const Color successBackground = Color(0xFFE7F5EC);

  static const Color warning = Color(0xFFE5A326);
  static const Color warningBackground = Color(0xFFFFF4D9);

  static const Color danger = Color(0xFFD9544D);
  static const Color dangerBackground = Color(0xFFFFE9E7);

  static const Color info = Color(0xFF3977C5);
  static const Color infoBackground = Color(0xFFEAF2FC);

  // Analysis
  static const Color excellent = Color(0xFF2E8B57);
  static const Color good = Color(0xFF4C8ED9);
  static const Color missedOpportunity = Color(0xFFE5A326);
  static const Color mistake = Color(0xFFD9544D);

  // Board bonuses
  static const Color doubleLetter = Color(0xFFB7DBF6);
  static const Color tripleLetter = Color(0xFF5B94D6);
  static const Color doubleWord = Color(0xFFF8D66D);
  static const Color tripleWord = Color(0xFFE97A63);

  // Misc
  static const Color navy = Color(0xFF1E2A44);
  static const Color coin = Color(0xFFF2B632);
  static const Color transparent = Colors.transparent;
}
