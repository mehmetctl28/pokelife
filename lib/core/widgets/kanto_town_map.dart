import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';

class MapNode {
  final String id;
  final String name;
  final double x; // 0.0 - 1.0 arası yüzdesel X konumu
  final double y; // 0.0 - 1.0 arası yüzdesel Y konumu
  final bool isCity;
  final int unlockSteps;

  const MapNode({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.isCity,
    required this.unlockSteps,
  });
}

class KantoTownMap extends StatefulWidget {
  const KantoTownMap({super.key});

  @override
  State<KantoTownMap> createState() => _KantoTownMapState();
}

class _KantoTownMapState extends State<KantoTownMap> {
  // Harita üzerinde dokunup incelediğimiz düğüm
  String? _inspectedNodeId;

  static const List<MapNode> nodes = [
    MapNode(
      id: 'pallet_town',
      name: 'Pallet Town',
      x: 0.30,
      y: 0.78,
      isCity: true,
      unlockSteps: 0,
    ),
    MapNode(
      id: 'route_1',
      name: 'Route 1',
      x: 0.30,
      y: 0.54,
      isCity: false,
      unlockSteps: 0,
    ),
    MapNode(
      id: 'viridian_forest',
      name: 'Viridian Forest',
      x: 0.30,
      y: 0.28,
      isCity: false,
      unlockSteps: 15000,
    ),
    MapNode(
      id: 'mt_moon',
      name: 'Mt. Moon',
      x: 0.72,
      y: 0.18,
      isCity: false,
      unlockSteps: 35000,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final trainer = context.watch<TrainerProvider>();
    final currentRegion = trainer.currentRegion;

    // Seçili veya incelenen düğümü bul
    final targetId = _inspectedNodeId ?? currentRegion.id;
    final selectedNode = nodes.firstWhere(
      (n) => n.id == targetId,
      orElse: () => nodes.first,
    );

    final bool isTargetUnlocked = trainer.steps >= selectedNode.unlockSteps;
    final bool isAlreadyHere = (currentRegion.id == selectedNode.id) ||
        (selectedNode.id == 'pallet_town' && currentRegion.id == 'route_1');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkBlue,
        border: Border.all(color: AppColors.cream, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: AppColors.navy,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOWN MAP // KANTO',
                  style: TextStyle(
                    color: AppColors.yellow,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text('YOU', style: TextStyle(color: AppColors.cream, fontSize: 8)),
                  ],
                ),
              ],
            ),
          ),

          // Harita Alanı
          Container(
            height: 240,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF162D3D),
              border: Border.all(color: AppColors.blue, width: 2),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;

                return Stack(
                  children: [
                    // Arka plan ızgarası
                    CustomPaint(
                      size: Size(w, h),
                      painter: _MapGridLinesPainter(),
                    ),
                    // Yollar
                    CustomPaint(
                      size: Size(w, h),
                      painter: _MapRoadsPainter(nodes: nodes),
                    ),

                    // Harita Düğümleri
                    ...nodes.map((node) {
                      final bool isUnlocked = trainer.steps >= node.unlockSteps;
                      final bool isPlayerHere = (currentRegion.id == node.id) ||
                          (node.id == 'pallet_town' && currentRegion.id == 'route_1');
                      final bool isInspected = selectedNode.id == node.id;

                      final double posX = node.x * w;
                      final double posY = node.y * h;

                      return Positioned(
                        left: posX - 28,
                        top: posY - 20,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _inspectedNodeId = node.id);
                          },
                          child: SizedBox(
                            width: 56,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Kutu + Pin
                                Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: node.isCity ? 26 : 22,
                                      height: node.isCity ? 26 : 22,
                                      decoration: BoxDecoration(
                                        color: isInspected
                                            ? AppColors.green
                                            : (isUnlocked ? AppColors.cream : AppColors.navy),
                                        border: Border.all(
                                          color: isInspected
                                              ? AppColors.yellow
                                              : (isUnlocked ? AppColors.cream : AppColors.blue),
                                          width: isInspected ? 2.5 : 1.5,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          isUnlocked
                                              ? (node.isCity ? Icons.home_filled : Icons.terrain)
                                              : Icons.lock,
                                          color: isInspected
                                              ? AppColors.navy
                                              : (isUnlocked ? AppColors.navy : AppColors.blue),
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                    // Oyuncu Konum İbresi (Kırmızı Ok)
                                    if (isPlayerHere)
                                      Positioned(
                                        top: -12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent,
                                            border: Border.all(color: Colors.white, width: 1),
                                          ),
                                          child: const Text(
                                            '▼',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 7,
                                              height: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                // İsim Etiketi
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                  color: AppColors.navy.withValues(alpha: 0.9),
                                  child: Text(
                                    node.name.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isPlayerHere
                                          ? AppColors.yellow
                                          : (isUnlocked ? AppColors.cream : AppColors.blue),
                                      fontSize: 6.5,
                                      fontWeight: isPlayerHere ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),

          // Alt Konsol Bilgi & Aksiyon Kartı (İki liste yerine geçen temiz panel)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.navy,
              border: Border(top: BorderSide(color: AppColors.blue, width: 2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isTargetUnlocked ? Icons.lock_open : Icons.lock,
                            color: isTargetUnlocked ? AppColors.green : AppColors.blue,
                            size: 13,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              selectedNode.name.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.cream,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        !isTargetUnlocked
                            ? 'Unlocks at ${selectedNode.unlockSteps} steps'
                            : (isAlreadyHere ? 'Current active location' : 'Ready to travel'),
                        style: TextStyle(
                          color: isTargetUnlocked ? AppColors.blue : Colors.redAccent,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Aksiyon Butonu
                if (isAlreadyHere)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.green, width: 1.5),
                    ),
                    child: const Text(
                      'HERE',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (isTargetUnlocked)
                  GestureDetector(
                    onTap: () {
                      final destId = selectedNode.id == 'pallet_town' ? 'route_1' : selectedNode.id;
                      trainer.selectRegion(destId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Traveled to ${selectedNode.name}!',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.navy,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: AppColors.green,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        border: Border.all(color: AppColors.green, width: 1.5),
                      ),
                      child: const Text(
                        'TRAVEL',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.blue, width: 1),
                    ),
                    child: const Text(
                      'LOCKED',
                      style: TextStyle(color: AppColors.blue, fontSize: 9),
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

class _MapGridLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.darkBlue.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapRoadsPainter extends CustomPainter {
  final List<MapNode> nodes;
  _MapRoadsPainter({required this.nodes});

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = AppColors.blue.withValues(alpha: 0.5)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.square;

    final pallet = nodes[0];
    final route1 = nodes[1];
    final forest = nodes[2];
    final mtMoon = nodes[3];

    // Dikey Hat: Pallet -> Route 1 -> Viridian Forest
    canvas.drawLine(
      Offset(pallet.x * size.width, pallet.y * size.height),
      Offset(forest.x * size.width, forest.y * size.height),
      roadPaint,
    );

    // Viridian Forest -> Mt. Moon (Önce sağa, sonra hafif yukarı)
    final cornerX = mtMoon.x * size.width;
    final cornerY = forest.y * size.height;

    canvas.drawLine(
      Offset(forest.x * size.width, forest.y * size.height),
      Offset(cornerX, cornerY),
      roadPaint,
    );
    canvas.drawLine(
      Offset(cornerX, cornerY),
      Offset(mtMoon.x * size.width, mtMoon.y * size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}