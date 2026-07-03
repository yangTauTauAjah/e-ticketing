import 'package:flutter/material.dart';

/// Semantic color tokens shared by every screen, so light/dark mode is
/// driven by [ThemeData] instead of screens hardcoding literal hex values.
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface;
  final Color surfaceBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDim;
  final Color accent;
  final Color onAccent;
  final Color danger;
  final Color success;
  final Color warning;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDim,
    required this.accent,
    required this.onAccent,
    required this.danger,
    required this.success,
    required this.warning,
  });

  static const light = AppColors(
    background: Color(0xFFF8FAFC),
    surface: Colors.white,
    surfaceBorder: Color(0xFFF1F5F9),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    textMuted: Color(0xFF94A3B8),
    textDim: Color(0xFFCBD5E1),
    accent: Color(0xFF2196F3),
    onAccent: Colors.white,
    danger: Color(0xFFEF4444),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
  );

  // Matches the Figma "Implement Dark Theme UI" palette.
  static const dark = AppColors(
    background: Color(0xFF0B0B0F),
    surface: Color(0x0AFFFFFF),
    surfaceBorder: Color(0x12FFFFFF),
    textPrimary: Color(0xFFEEEEF5),
    textSecondary: Color(0xFFAAAABC),
    textMuted: Color(0xFF5A5A70),
    textDim: Color(0xFF3A3A50),
    accent: Color(0xFF5B8DEF),
    onAccent: Colors.white,
    danger: Color(0xFFF87171),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFB923C),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textDim,
    Color? accent,
    Color? onAccent,
    Color? danger,
    Color? success,
    Color? warning,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceBorder: surfaceBorder ?? this.surfaceBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textDim: textDim ?? this.textDim,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceBorder: Color.lerp(surfaceBorder, other.surfaceBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

/// Theme-invariant "hero" card treatment used for surfaces that are always
/// styled dark regardless of the active theme (matches the Figma reference).
class HeroCard {
  const HeroCard._();

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF131325), Color(0xFF0D0D18)],
  );

  static const border = Color(0x245B8DEF);
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
