import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';
import 'package:pokelife/core/widgets/pokemon_sprite.dart';

class PokedexScreen extends StatelessWidget {
  const PokedexScreen({super.key});

  String _getPokeType(int id) {
    if ([1, 2, 3, 43, 69].contains(id)) return 'GRASS / POISON';
    if ([4, 5, 6].contains(id)) return 'FIRE';
    if ([7, 8, 9, 54, 60, 118, 131].contains(id)) return 'WATER';
    if ([25].contains(id)) return 'ELECTRIC';
    if ([74, 95].contains(id)) return 'ROCK / GROUND';
    if ([147, 149].contains(id)) return 'DRAGON';
    if ([92].contains(id)) return 'GHOST / POISON';
    return 'NORMAL'; 
  }

  String _getPokemonName(int id) => 'Pokemon #$id';

  @override
  Widget build(BuildContext context) {
    final trainer = context.watch<TrainerProvider>();
    final caughtIds = trainer.caughtPokemonIds;
    
    final partnerId = trainer.partnerId;
    
    final partnerName = _getPokemonName(partnerId);

    final int friendship = (trainer.streak).clamp(0, 5);
    String hearts = '♥️' * friendship + '♡' * (5 - friendship);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SYSTEM_DEX_OS_V1', style: TextStyle(color: AppColors.blue, fontSize: 8)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(2)),
                  child: const Text('ONLINE', style: TextStyle(color: AppColors.navy, fontSize: 7, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: AppColors.darkBlue,
                border: Border.all(color: AppColors.cream, width: 2),
                boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: 0.2), offset: const Offset(4, 4))]
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: AppColors.navy,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: const Text('MY PARTNER', textAlign: TextAlign.center, style: TextStyle(color: AppColors.yellow, fontSize: 10, letterSpacing: 2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            border: Border.all(color: AppColors.blue, width: 2),
                          ),
                          child: PokemonSprite(pokemonId: partnerId, size: 80),
                        ),
                        const SizedBox(width: 16),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(partnerName, style: const TextStyle(color: AppColors.cream, fontSize: 14, fontWeight: FontWeight.bold)),
                                  Text('Lv. ${trainer.level}', style: const TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              Container(
                                height: 8,
                                decoration: BoxDecoration(border: Border.all(color: AppColors.blue, width: 1)),
                                child: LinearProgressIndicator(
                                  value: trainer.currentLevelXp / trainer.nextLevelXp,
                                  backgroundColor: AppColors.navy,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              Text('Friendship: $hearts', style: const TextStyle(color: AppColors.cream, fontSize: 9)),
                              const SizedBox(height: 4),
                              Text('Total Steps: ${trainer.steps}', style: const TextStyle(color: AppColors.blue, fontSize: 8)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.navy, width: 2))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton('INFO'),
                        _buildActionButton('EVOLVE (Locked)'),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('COLLECTION', style: TextStyle(color: AppColors.cream, fontSize: 14, letterSpacing: 1)),
                Text('${caughtIds.length} / 151', style: const TextStyle(color: AppColors.yellow, fontSize: 10)),
              ],
            ),
            const Divider(color: AppColors.blue, thickness: 2, height: 16),

            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, 
                  childAspectRatio: 2.5, 
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 151,
                itemBuilder: (context, index) {
                  final int pokeId = index + 1;
                  final bool isCaught = caughtIds.contains(pokeId);
                  final bool isPartner = (pokeId == partnerId);
                  
                  return GestureDetector(
                    onTap: () {
                      if (isCaught) {
                        _showPokeDetails(context, pokeId, _getPokemonName(pokeId), isPartner);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isPartner ? AppColors.navy : AppColors.darkBlue,
                        border: Border.all(color: isPartner ? AppColors.yellow : (isCaught ? AppColors.green : AppColors.navy), width: isPartner ? 2 : 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            pokeId.toString().padLeft(3, '0'),
                            style: TextStyle(color: isPartner ? AppColors.yellow : (isCaught ? AppColors.cream : AppColors.blue), fontSize: 10, fontWeight: isPartner ? FontWeight.bold : FontWeight.normal),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isCaught ? (isPartner ? Icons.star : Icons.check) : Icons.question_mark,
                            color: isPartner ? AppColors.yellow : (isCaught ? AppColors.green : AppColors.navy),
                            size: 12,
                          ),
                        ],
                      ),
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

  Widget _buildActionButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(border: Border.all(color: AppColors.blue, width: 1)),
      child: Text(label, style: const TextStyle(color: AppColors.blue, fontSize: 8)),
    );
  }

  void _showPokeDetails(BuildContext context, int pokeId, String name, bool isPartner) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.darkBlue,
        shape: Border.all(color: AppColors.cream, width: 2),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('DEX DATA: #$pokeId', style: const TextStyle(color: AppColors.yellow, fontSize: 10)),
              const SizedBox(height: 16),
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(color: AppColors.navy, border: Border.all(color: AppColors.cream, width: 2)),
                child: PokemonSprite(pokemonId: pokeId, size: 100),
              ),
              const SizedBox(height: 16),
              Text(name, style: const TextStyle(color: AppColors.cream, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              Text('Type: ${_getPokeType(pokeId)} / STATUS: ${isPartner ? "PARTNER" : "IN BOX"}', style: const TextStyle(color: AppColors.blue, fontSize: 8)),
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.cream, width: 1)),
                      child: const Text('CLOSE', style: TextStyle(color: AppColors.cream, fontSize: 10)),
                    ),
                  ),
                  
                  if (!isPartner)
                    GestureDetector(
                      onTap: () {
                        context.read<TrainerProvider>().setPartner(pokeId);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(color: AppColors.green, border: Border.all(color: AppColors.green, width: 1)),
                        child: const Text('SET PARTNER', style: TextStyle(color: AppColors.navy, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}