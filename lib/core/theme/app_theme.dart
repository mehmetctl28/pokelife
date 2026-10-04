import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pokelife/core/theme/app_colors.dart';
class AppTheme {
  static ThemeData darkTheme = ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: AppColors.navy, fontFamily: GoogleFonts.pressStart2p().fontFamily, colorScheme: const ColorScheme.dark(primary: AppColors.purple, secondary: AppColors.yellow, surface: AppColors.darkBlue), appBarTheme: const AppBarTheme(backgroundColor: AppColors.navy, elevation: 0), cardTheme: const CardThemeData(color: AppColors.darkBlue, elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero)));
}
