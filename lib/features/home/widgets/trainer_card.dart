import 'package:flutter/material.dart';
import 'package:pokelife/core/theme/app_colors.dart';
class TrainerCard extends StatelessWidget {
  final int xp;
  final int level;
  const TrainerCard({super.key, required this.xp, required this.level});
  @override
  Widget build(BuildContext context) {
    const int xpPerLevel = 100;
    final int currentLevelXp = xp % xpPerLevel;
    final double progress = currentLevelXp / xpPerLevel;
    return Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.darkBlue, border: Border.all(color: AppColors.cream, width: 2)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('TRAINER LV.$level', style: const TextStyle(color: AppColors.cream, fontSize: 12)), const SizedBox(height: 8), const Text('ROOKIE', style: TextStyle(color: AppColors.blue, fontSize: 8))])), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.25), border: Border.all(color: AppColors.cream)), child: const Icon(Icons.person, color: AppColors.cream, size: 24))]), const SizedBox(height: 20), LinearProgressIndicator(value: progress, minHeight: 14, backgroundColor: AppColors.navy, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.yellow)), const SizedBox(height: 8), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('$currentLevelXp/$xpPerLevel XP', style: const TextStyle(color: AppColors.blue, fontSize: 8)), Text('${xpPerLevel - currentLevelXp} LEFT', style: const TextStyle(color: AppColors.yellow, fontSize: 8))])]));
  }
}
