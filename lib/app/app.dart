import 'package:flutter/material.dart';
import 'package:pokelife/core/theme/app_theme.dart';
import 'package:pokelife/features/home/home_screen.dart';

class PokelifeApp extends StatelessWidget {
  const PokelifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PokéLife',
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
