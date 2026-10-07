import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/quest_provider.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';

class QuestScreen extends StatelessWidget {
  const QuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final questProvider = context.watch<QuestProvider>();
    final trainerProvider = context.read<TrainerProvider>();
    final quests = questProvider.dailyQuests;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('DAILY QUESTS', style: TextStyle(color: AppColors.cream, fontSize: 14, letterSpacing: 1)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(2)),
                  child: const Text('RESETS DAILY', style: TextStyle(color: AppColors.navy, fontSize: 7, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(color: AppColors.blue, thickness: 2, height: 16),
            const Text('Complete tasks to earn XP and power up your partner.', style: TextStyle(color: AppColors.blue, fontSize: 8)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: quests.length,
                itemBuilder: (context, index) {
                  final quest = quests[index];
                  final bool isCompleted = quest.progress >= quest.target;
                  double progressValue = (quest.progress / quest.target).clamp(0.0, 1.0);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.darkBlue,
                      border: Border.all(
                        color: quest.isClaimed ? AppColors.navy : (isCompleted ? AppColors.green : AppColors.blue), 
                        width: 2,
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
                                quest.title, 
                                style: TextStyle(color: quest.isClaimed ? AppColors.blue : AppColors.cream, fontSize: 10, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text('+${quest.rewardXp} XP', style: const TextStyle(color: AppColors.yellow, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progressValue,
                          minHeight: 6,
                          backgroundColor: AppColors.navy,
                          valueColor: AlwaysStoppedAnimation<Color>(quest.isClaimed ? AppColors.blue : (isCompleted ? AppColors.green : AppColors.yellow)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Progress: ${quest.progress} / ${quest.target}', style: const TextStyle(color: AppColors.blue, fontSize: 8)),
                            if (quest.isClaimed)
                              const Text('CLAIMED ✓', style: TextStyle(color: AppColors.blue, fontSize: 8, fontWeight: FontWeight.bold))
                            else if (isCompleted)
                              GestureDetector(
                               onTap: () {
                                questProvider.claimReward(quest.id, trainerProvider);
                               },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.green, border: Border.all(color: AppColors.green, width: 1)),
                                  child: const Text('CLAIM', style: TextStyle(color: AppColors.navy, fontSize: 8, fontWeight: FontWeight.bold)),
                                ),
                              )
                            else
                              const Text('IN PROGRESS', style: TextStyle(color: AppColors.yellow, fontSize: 8)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}