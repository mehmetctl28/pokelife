import 'package:flutter/material.dart';
import 'package:pokelife/core/models/daily_quest.dart';
import 'package:pokelife/core/theme/app_colors.dart';
class DailyQuests extends StatelessWidget {
  final List<DailyQuest> quests;
  final void Function(int index) onComplete;
  const DailyQuests({super.key, required this.quests, required this.onComplete});
  @override
  Widget build(BuildContext context) {
    final completedCount = quests.where((quest) => quest.isCompleted).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('QUESTS', style: TextStyle(color: AppColors.cream, fontSize: 12)), Text('$completedCount/${quests.length}', style: const TextStyle(color: AppColors.yellow, fontSize: 12))]), const SizedBox(height: 12), ...List.generate(quests.length, (index) { final quest = quests[index]; return GestureDetector(onTap: () => onComplete(index), child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.darkBlue, border: Border.all(color: AppColors.cream, width: 2)), child: Row(children: [Icon(quest.isCompleted ? Icons.check_box : Icons.check_box_outline_blank, color: quest.isCompleted ? AppColors.green : AppColors.blue, size: 20), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(quest.title.toUpperCase(), style: TextStyle(color: quest.isCompleted ? AppColors.blue : AppColors.cream, fontSize: 9, decoration: quest.isCompleted ? TextDecoration.lineThrough : TextDecoration.none)), const SizedBox(height: 6), Text(quest.description, style: const TextStyle(color: AppColors.blue, fontSize: 7))])), Text('+${quest.xpReward}', style: TextStyle(color: quest.isCompleted ? AppColors.green : AppColors.yellow, fontSize: 9))]))); })]);
  }
}
