import 'package:flutter/material.dart';
import 'package:pokelife/core/theme/app_colors.dart';

class QuestScreen extends StatelessWidget {
  const QuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('QUESTS', style: TextStyle(color: AppColors.cream, fontSize: 16)),
          const SizedBox(height: 24),
          const Text('★ ACTIVE', style: TextStyle(color: AppColors.yellow, fontSize: 10)),
          const SizedBox(height: 12),
          
          // Aktif Görev Kartı
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.darkBlue,
              border: Border.all(color: AppColors.cream, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('THE LOST POKÉBALL', style: TextStyle(color: AppColors.cream, fontSize: 10)),
                const SizedBox(height: 12),
                const Text('Explore the forest and find the lost Pokéball.', 
                  style: TextStyle(color: AppColors.blue, fontSize: 8, height: 1.5)),
                const SizedBox(height: 16),
                
                // Alt Görevler
                _buildObjective('4,000 steps', true),
                _buildObjective('2 daily tasks', false),
                
                const SizedBox(height: 16),
                
                // İlerleme Çubuğu
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: 0.72,
                        minHeight: 10,
                        backgroundColor: AppColors.navy,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('72%', style: TextStyle(color: AppColors.yellow, fontSize: 8)),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Ödüller
                const Text('REWARD:', style: TextStyle(color: AppColors.blue, fontSize: 8)),
                const SizedBox(height: 8),
                const Text('⭐ 100 XP   🎒 x1', style: TextStyle(color: AppColors.yellow, fontSize: 10)),
                
                const SizedBox(height: 20),
                
                // Aksiyon Butonu
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    border: Border.all(color: AppColors.blue, width: 2),
                  ),
                  child: const Center(
                    child: Text('CONTINUE', style: TextStyle(color: AppColors.blue, fontSize: 10)),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const Text('UPCOMING', style: TextStyle(color: AppColors.blue, fontSize: 10)),
          const SizedBox(height: 12),
          
          // Kilitli Görev Kartı
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.navy,
              border: Border.all(color: AppColors.blue, width: 2),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock, color: AppColors.blue, size: 16),
                SizedBox(width: 12),
                Text('REACH LEVEL 5 TO UNLOCK', style: TextStyle(color: AppColors.blue, fontSize: 8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjective(String text, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_box : Icons.check_box_outline_blank,
            color: isDone ? AppColors.green : AppColors.blue,
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isDone ? AppColors.green : AppColors.cream,
              fontSize: 8,
              decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}