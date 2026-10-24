import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';
import 'package:pokelife/core/constants/game_constants.dart';

class DailyStatsWidget extends StatelessWidget {
  const DailyStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final trainer = context.watch<TrainerProvider>();
    final int todayStepXp = trainer.dailySteps ~/ GameConstants.stepsPerXp;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'DAILY STEPS',
            value: '${trainer.dailySteps}',
            subtitle: 'BEST: ${trainer.bestDailySteps}',
            valueColor: AppColors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            title: 'STREAK',
            value: '${trainer.streak} DAYS',
            subtitle: trainer.dailySteps >= GameConstants.dailyFirstMilestone
                ? '🔥 SECURED'
                : 'GOAL: 1,000',
            valueColor: AppColors.yellow,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            title: 'TOTAL XP',
            // DÜZELTME (Madde 10): Toplam XP başındaki yanıltıcı '+' kaldırıldı,
            // günlük kazanım alt satırda '+X TODAY' olarak ayrıştırıldı.
            value: '${trainer.xp}',
            subtitle: '+$todayStepXp TODAY',
            valueColor: AppColors.cream,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkBlue,
        border: Border.all(color: AppColors.blue, width: 2),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.blue,
              fontSize: 7,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.yellow,
              fontSize: 6.5,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}