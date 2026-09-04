import 'package:flutter/material.dart';

/// High-contrast, emergency-optimized color tokens for UyirKappan.
class AppColors {
  AppColors._();

  // Primary Emergency Palette
  static const Color emergencyRed = Color(0xFFD32F2F);
  static const Color emergencyDarkRed = Color(0xFFB71C1C);
  static const Color emergencyLightRed = Color(0xFFFFEBEE);
  static const Color emergencyGlow = Color(0xFFEF5350);

  // Status Colors
  static const Color statusSearching = Color(0xFFF57C00); // Amber/Orange
  static const Color statusAssigned = Color(0xFF1976D2); // Blue
  static const Color statusAccepted = Color(0xFF0288D1); // Light Blue
  static const Color statusEnRoute = Color(0xFF7B1FA2); // Purple
  static const Color statusArrived = Color(0xFF388E3C); // Green
  static const Color statusCompleted = Color(0xFF2E7D32); // Dark Green
  static const Color statusCancelled = Color(0xFF616161); // Grey
  static const Color statusFallback = Color(0xFFE65100); // Deep Orange

  // Background & Surfaces (Light)
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F3F5);

  // Background & Surfaces (Dark)
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF2C2C2C);

  // Text & Icons
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF5F6368);
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFA0A0A0);

  // Accent & Utilities
  static const Color cardBorderLight = Color(0xFFE0E0E0);
  static const Color cardBorderDark = Color(0xFF333333);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);
  static const Color gpsActive = Color(0xFF2E7D32);
  static const Color gpsInactive = Color(0xFFD32F2F);
}
