import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/quest_provider.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';

class DailyQuestsWidget extends StatelessWidget {
  const DailyQuestsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final questProv = context.watch<QuestProvider>();
    final trainer = context.read<TrainerProvider>();
    final quests = questProv.quests;

    if (quests.isEmpty) {
      return const SizedBox.shrink();
    }

    // DÜZELTME (Madde 6): Tüm görevler talep edildiyse özel tamamlanma kartı göster
    if (questProv.allQuestsClaimed) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.darkBlue,
          border: Border.all(color: AppColors.green, width: 2),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '★ ALL DAILY QUESTS COMPLETE!',
              style: TextStyle(
                color: AppColors.green,
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'GREAT WALKING!',
              style: TextStyle(color: AppColors.yellow, fontSize: 7.5),
            ),
          ],
        ),
      );
    }

    // Henüz talep edilmemiş ilk görevi seç (Öncelik: Tamamlanmış ve ödülü bekleyen görev)
    final activeQuest = quests.firstWhere(
      (q) => q.isCompleted && !q.isClaimed,
      orElse: () => quests.firstWhere((q) => !q.isClaimed, orElse: () => quests.last),
    );

    // DÜZELTME (Madde 1): .toDouble() ile kesin double dönüşümü
    final double progress = (activeQuest.target > 0
            ? (activeQuest.current / activeQuest.target)
            : 0.0)
        .clamp(0.0, 1.0)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkBlue,
        border: Border.all(
          color: activeQuest.isCompleted ? AppColors.green : AppColors.blue,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                activeQuest.isCompleted ? '★ QUEST READY TO CLAIM!' : 'ACTIVE QUEST',
                style: TextStyle(
                  color: activeQuest.isCompleted ? AppColors.green : AppColors.yellow,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '+${activeQuest.rewardXp} XP',
                style: const TextStyle(
                  color: AppColors.yellow,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            activeQuest.title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.cream,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.navy,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${activeQuest.current} / ${activeQuest.target}',
                style: const TextStyle(color: AppColors.blue, fontSize: 7.5),
              ),
              if (activeQuest.isCompleted && !activeQuest.isClaimed)
                GestureDetector(
                  onTap: () async {
                    await questProv.claimReward(activeQuest.id, trainer);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      border: Border.all(color: AppColors.cream, width: 1),
                    ),
                    child: Text(
                      'CLAIM +${activeQuest.rewardXp} XP',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}