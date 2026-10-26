import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';
import 'package:pokelife/core/data/world_data.dart';
import 'package:pokelife/core/data/gym_data.dart';
import 'package:pokelife/core/data/achievement_data.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  List<String> _earnedGymBadges = [];

  @override
  void initState() {
    super.initState();
    _loadGymBadges();
  }

  Future<void> _loadGymBadges() async {
    final badges = await GymData.getEarnedBadges();
    if (mounted) {
      setState(() => _earnedGymBadges = badges);
    }
  }

  /// DÜZELTME (Madde 8.1): first_catch artık başlangıç partnerini saymaz,
  /// yalnızca gerçek vahşi yakalama (hasCaughtWildPokemon) yapıldığında 1/1 döner.
  ({int current, int target}) _getAchievementProgress(
    String id,
    TrainerProvider trainer,
  ) {
    switch (id) {
      case 'first_steps':
        return (current: trainer.steps.clamp(0, 1000).toInt(), target: 1000);
      case 'first_catch':
        return (current: trainer.hasCaughtWildPokemon ? 1 : 0, target: 1);
      case 'getting_serious':
        return (current: trainer.streak.clamp(0, 7).toInt(), target: 7);
      case 'long_walker':
        return (current: trainer.bestDailySteps.clamp(0, 10000).toInt(), target: 10000);
      case 'collector':
        return (current: trainer.caughtPokemonIds.length.clamp(0, 25).toInt(), target: 25);
      case 'explorer':
        final int unlockedCount =
            WorldData.regions.where((r) => trainer.steps >= r.unlockSteps).length;
        return (current: unlockedCount.clamp(0, 3).toInt(), target: 3);
      default:
        return (current: 0, target: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trainer = context.watch<TrainerProvider>();
    final int totalSteps = trainer.steps;
    final List<String> unlockedBadges = trainer.unlockedAchievements;

    final int maxWorldSteps = WorldData.regions.last.unlockSteps;
    // DÜZELTME (Madde 2.A): .toDouble() ile kesin double dönüşümü
    final double journeyProgress =
        (maxWorldSteps > 0 ? (totalSteps / maxWorldSteps) : 0.0)
            .clamp(0.0, 1.0)
            .toDouble();

    final GymLeader? nextLeader = GymData.getNextUndefeatedLeader(_earnedGymBadges);
    final int partnerLevel = trainer.activePartner?.level ?? trainer.level;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'KANTO JOURNEY & BADGES',
            style: TextStyle(
              color: AppColors.yellow,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // 1. WORLD EXPLORATION ÖZETİ
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkBlue,
              border: Border.all(color: AppColors.cream, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'WORLD EXPLORATION',
                      style: TextStyle(color: AppColors.yellow, fontSize: 8.5),
                    ),
                    Text(
                      '${(journeyProgress * 100).round()}%',
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: journeyProgress,
                  minHeight: 8,
                  backgroundColor: AppColors.navy,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lifetime Steps: $totalSteps / $maxWorldSteps',
                      style: const TextStyle(color: AppColors.cream, fontSize: 7.5),
                    ),
                    Text(
                      'Best Day: ${trainer.bestDailySteps}',
                      style: const TextStyle(color: AppColors.blue, fontSize: 7.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. DÜZELTME (Madde 3.4): GYM BADGES & NEXT CHALLENGE RPG KARTI
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkBlue,
              border: Border.all(color: AppColors.yellow, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🏅 GYM BADGES',
                      style: TextStyle(
                        color: AppColors.yellow,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_earnedGymBadges.length} / ${GymData.leaders.length} BADGES EARNED',
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: GymData.leaders.map((leader) {
                    final bool isEarned = _earnedGymBadges.contains(leader.badgeId);
                    return Opacity(
                      opacity: isEarned ? 1.0 : 0.35,
                      child: Column(
                        children: [
                          Text(leader.badgeEmoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(
                            leader.badgeName.split(' ').first.toUpperCase(),
                            style: TextStyle(
                              color: isEarned ? AppColors.cream : AppColors.blue,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const Divider(color: AppColors.navy, height: 18),
                if (nextLeader != null) ...[
                  const Text(
                    '⚔️ NEXT CHALLENGE',
                    style: TextStyle(
                      color: AppColors.yellow,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${nextLeader.leaderName} (${nextLeader.title})',
                          style: const TextStyle(
                            color: AppColors.cream,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Rec. Partner Lv.${nextLeader.recommendedLevel} (Yours: Lv.$partnerLevel)',
                        style: TextStyle(
                          color: partnerLevel >= nextLeader.recommendedLevel
                              ? AppColors.green
                              : Colors.orangeAccent,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ] else
                  const Text(
                    '👑 ALL REGIONAL GYM LEADERS CONQUERED!',
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. DÜZELTME (Madde 3.3): CERULEAN CAPE DAHİL KANTO BÖLGE HARİTASI (WorldData Kaynaklı)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkBlue,
              border: Border.all(color: AppColors.blue, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🗺️ KANTO REGION NODES',
                  style: TextStyle(
                    color: AppColors.yellow,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ...WorldData.regions.map((region) {
                  final bool unlocked = totalSteps >= region.unlockSteps;
                  final bool isCurrent = trainer.currentRegion.id == region.id;
                  return GestureDetector(
                    onTap: unlocked ? () => trainer.selectRegion(region.id) : null,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCurrent ? AppColors.navy : Colors.transparent,
                        border: Border.all(
                          color: isCurrent
                              ? AppColors.green
                              : (unlocked ? AppColors.blue : AppColors.navy),
                          width: isCurrent ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${unlocked ? "📍" : "🔒"} ${region.name.toUpperCase()}',
                            style: TextStyle(
                              color: isCurrent
                                  ? AppColors.green
                                  : (unlocked ? AppColors.cream : AppColors.blue),
                              fontSize: 8,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          Text(
                            unlocked
                                ? (isCurrent ? 'ACTIVE AREA' : 'UNLOCKED')
                                : '${region.unlockSteps} STEPS',
                            style: TextStyle(
                              color: isCurrent ? AppColors.green : AppColors.yellow,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. TRAINER ACHIEVEMENTS (Doğru Progress ve .toDouble() ile)
          const Text(
            'TRAINER ACHIEVEMENTS',
            style: TextStyle(
              color: AppColors.yellow,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...AchievementData.achievements.map((ach) {
            final bool isUnlocked = unlockedBadges.contains(ach.id);
            final prog = _getAchievementProgress(ach.id, trainer);
            final double pct = (prog.target > 0 ? (prog.current / prog.target) : 0.0)
                .clamp(0.0, 1.0)
                .toDouble();

            // Madde 8.2: Collector açıklaması benzersiz tür sayısını netleştirir
            final String description = ach.id == 'collector'
                ? 'Register 25 unique Pokémon species in your Pokédex.'
                : ach.description;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUnlocked ? AppColors.darkBlue : AppColors.navy,
                border: Border.all(
                  color: isUnlocked ? AppColors.green : AppColors.blue,
                  width: isUnlocked ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          ach.title.toUpperCase(),
                          style: TextStyle(
                            color: isUnlocked ? AppColors.yellow : AppColors.cream,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isUnlocked ? '✓ UNLOCKED' : '+${ach.rewardXp} XP',
                        style: TextStyle(
                          color: isUnlocked ? AppColors.green : AppColors.yellow,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: AppColors.cream, fontSize: 7.5),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: isUnlocked ? 1.0 : pct,
                          minHeight: 6,
                          backgroundColor: AppColors.darkBlue,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isUnlocked ? AppColors.green : AppColors.yellow,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${isUnlocked ? prog.target : prog.current}/${prog.target}',
                        style: const TextStyle(color: AppColors.blue, fontSize: 7),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}