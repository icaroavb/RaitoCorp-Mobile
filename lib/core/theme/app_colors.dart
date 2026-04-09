import 'package:flutter/material.dart';

abstract class AppColors {
  // Primárias
  static const obsidian = Color(0xFF111111);
  static const cream = Color(0xFFF9F5EF);
  static const warmWhite = Color(0xFFFFFFFF);

  // Âmbar (acento — evoca luz quente)
  static const amber100 = Color(0xFFFFF3DC);
  static const amber200 = Color(0xFFFFE4B5);
  static const amber400 = Color(0xFFF5A623);
  static const amber600 = Color(0xFFC47D0E);

  // Neutros
  static const gray50 = Color(0xFFF7F5F2);
  static const gray100 = Color(0xFFF2F2F2);
  static const gray200 = Color(0xFFE5E2DF);
  static const gray300 = Color(0xFFD0CCCA);
  static const gray400 = Color(0xFFB0ABA7);
  static const gray500 = Color(0xFF8A8580);
  static const gray700 = Color(0xFF4A4744);

  // Semânticas
  static const success = Color(0xFF2D7A4F);
  static const successBg = Color(0xFFE8F5EC);
  static const warning = Color(0xFFD97706);
  static const error = Color(0xFFDC2626);
  static const info = Color(0xFF1A6B9A);

  // Temperatura de cor
  static const warmLight = Color(0xFFF5A623);
  static const neutralLight = Color(0xFFE8E0D0);
  static const coolLight = Color(0xFFA8C8E8);

  // CTA IA banner (fundo escuro com âmbar)
  static const navyDark = Color(0xFF1A1F35);
}
