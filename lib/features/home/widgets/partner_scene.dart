import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';
import 'package:pokelife/core/widgets/pokemon_sprite.dart';

class PartnerScene extends StatefulWidget {
  const PartnerScene({super.key});

  @override
  State<PartnerScene> createState() => _PartnerSceneState();
}

class _PartnerSceneState extends State<PartnerScene> {
  bool _isJumping = false;
  bool _showHeart = false;
  Timer? _timeUpdater;

  @override
  void initState() {
    super.initState();
    // Zamanlayıcı sadece bu küçük bileşeni günceller, tüm ekranı yormaz!
    _timeUpdater = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) setState(() {}); 
    });
  }

  @override
  void dispose() {
    _timeUpdater?.cancel();
    super.dispose();
  }

  void _interactWithPokemon() {
    if (_isJumping) return;
    setState(() {
      _isJumping = true;
      _showHeart = true;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isJumping = false);
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final trainer = context.watch<TrainerProvider>();
    final hour = DateTime.now().hour;
    final isNight = hour < 6 || hour > 18;
    final timeString = "${hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";
    
    final skyColor = isNight ? AppColors.navy : const Color(0xFF8BADD3);
    final groundColor = isNight ? const Color(0xFF2A5934) : const Color(0xFF52A55C);
    final skyIcon = isNight ? '🌙' : '☀️';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orangeAccent, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('🔥 ${trainer.streak} DAY STREAK', 
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)
              ),
            ),
            Text('$timeString $skyIcon', style: const TextStyle(color: AppColors.yellow, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _interactWithPokemon,
          child: Container(
            height: 280,
            decoration: BoxDecoration(color: skyColor, border: Border.all(color: AppColors.cream, width: 4)),
            child: Stack(
              children: [
                if (!isNight) ...[
                  const Positioned(top: 30, left: 20, child: Icon(Icons.cloud, color: Colors.white70, size: 30)),
                  const Positioned(top: 50, right: 40, child: Icon(Icons.cloud, color: Colors.white70, size: 20)),
                ] else ...[
                  const Positioned(top: 20, left: 30, child: Text('✦', style: TextStyle(color: Colors.white70, fontSize: 12))),
                  const Positioned(top: 50, right: 40, child: Text('·', style: TextStyle(color: Colors.white70, fontSize: 16))),
                  const Positioned(top: 70, left: 80, child: Text('✦', style: TextStyle(color: Colors.white70, fontSize: 10))),
                ],
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(height: 90, decoration: BoxDecoration(color: groundColor, border: const Border(top: BorderSide(color: AppColors.cream, width: 2)))),
                ),
                Positioned(bottom: 75, left: 20, child: Text('🌲', style: TextStyle(fontSize: 30, color: isNight ? Colors.black54 : null))),
                Positioned(bottom: 65, right: 25, child: Text('🌲', style: TextStyle(fontSize: 40, color: isNight ? Colors.black54 : null))),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  bottom: _isJumping ? 90 : 60,
                  left: 0, right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(opacity: _showHeart ? 1.0 : 0.0, child: const Text('❤️', style: TextStyle(fontSize: 18))),
                      const SizedBox(height: 4),
                      PokemonSprite(pokemonId: trainer.partnerId, size: 100),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 12, left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.darkBlue.withValues(alpha: 0.8), border: Border.all(color: AppColors.cream, width: 1), borderRadius: BorderRadius.circular(4)),
                      child: Text('PARTNER  Lv. ${trainer.level}', style: const TextStyle(color: AppColors.cream, fontSize: 9)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}