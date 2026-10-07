import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';

class XpBarWidget extends StatelessWidget {
  const XpBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final trainer = context.watch<TrainerProvider>();
    
    // Güvenlik: Sıfıra bölünme hatasını engellemek için
    final double progress = trainer.nextLevelXp > 0 
        ? trainer.currentLevelXp / trainer.nextLevelXp 
        : 0.0;

    return Row(
      children: [
        // Raporun istediği: LV. 4
        Text('LV. ${trainer.level}', style: const TextStyle(color: AppColors.yellow, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(width: 12),
        
        // Raporun istediği: ██████░░░░ (Dinamik Çubuk)
        Expanded(
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.navy,
              border: Border.all(color: AppColors.cream, width: 2)
            ),
            child: LinearProgressIndicator(
              value: progress, 
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // Raporun istediği: 240 / 400 XP
        Text('${trainer.currentLevelXp} / ${trainer.nextLevelXp} XP', style: const TextStyle(color: AppColors.cream, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}