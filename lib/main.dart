import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_theme.dart';
import 'package:pokelife/features/home/home_screen.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';

void main() {
  runApp(
    // Tüm uygulamayı Provider ile sarıyoruz
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TrainerProvider()),
      ],
      child: const PokeLifeApp(),
    ),
  );
}

class PokeLifeApp extends StatelessWidget {
  const PokeLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokéLife',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}