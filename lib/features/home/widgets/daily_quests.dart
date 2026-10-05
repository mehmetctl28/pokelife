import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/quest_provider.dart';

class DailyQuestsWidget extends StatelessWidget {
  const DailyQuestsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Widget kendi Provider'ını kendi dinliyor
    final questProvider = context.watch<QuestProvider>();

    // Boş dönmek (ekranı zıplatmak) yerine retro bir yükleniyor durumu gösteriyoruz
    if (questProvider.dailyQuests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.darkBlue, border: Border.all(color: AppColors.blue, width: 2)),
        child: const Center(child: Text('PREPARING ADVENTURE...', style: TextStyle(color: AppColors.blue, fontSize: 10))),
      );
    }

    final activeQuest = questProvider.dailyQuests.firstWhere(
      (q) => !q.isClaimed, 
      orElse: () => questProvider.dailyQuests.last
    );
    
    final String questTitle = activeQuest.title;
    final double questProgress = (activeQuest.progress / activeQuest.target).clamp(0.0, 1.0);
    final String questProgressText = "${(questProgress * 100).toInt()}%";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBlue, 
        border: Border.all(color: AppColors.blue, width: 2)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flag, color: AppColors.yellow, size: 14), 
              SizedBox(width: 8), 
              Text('ACTIVE QUEST', style: TextStyle(color: AppColors.yellow, fontSize: 10))
            ]
          ),
          const SizedBox(height: 12),
          Text(questTitle, style: const TextStyle(color: AppColors.cream, fontSize: 10)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: questProgress, 
                  minHeight: 6, 
                  backgroundColor: AppColors.navy, 
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.yellow)
                )
              ),
              const SizedBox(width: 12),
              Text(questProgressText, style: const TextStyle(color: AppColors.blue, fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }
}