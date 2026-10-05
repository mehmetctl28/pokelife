import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trainer = context.watch<TrainerProvider>();
    final steps = trainer.steps;
    final caughtCount = trainer.caughtPokemonIds.length;
    final streak = trainer.streak;
    
    // Şimdilik UI mock verileri (Sonraki adımda Provider'a eklenecek)
    final int bestDailySteps = trainer.bestDailySteps;
    final int regionsUnlocked = trainer.unlockedRegions;

    // RPG Stat Hesaplamaları (Yeni ve Mantıklı Formüller)
    final double endurance = (bestDailySteps / 20000).clamp(0.1, 1.0); // 20k rekor = Full Bar
    final double consistency = (streak / 7).clamp(0.1, 1.0);  // 7 gün seri = Full Bar
    final double discovery = (caughtCount / 151).clamp(0.1, 1.0); // 151 Pokemon = Full Bar

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ==========================================
          // 1. TRAINER STATS
          // ==========================================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkBlue,
              border: Border.all(color: AppColors.cream, width: 2),
            ),
            child: Column(
              children: [
                const Text('YOUR JOURNEY', style: TextStyle(color: AppColors.yellow, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TRAINER LV. ${trainer.level}', style: const TextStyle(color: AppColors.cream, fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('$steps TOTAL STEPS', style: const TextStyle(color: AppColors.blue, fontSize: 9)),
                        const SizedBox(height: 2),
                        Text('🔥 $streak DAY STREAK', style: const TextStyle(color: Colors.orangeAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.blue, width: 1)),
                      child: Column(
                        children: [
                          const Text('BEST DAY', style: TextStyle(color: AppColors.blue, fontSize: 7)),
                          const SizedBox(height: 4),
                          Text('$bestDailySteps', style: const TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.navy, thickness: 2),
                const SizedBox(height: 12),
                
                _buildRpgStat('ENDURANCE', endurance, AppColors.green),
                const SizedBox(height: 8),
                _buildRpgStat('CONSISTENCY', consistency, Colors.orangeAccent),
                const SizedBox(height: 8),
                _buildRpgStat('DISCOVERY', discovery, AppColors.purple),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==========================================
          // 2. WORLD MAP
          // ==========================================
          const Text('WORLD MAP', style: TextStyle(color: AppColors.yellow, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.navy, border: Border.all(color: AppColors.blue, width: 2)),
            child: Column(
              children: [
                _buildMapNode('🌱 PALLET MEADOW', true, true),
                _buildMapPath(regionsUnlocked >= 2),
                _buildMapNode('🌊 AZURE LAKE', false, regionsUnlocked >= 2),
                _buildMapPath(regionsUnlocked >= 3),
                _buildMapNode('⛰️ ROCKY CAVE', false, regionsUnlocked >= 3),
                _buildMapPath(regionsUnlocked >= 4),
                _buildMapNode('❄️ SNOW PEAK', false, regionsUnlocked >= 4),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==========================================
          // 3. ADVENTURE STREAK
          // ==========================================
          const Text('ADVENTURE STREAK', style: TextStyle(color: AppColors.yellow, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.darkBlue, border: Border.all(color: Colors.orangeAccent, width: 2)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 16),
                    const SizedBox(width: 8),
                    Text('$streak DAYS', style: const TextStyle(color: AppColors.cream, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 16),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'].asMap().entries.map((entry) {
                    int idx = entry.key;
                    bool isLit = idx < (streak % 7 == 0 && streak > 0 ? 7 : streak % 7);
                    return Column(
                      children: [
                        Text(entry.value, style: TextStyle(color: isLit ? AppColors.cream : AppColors.blue, fontSize: 8)),
                        const SizedBox(height: 8),
                        Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isLit ? Colors.orangeAccent : AppColors.navy,
                            border: Border.all(color: isLit ? Colors.orangeAccent : AppColors.blue, width: 1)
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Next milestone: 7 Days → 🔓 Rare Encounter', style: TextStyle(color: AppColors.blue, fontSize: 9)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==========================================
          // 4. NEXT MILESTONE (HOOK)
          // ==========================================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkBlue, 
              border: Border.all(color: AppColors.yellow, width: 2),
              boxShadow: [BoxShadow(color: AppColors.yellow.withValues(alpha: 0.1), spreadRadius: 2, blurRadius: 8)]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.star, color: AppColors.yellow, size: 16),
                    SizedBox(width: 8),
                    Text('NEXT MILESTONE', style: TextStyle(color: AppColors.yellow, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('🗺️ EXPLORER', style: TextStyle(color: AppColors.cream, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Unlock 3 regions on the World Map.', style: TextStyle(color: AppColors.blue, fontSize: 9)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (regionsUnlocked / 3).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: AppColors.navy,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.yellow),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('$regionsUnlocked / 3', style: const TextStyle(color: AppColors.cream, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('+100 XP', style: TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==========================================
          // 5. ALL MILESTONES GRID
          // ==========================================
          const Text('ACHIEVEMENTS', style: TextStyle(color: AppColors.yellow, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _buildMilestoneCard('🥾 FIRST STEPS', '1,000 total steps', steps >= 1000),
              _buildMilestoneCard('🔴 FIRST CATCH', 'Catch 1 Pokémon', caughtCount >= 1),
              _buildMilestoneCard('🔥 GETTING SERIOUS', '7-day streak', streak >= 7),
              _buildMilestoneCard('🏃 LONG WALKER', '10k steps in a day', bestDailySteps >= 10000),
              _buildMilestoneCard('🎒 COLLECTOR', 'Catch 25 Pokémon', caughtCount >= 25),
              _buildMilestoneCard('🗺️ EXPLORER', 'Unlock 3 regions', regionsUnlocked >= 3),
            ],
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRpgStat(String label, double percentage, Color color) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(color: AppColors.blue, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 10,
            backgroundColor: AppColors.navy,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMapNode(String title, bool isStart, bool isUnlocked) {
    return Row(
      children: [
        Container(
          width: 16, height: 16,
          decoration: BoxDecoration(
            color: isUnlocked ? AppColors.green : AppColors.navy,
            shape: BoxShape.circle,
            border: Border.all(color: isUnlocked ? AppColors.cream : AppColors.blue, width: 2),
          ),
        ),
        const SizedBox(width: 16),
        Text(title, style: TextStyle(
          color: isUnlocked ? AppColors.cream : AppColors.blue, 
          fontSize: 12, 
          fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal
        )),
        if (!isUnlocked) ...[
          const Spacer(),
          const Icon(Icons.lock, color: AppColors.blue, size: 14),
        ]
      ],
    );
  }

  Widget _buildMapPath(bool isUnlocked) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 7, top: 4, bottom: 4),
      child: Container(width: 2, height: 24, color: isUnlocked ? AppColors.green : AppColors.blue),
    );
  }

  Widget _buildMilestoneCard(String title, String desc, bool isUnlocked) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isUnlocked ? AppColors.darkBlue : AppColors.navy,
        border: Border.all(color: isUnlocked ? AppColors.cream : AppColors.blue, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: TextStyle(color: isUnlocked ? AppColors.cream : AppColors.blue, fontSize: 8, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              if (isUnlocked) const Icon(Icons.check_circle, color: AppColors.green, size: 12),
            ],
          ),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(color: AppColors.blue, fontSize: 7)),
        ],
      ),
    );
  }
}