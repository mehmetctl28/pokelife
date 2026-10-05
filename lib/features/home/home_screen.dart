import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';
import 'package:pokelife/core/providers/quest_provider.dart';
import 'package:pokelife/features/walk/walk_screen.dart';
import 'package:pokelife/features/journal/journal_screen.dart';
import 'package:pokelife/features/quests/quest_screen.dart';
import 'package:pokelife/features/pokedex/pokedex_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isJumping = false;
  bool _showHeart = false;

  void _interactWithPokemon() {
    if (_isJumping) return;
    setState(() {
      _isJumping = true;
      _showHeart = true;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isJumping = false);
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  Widget _buildHomePage(TrainerProvider trainer, QuestProvider questProvider) {
    final hour = DateTime.now().hour;
    final isNight = hour < 6 || hour > 18;
    final timeString = "${hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";
    
    final skyColor = isNight ? AppColors.navy : const Color(0xFF8BADD3);
    final groundColor = isNight ? const Color(0xFF2A5934) : const Color(0xFF52A55C);
    final skyIcon = isNight ? '🌙' : '☀️';

    // Dinamik Partner: Pokedex'teki ilk Pokémon, yoksa Bulbasaur (1)
    final int partnerId = trainer.caughtPokemonIds.isNotEmpty ? trainer.caughtPokemonIds.first : 1;
    
    // Dinamik Görev: Tamamlanmamış ilk görevi bul, yoksa en son görevi göster
    String questTitle = "All Caught Up!";
    double questProgress = 1.0;
    String questProgressText = "100%";
    
    if (questProvider.dailyQuests.isNotEmpty) {
      final activeQuest = questProvider.dailyQuests.firstWhere(
        (q) => !q.isClaimed, 
        orElse: () => questProvider.dailyQuests.last
      );
      questTitle = activeQuest.title;
      questProgress = (activeQuest.progress / activeQuest.target).clamp(0.0, 1.0);
      questProgressText = "${(questProgress * 100).toInt()}%";
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Day yazısı artık oyuncunun oyuna giriş serisine bağlı
              Text('DAY ${trainer.streak > 0 ? trainer.streak : 1}', style: const TextStyle(color: AppColors.cream, fontSize: 12)),
              Text('$timeString $skyIcon', style: const TextStyle(color: AppColors.yellow, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          
          GestureDetector(
            onTap: _interactWithPokemon,
            child: Container(
              height: 280,
              decoration: BoxDecoration(color: skyColor, border: Border.all(color: AppColors.cream, width: 4)),
              child: Stack(
                children: [
                  if (!isNight) ...[
                    const Positioned(top: 30, left: 20, child: Icon(Icons.cloud, color: Colors.white70, size: 30)),
                    const Positioned(top: 50, right: 40, child: Icon(Icons.cloud, color: Colors.white70, size: 20)),
                  ] else ...[
                    const Positioned(top: 20, left: 30, child: Text('✦', style: TextStyle(color: Colors.white70, fontSize: 12))),
                    const Positioned(top: 50, right: 40, child: Text('·', style: TextStyle(color: Colors.white70, fontSize: 16))),
                    const Positioned(top: 70, left: 80, child: Text('✦', style: TextStyle(color: Colors.white70, fontSize: 10))),
                  ],

                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(height: 90, decoration: BoxDecoration(color: groundColor, border: const Border(top: BorderSide(color: AppColors.cream, width: 2)))),
                  ),
                  
                  Positioned(bottom: 75, left: 20, child: Text('🌲', style: TextStyle(fontSize: 30, color: isNight ? Colors.black54 : null))),
                  Positioned(bottom: 65, right: 25, child: Text('🌲', style: TextStyle(fontSize: 40, color: isNight ? Colors.black54 : null))),

                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    bottom: _isJumping ? 90 : 60,
                    left: 0, right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(opacity: _showHeart ? 1.0 : 0.0, child: const Text('❤️', style: TextStyle(fontSize: 18))),
                        const SizedBox(height: 4),
                        // Sabit Bulbasaur yerine gerçek partner görseli
                        Image.network('https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iv/diamond-pearl/$partnerId.png', height: 100, fit: BoxFit.contain, filterQuality: FilterQuality.none),
                      ],
                    ),
                  ),
                  
                  Positioned(
                    bottom: 12, left: 0, right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.darkBlue.withValues(alpha: 0.8), border: Border.all(color: AppColors.cream, width: 1), borderRadius: BorderRadius.circular(4)),
                        child: Text('PARTNER  Lv. ${trainer.level}', style: const TextStyle(color: AppColors.cream, fontSize: 9)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          
          Row(
            children: [
              const Text('XP', style: TextStyle(color: AppColors.yellow, fontSize: 10)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(border: Border.all(color: AppColors.cream, width: 2)),
                  child: LinearProgressIndicator(
                    value: trainer.currentLevelXp / trainer.nextLevelXp, 
                    backgroundColor: AppColors.navy,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${trainer.currentLevelXp}/${trainer.nextLevelXp}', style: const TextStyle(color: AppColors.blue, fontSize: 8)),
            ],
          ),
          
          const SizedBox(height: 28),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.darkBlue, border: Border.all(color: AppColors.blue, width: 2)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [Icon(Icons.flag, color: AppColors.yellow, size: 14), SizedBox(width: 8), Text('ACTIVE QUEST', style: TextStyle(color: AppColors.yellow, fontSize: 10))]),
                const SizedBox(height: 12),
                // Sabit görev yerine QuestProvider'dan gelen gerçek anlık görev
                Text(questTitle, style: const TextStyle(color: AppColors.cream, fontSize: 10)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: LinearProgressIndicator(value: questProgress, minHeight: 6, backgroundColor: AppColors.navy, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.yellow))),
                    const SizedBox(width: 12),
                    Text(questProgressText, style: const TextStyle(color: AppColors.blue, fontSize: 8)),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.navy, width: 2))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(Icons.directions_walk, '${trainer.dailySteps}', 'STEPS', AppColors.green),
                _buildStatCard(Icons.star, '+${trainer.xp}', 'TOTAL XP', AppColors.yellow),
                _buildStatCard(Icons.local_fire_department, '${trainer.streak} DAY', 'STREAK', Colors.orangeAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color iconColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(color: AppColors.cream, fontSize: 11)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: AppColors.blue, fontSize: 8)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final trainer = context.watch<TrainerProvider>();
    final questProvider = context.watch<QuestProvider>(); 

    // YENİ: Veriler henüz hafızadan okunmadıysa Yükleniyor ekranı göster
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
          _buildHomePage(trainer, questProvider),
          const WalkScreen(),
          const JournalScreen(),
          const QuestScreen(),
          const PokedexScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.darkBlue,
        indicatorColor: AppColors.purple.withValues(alpha: 0.4), 
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'HOME'),
          NavigationDestination(icon: Icon(Icons.directions_walk), label: 'WALK'),
          NavigationDestination(icon: Icon(Icons.book), label: 'LOG'),
          NavigationDestination(icon: Icon(Icons.star), label: 'TASK'),
          NavigationDestination(icon: Icon(Icons.catching_pokemon), label: 'DEX')
        ],
      ),
    );
  }
}