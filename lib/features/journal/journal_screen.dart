import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';
import 'package:pokelife/core/data/world_data.dart';
import 'package:pokelife/core/data/achievement_data.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trainer = context.watch<TrainerProvider>();
    final totalRegions = WorldData.regions.length;
    final unlockedRegions = WorldData.regions.where((r) => trainer.steps >= r.unlockSteps).length;
    final lockedAchievements = AchievementData.achievements
        .where((a) => !trainer.unlockedAchievements.contains(a.id))
        .toList();
    final nextMilestone = lockedAchievements.isNotEmpty ? lockedAchievements.first : null;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('TRAINER JOURNAL', style: TextStyle(color: AppColors.cream, fontSize: 14)),
          const SizedBox(height: 20),
          
          // --- 1. İSTATİSTİKLER (LIFETIME STATS) ---
          const Text('LIFETIME STATS', style: TextStyle(color: AppColors.yellow, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.navy, 
              border: Border.all(color: AppColors.blue, width: 2)
            ),
            child: Column(
              children: [
                _buildStatRow('Total Steps', '${trainer.steps}'),
                const Divider(color: AppColors.darkBlue, height: 16),
                _buildStatRow('Best Daily Steps', '${trainer.bestDailySteps}'),
                const Divider(color: AppColors.darkBlue, height: 16),
                _buildStatRow('Pokémon Caught', '${trainer.caughtPokemonIds.length} / 151'),
                const Divider(color: AppColors.darkBlue, height: 16),
                _buildStatRow('Regions Unlocked', '$unlockedRegions / $totalRegions'),
              ],
            ),
          ),
          
          const SizedBox(height: 28),
          const Text('NEXT MILESTONE', style: TextStyle(color: AppColors.yellow, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),
          
          if (nextMilestone != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.darkBlue, border: Border.all(color: AppColors.purple, width: 2)),
              child: Row(
                children: [
                  const Icon(Icons.star, color: AppColors.purple, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nextMilestone.title, style: const TextStyle(color: AppColors.cream, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(nextMilestone.description, style: const TextStyle(color: AppColors.blue, fontSize: 9)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.purple.withValues(alpha: 0.2), border: Border.all(color: AppColors.purple, width: 1)),
                    child: Text('+${nextMilestone.rewardXp} XP', style: const TextStyle(color: AppColors.purple, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.darkBlue, border: Border.all(color: AppColors.green, width: 2)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events, color: AppColors.green, size: 24),
                  SizedBox(width: 12),
                  Text('ALL MILESTONES COMPLETED!', style: TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
          const SizedBox(height: 28),
          const Text('WORLD MAP PROGRESS', style: TextStyle(color: AppColors.yellow, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.navy, border: Border.all(color: AppColors.blue, width: 2)),
            child: Column(
              children: WorldData.regions.map((region) {
                final bool isUnlocked = trainer.steps >= region.unlockSteps;
                final bool isCurrent = WorldData.getCurrentRegion(trainer.steps).name == region.name;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Icon(
                        isUnlocked ? Icons.lock_open : Icons.lock, 
                        color: isCurrent ? AppColors.green : (isUnlocked ? AppColors.cream : AppColors.blue), 
                        size: 16
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              region.name.toUpperCase(), 
                              style: TextStyle(
                                color: isCurrent ? AppColors.green : (isUnlocked ? AppColors.cream : AppColors.blue), 
                                fontSize: 10, 
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal
                              )
                            ),
                            if (!isUnlocked)
                              Text('Unlocks at ${region.unlockSteps} steps', style: const TextStyle(color: AppColors.blue, fontSize: 8)),
                          ],
                        ),
                      ),
                      if (isCurrent)
                        const Text('CURRENT', style: TextStyle(color: AppColors.green, fontSize: 8, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 28),
          const Text('ACHIEVEMENTS', style: TextStyle(color: AppColors.yellow, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: AchievementData.achievements.map((achievement) {
              final bool isUnlocked = trainer.unlockedAchievements.contains(achievement.id);
              
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
                        Expanded(
                          child: Text(
                            achievement.title, 
                            style: TextStyle(
                              color: isUnlocked ? AppColors.cream : AppColors.blue, 
                              fontSize: 8, 
                              fontWeight: FontWeight.bold
                            ), 
                            overflow: TextOverflow.ellipsis
                          )
                        ),
                        if (isUnlocked) const Icon(Icons.check_circle, color: AppColors.green, size: 12),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description, 
                      style: TextStyle(color: AppColors.blue, fontSize: 7)
                    ),
                    if (!isUnlocked) ...[
                      const SizedBox(height: 4),
                      Text(
                        '+${achievement.rewardXp} XP', 
                        style: const TextStyle(color: AppColors.yellow, fontSize: 7, fontWeight: FontWeight.bold)
                      ),
                    ]
                  ],
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.blue, fontSize: 10)),
        Text(value, style: const TextStyle(color: AppColors.cream, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}