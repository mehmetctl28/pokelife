import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/quest_provider.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';

class QuestScreen extends StatelessWidget {
  const QuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final questProv = context.watch<QuestProvider>();
    final trainer = context.read<TrainerProvider>();
    final quests = questProv.quests;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DAILY QUEST BOARD',
                  style: TextStyle(
                    color: AppColors.yellow,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  questProv.allQuestsClaimed ? 'ALL COMPLETE! ★' : 'RESETS DAILY',
                  style: TextStyle(
                    color: questProv.allQuestsClaimed ? AppColors.green : AppColors.blue,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: quests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final q = quests[index];
                  // DÜZELTME (Madde 1): .toDouble() ile kesin double dönüşümü
                  final double progress =
                      (q.target > 0 ? (q.current / q.target) : 0.0)
                          .clamp(0.0, 1.0)
                          .toDouble();

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.darkBlue,
                      border: Border.all(
                        color: q.isClaimed
                            ? AppColors.blue
                            : (q.isCompleted ? AppColors.green : AppColors.cream),
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
                                q.title.toUpperCase(),
                                style: TextStyle(
                                  color: q.isClaimed ? AppColors.blue : AppColors.cream,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              color: AppColors.navy,
                              child: Text(
                                '+${q.rewardXp} XP',
                                style: const TextStyle(
                                  color: AppColors.yellow,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: AppColors.navy,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            q.isClaimed ? AppColors.blue : AppColors.green,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${q.current} /${q.target}',
                              style: const TextStyle(color: AppColors.cream, fontSize: 8),
                            ),
                            if (q.isClaimed)
                              const Text(
                                '✓ CLAIMED',
                                style: TextStyle(
                                  color: AppColors.blue,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else if (q.isCompleted)
                              GestureDetector(
                                onTap: () async {
                                  final success =
                                      await questProv.claimReward(q.id, trainer);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? '★ QUEST REWARD CLAIMED! +${q.rewardXp} XP'
                                            : 'Reward already claimed or unavailable.',
                                        style: const TextStyle(
                                          color: AppColors.navy,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor:
                                          success ? AppColors.green : AppColors.yellow,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.green,
                                    border: Border.all(color: AppColors.cream, width: 1.5),
                                  ),
                                  child: const Text(
                                    'CLAIM REWARD',
                                    style: TextStyle(
                                      color: AppColors.navy,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            else
                              const Text(
                                'IN PROGRESS',
                                style: TextStyle(color: AppColors.yellow, fontSize: 8),
                              ),
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