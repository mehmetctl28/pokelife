import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';

class PokedexScreen extends StatelessWidget {
  const PokedexScreen({super.key});

  static const Map<int, String> pokemonNames = {
    1: 'BULBASAUR', 2: 'IVYSAUR', 3: 'VENUSAUR', 4: 'CHARMANDER', 5: 'CHARMELEON', 6: 'CHARIZARD',
    7: 'SQUIRTLE', 8: 'WARTORTLE', 9: 'BLASTOISE', 10: 'CATERPIE', 16: 'PIDGEY', 25: 'PIKACHU',
    35: 'CLEFAIRY', 41: 'ZUBAT', 43: 'ODDISH', 54: 'PSYDUCK', 60: 'POLIWAG', 69: 'BELLSPROUT',
    74: 'GEODUDE', 92: 'GASTLY', 95: 'ONIX', 118: 'GOLDEEN', 131: 'LAPRAS', 133: 'EEVEE',
    143: 'SNORLAX', 147: 'DRATINI', 149: 'DRAGONITE', 151: 'MEW'
  };

  @override
  Widget build(BuildContext context) {
    final trainer = context.watch<TrainerProvider>();
    final caughtIds = trainer.caughtPokemonIds;
    
    // Partner Pokémon (Şimdilik ilk yakalanan veya Bulbasaur)
    final partnerId = caughtIds.isNotEmpty ? caughtIds.first : 1;
    final partnerName = pokemonNames[partnerId] ?? 'UNKNOWN';

    // Friendship = Seri (Streak) sayısına göre maksimum 5 kalp
    final int friendship = (trainer.streak).clamp(0, 5);
    String hearts = '♥️' * friendship + '♡' * (5 - friendship);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        // Ekran taşmasını engellemek için ana yapıyı Column yapıp, alt kısmı Expanded ile sarıyoruz
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DSi Tarzı Üst Başlık
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

            // 🐾 MY TEAM / PARTNER KARTI (Nintendo Çift Ekran Üst Kısım Hissiyatı)
            Container(
              decoration: BoxDecoration(
                color: AppColors.darkBlue,
                border: Border.all(color: AppColors.cream, width: 2),
                boxShadow: [BoxShadow(color: AppColors.blue.withOpacity(0.2), offset: const Offset(4, 4))]
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
                        // Sol Taraf: Sprite
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            border: Border.all(color: AppColors.blue, width: 2),
                          ),
                          child: Image.network(
                            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iv/diamond-pearl/$partnerId.png',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.none,
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Sağ Taraf: İstatistikler
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
                              
                              // XP Barı
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
                  // Aksiyon Butonları
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

            // Alt Ekran: COLLECTION BAŞLIĞI
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('COLLECTION', style: TextStyle(color: AppColors.cream, fontSize: 14, letterSpacing: 1)),
                Text('${caughtIds.length} / 151', style: const TextStyle(color: AppColors.yellow, fontSize: 10)),
              ],
            ),
            const Divider(color: AppColors.blue, thickness: 2, height: 16),

            // 🎒 COLLECTION LİSTESİ (Taşmayı önlemek için Expanded ve GridView)
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // Yan yana 3 tane
                  childAspectRatio: 2.5, // Kutu oranı (geniş ve kısa)
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                // 1'den 151'e kadar tüm Pokémon'ları listele
                itemCount: 151,
                itemBuilder: (context, index) {
                  final int pokeId = index + 1;
                  final bool isCaught = caughtIds.contains(pokeId);
                  
                  return GestureDetector(
                    onTap: () {
                      if (isCaught) _showPokeDetails(context, pokeId, pokemonNames[pokeId] ?? 'UNKNOWN');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkBlue,
                        border: Border.all(color: isCaught ? AppColors.green : AppColors.navy, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            pokeId.toString().padLeft(3, '0'),
                            style: TextStyle(color: isCaught ? AppColors.cream : AppColors.blue, fontSize: 10),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isCaught ? Icons.check : Icons.question_mark,
                            color: isCaught ? AppColors.green : AppColors.navy,
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

  // Tıklanınca açılan detay popup'ı
  void _showPokeDetails(BuildContext context, int pokeId, String name) {
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
                child: Image.network(
                  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iv/diamond-pearl/$pokeId.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
              ),
              const SizedBox(height: 16),
              Text(name, style: const TextStyle(color: AppColors.cream, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Type: NORMAL / ENCOUNTER: WILD', style: TextStyle(color: AppColors.blue, fontSize: 8)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.green, width: 2)),
                  child: const Text('CLOSE', style: TextStyle(color: AppColors.green, fontSize: 10)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}