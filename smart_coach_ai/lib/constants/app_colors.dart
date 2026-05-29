import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Design System Colors
  static const Color background = Color(0xFFF4FAFD); // kSkyLighter (Fond global)
  static const Color surface = Color(0xFFFFFFFF);    // kWhite
  static const Color primary = Color(0xFF87CEEB);    // kSky (Couleur principale bleu ciel)
  static const Color primaryLight = Color(0xFFE8F6FC); // kSkyLight (Fonds de cartes)
  static const Color sky = Color(0xFF87CEEB);        // kSky
  static const Color skyDark = Color(0xFF4A9FC0);    // kSkyDark (Accents & textes actifs)
  static const Color text = Color(0xFF1A2332);       // kText (Texte principal)
  static const Color textSoft = Color(0xFF5A6A7A);   // kText2 (Texte secondaire)
  static const Color muted = Color(0xFFA0AAB8);      // kText3 (Placeholder / hints)
  static const Color outline = Color(0xFFE2EDF5);    // kBorder (Bordures)
  
  static const Color success = Color(0xFF27AE60);    // kGreen (Succès)
  static const Color danger = Color(0xFFE74C3C);     // kRed (Erreur / stress)
  static const Color warning = Color(0xFFF0A500);    // kAmber (Avertissement)
  static const Color navIcon = Color(0xFF5A6A7A);

  // Legacy mappings for compatibility
  static const Color softPurple = Color(0xFFE8F6FC);
  static const Color softSky = Color(0xFFF4FAFD);
  static const Color softGreen = Color(0xFFD8FCE8);
  static const Color softOrange = Color(0xFFFFF4E7);
  static const Color grayBar = Color(0xFFE2EDF5);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, skyDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient skyGradient = LinearGradient(
    colors: [Color(0xFFE8F6FC), primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightWash = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF4FAFD), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
