import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';

class XpBarWidget extends StatelessWidget {
  const XpBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final trainer = context.watch<TrainerProvider>();
    final partner = trainer.activePartner;

    // Aktif partnerin bireysel verileri
    final int level = partner?.level ?? 5;
    final int currentXp = partner?.xp ?? 0;
    final int maxXp = partner?.nextLevelXp ?? 500;
    final double progress = (maxXp > 0) ? (currentXp / maxXp).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LV. $level',
              style: const TextStyle(
                color: AppColors.cream,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Text(
              '$currentXp / $maxXp XP',
              style: const TextStyle(
                color: AppColors.yellow,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 12,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cream, width: 2),
          ),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.navy,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
          ),
        ),
      ],
    );
  }
}