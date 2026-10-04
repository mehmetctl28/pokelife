import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/quest_provider.dart';

class DailyQuestsWidget extends StatelessWidget {
  const DailyQuestsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final questProvider = context.watch<QuestProvider>();
    final quests = questProvider.dailyQuests;

    if (quests.isEmpty) {
      return const SizedBox.shrink();
    }

    // Tamamlanmayan ilk görevi ana sayfada mini kart olarak gösterelim
    final activeQuest = quests.firstWhere(
      (q) => !q.isClaimed,
      orElse: () => quests.first,
    );

    double progressValue = (activeQuest.progress / activeQuest.target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkBlue,
        border: Border.all(color: AppColors.blue, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ACTIVE QUEST', style: TextStyle(color: AppColors.yellow, fontSize: 8)),
              Text('+${activeQuest.rewardXp} XP', style: const TextStyle(color: AppColors.green, fontSize: 8, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Text(activeQuest.title, style: const TextStyle(color: AppColors.cream, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progressValue,
            minHeight: 6,
            backgroundColor: AppColors.navy,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
          ),
          const SizedBox(height: 4),
          Text(
            'Progress: ${activeQuest.progress} / ${activeQuest.target}', 
            style: const TextStyle(color: AppColors.blue, fontSize: 7),
          ),
        ],
      ),
    );
  }
}