import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';
import 'package:pokelife/core/providers/quest_provider.dart';
import 'package:pokelife/core/theme/app_theme.dart';
import 'package:pokelife/features/home/home_screen.dart';

class PokelifeApp extends StatelessWidget {
  const PokelifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TrainerProvider>(create: (_) => TrainerProvider()),
        ChangeNotifierProvider<QuestProvider>(create: (_) => QuestProvider()),
      ],
      child: MaterialApp(
        title: 'PokéLife',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}