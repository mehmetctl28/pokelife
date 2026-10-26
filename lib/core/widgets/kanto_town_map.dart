import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';
import 'package:pokelife/core/data/world_data.dart';
import 'package:pokelife/core/models/region.dart';

class MapNodeData {
  final String id;
  final String label;
  final int unlockSteps;
  final String icon;
  final bool isSelectableRegion;

  const MapNodeData({
    required this.id,
    required this.label,
    required this.unlockSteps,
    required this.icon,
    this.isSelectableRegion = true,
  });
}

class KantoTownMap extends StatelessWidget {
  const KantoTownMap({super.key});

  /// DÜZELTME (Madde 3.3): Tüm bölge isimleri ve açılma eşikleri doğrudan WorldData'dan alınır,
  /// 4. bölge olan Cerulean Cape haritaya dahil edilir.
  List<MapNodeData> _buildNodesFromWorldData() {
    final Region route1 = WorldData.getRegionById('route_1');
    final Region viridian = WorldData.getRegionById('viridian_forest');
    final Region mtMoon = WorldData.getRegionById('mt_moon');
    final Region cerulean = WorldData.getRegionById('cerulean_city');

    return [
      const MapNodeData(
        id: 'pallet_town',
        label: 'Pallet Town',
        unlockSteps: 0,
        icon: '🏠',
        isSelectableRegion: false,
      ),
      MapNodeData(
        id: route1.id,
        label: route1.name,
        unlockSteps: route1.unlockSteps,
        icon: '🌿',
      ),
      MapNodeData(
        id: viridian.id,
        label: viridian.name,
        unlockSteps: viridian.unlockSteps,
        icon: '🌲',
      ),
      MapNodeData(
        id: mtMoon.id,
        label: mtMoon.name,
        unlockSteps: mtMoon.unlockSteps,
        icon: '⛰️',
      ),
      MapNodeData(
        id: cerulean.id,
        label: cerulean.name,
        unlockSteps: cerulean.unlockSteps,
        icon: '🌊',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final trainer = context.watch<TrainerProvider>();
    final int totalSteps = trainer.steps;
    final String activeRegionId = trainer.currentRegion.id;
    final nodes = _buildNodesFromWorldData();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkBlue,
        border: Border.all(color: AppColors.cream, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🗺️ KANTO TOWN MAP',
                style: TextStyle(
                  color: AppColors.yellow,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'TAP UNLOCKED AREA TO TRAVEL',
                style: TextStyle(color: AppColors.blue, fontSize: 6.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(nodes.length, (index) {
            final node = nodes[index];
            final bool isUnlocked = totalSteps >= node.unlockSteps;
            final bool isCurrent = node.isSelectableRegion && activeRegionId == node.id;
            final bool isLast = index == nodes.length - 1;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: (node.isSelectableRegion && isUnlocked)
                      ? () => trainer.selectRegion(node.id)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.navy : Colors.transparent,
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.green
                            : (isUnlocked ? AppColors.blue : AppColors.navy),
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              isUnlocked ? node.icon : '🔒',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  node.label.toUpperCase(),
                                  style: TextStyle(
                                    color: isCurrent
                                        ? AppColors.green
                                        : (isUnlocked ? AppColors.cream : AppColors.blue),
                                    fontSize: 8.5,
                                    fontWeight:
                                        isCurrent ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                Text(
                                  isUnlocked
                                      ? (node.unlockSteps == 0
                                          ? 'Starting Point'
                                          : 'Unlocked (${node.unlockSteps} steps)')
                                      : 'Requires ${node.unlockSteps} steps',
                                  style: const TextStyle(color: AppColors.blue, fontSize: 6.5),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            color: AppColors.green,
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontSize: 6.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else if (isUnlocked && node.isSelectableRegion)
                          const Text(
                            'TRAVEL ▶',
                            style: TextStyle(color: AppColors.yellow, fontSize: 7),
                          ),
                      ],
                    ),
                  ),
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: Container(
                      width: 2,
                      height: 10,
                      color: isUnlocked ? AppColors.green : AppColors.navy,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}