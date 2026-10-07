import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';

class DailyStatsWidget extends StatelessWidget {
  const DailyStatsWidget({super.key});

  Widget _buildStatCard(IconData icon, String value, String label, Color iconColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(color: AppColors.cream, fontSize: 11)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: AppColors.blue, fontSize: 8)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final trainer = context.watch<TrainerProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.navy, width: 2))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(Icons.directions_walk, '${trainer.dailySteps}', 'STEPS', AppColors.green),
              _buildStatCard(Icons.star, '+${trainer.xp}', 'TOTAL XP', AppColors.yellow),
              _buildStatCard(Icons.local_fire_department, '${trainer.streak} DAY', 'STREAK', Colors.orangeAccent),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.navy,
              border: Border.all(color: AppColors.blue, width: 1),
              borderRadius: BorderRadius.circular(4)
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.blue, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    trainer.dailySteps >= 1000 
                      ? 'Awesome! You secured your streak for today.' 
                      : 'Walk 1,000 steps today to keep your streak alive!',
                    style: TextStyle(
                      color: trainer.dailySteps >= 1000 ? AppColors.green : AppColors.cream, 
                      fontSize: 8
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}