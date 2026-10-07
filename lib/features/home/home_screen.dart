import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';
import 'package:pokelife/features/walk/walk_screen.dart';
import 'package:pokelife/features/journal/journal_screen.dart';
import 'package:pokelife/features/quests/quest_screen.dart';
import 'package:pokelife/features/pokedex/pokedex_screen.dart';

// Modüler Widget'larımız
import 'package:pokelife/features/home/widgets/partner_scene.dart';
import 'package:pokelife/features/home/widgets/daily_quests.dart';
import 'package:pokelife/features/home/widgets/daily_stats.dart';
import 'package:pokelife/features/home/widgets/xp_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  Widget _buildHomeTab(TrainerProvider trainer) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          PartnerScene(),         // 1. Partner sahnesi, saat, gökyüzü ve streak
          SizedBox(height: 16),
          XpBarWidget(),          // 2. Tertemiz, RPG tarzı XP Çubuğumuz (LV, Bar, Rakamlar)
          SizedBox(height: 28),
          DailyQuestsWidget(),    // 3. Tekil ve düzenli Günlük Görevler
          SizedBox(height: 24),
          DailyStatsWidget(),     // 4. Adım, Toplam XP ve Streak alt kartları
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trainer = context.watch<TrainerProvider>();

    if (!trainer.isInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.darkBlue,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('LOADING...', style: TextStyle(color: AppColors.yellow, fontSize: 16, letterSpacing: 2)),
              SizedBox(height: 20),
              CircularProgressIndicator(color: AppColors.green),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(trainer), 
          const WalkScreen(),
          const JournalScreen(),
          const QuestScreen(),
          const PokedexScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.blue),
          ),
        ),
        child: NavigationBar(
          height: 65,
          backgroundColor: AppColors.darkBlue,
          indicatorColor: AppColors.purple.withValues(alpha: 0.4),
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'HOME'),
            NavigationDestination(icon: Icon(Icons.directions_walk), label: 'WALK'),
            NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'JOURNEY'),
            NavigationDestination(icon: Icon(Icons.star_border), selectedIcon: Icon(Icons.star), label: 'TASK'),
            NavigationDestination(icon: Icon(Icons.catching_pokemon), label: 'DEX'),
          ],
        ),
      ),
    );
  }
}