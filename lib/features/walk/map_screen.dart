import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';

class MapScreen extends StatelessWidget {
  final Function(String selectedArea) onAreaSelected;

  const MapScreen({super.key, required this.onAreaSelected});

  @override
  Widget build(BuildContext context) {
    final trainer = context.watch<TrainerProvider>();
    final steps = trainer.dailySteps;

    // Bölge kilit koşulları
    final bool isLakeUnlocked = steps >= 3000;
    final bool isMountainUnlocked = steps >= 7000; // İlerisi için yeni bir bölge

    return Dialog(
      backgroundColor: AppColors.darkBlue,
      shape: Border.all(color: AppColors.cream, width: 3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'WORLD MAP',
              style: TextStyle(color: AppColors.yellow, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a region to explore',
              style: TextStyle(color: AppColors.blue, fontSize: 8),
            ),
            const SizedBox(height: 16),

            // BÖLGE 1: WHISPERING FOREST (Her zaman açık)
            _buildMapNode(
              context,
              title: '🌲 WHISPERING FOREST',
              subtitle: 'Starting Area (Normal Encounters)',
              isUnlocked: true,
              onTap: () {
                onAreaSelected('Whispering Forest');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),

            // BÖLGE 2: AZURE LAKE (3,000 Adımda açılır)
            _buildMapNode(
              context,
              title: '🌊 AZURE LAKE',
              subtitle: isLakeUnlocked ? 'Water-type Encounters' : 'Unlocks at 3,000 steps',
              isUnlocked: isLakeUnlocked,
              onTap: isLakeUnlocked
                  ? () {
                      onAreaSelected('Azure Lake');
                      Navigator.pop(context);
                    }
                  : null,
            ),
            const SizedBox(height: 12),

            // BÖLGE 3: MOUNT PYRE / CAVE (7,000 Adımda açılır)
            _buildMapNode(
              context,
              title: '⛰️ ROCKY CAVE',
              subtitle: isMountainUnlocked ? 'Rock/Ground Encounters' : 'Unlocks at 7,000 steps',
              isUnlocked: isMountainUnlocked,
              onTap: isMountainUnlocked
                  ? () {
                      onAreaSelected('Rocky Cave');
                      Navigator.pop(context);
                    }
                  : null,
            ),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(border: Border.all(color: AppColors.cream, width: 2)),
                child: const Text('CLOSE', style: TextStyle(color: AppColors.cream, fontSize: 9)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapNode(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isUnlocked,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnlocked ? AppColors.navy : AppColors.yellow,
          border: Border.all(
            color: isUnlocked ? AppColors.green : AppColors.yellow,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isUnlocked ? AppColors.cream : AppColors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isUnlocked ? AppColors.yellow : AppColors.yellow,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isUnlocked ? Icons.map : Icons.lock,
              color: isUnlocked ? AppColors.green : AppColors.blue,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}