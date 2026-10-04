import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mevcut ve sağlam TrainerProvider'ımızı dinliyoruz
    final trainer = context.watch<TrainerProvider>();
  
    // Günlük geçmişini dinamik olarak Trainer verilerinden oluşturuyoruz
    final List<Map<String, dynamic>> journalEntries = [
      {
        'title': 'Günlük Adım Durumu',
        'desc': 'Bugün şu ana kadar ${trainer.dailySteps} adım atıldı.',
        'time': 'Bugün',
        'icon': '🚶',
        'color': AppColors.green,
      },
      {
        'title': 'Pokedex Kayıtları',
        'desc': 'Pokedex\'e kaydedilen benzersiz Pokémon sayısı: ${trainer.caughtPokemonIds.length}',
        'time': 'Devam Ediyor',
        'icon': '📖',
        'color': AppColors.blue,
      },
      {
        'title': 'Macera Başladı',
        'desc': 'PokéLife dünyasındaki yolculuğun resmen başladı.',
        'time': '1. Gün',
        'icon': '🌟',
        'color': AppColors.yellow,
      },
    ];

    // Eğer oyuncu en az 1 Pokémon yakaladıysa, en başa (en yeni kayıt olarak) bunu ekliyoruz
    if (trainer.caughtPokemonIds.isNotEmpty) {
      journalEntries.insert(0, {
        'title': 'Yeni Bir Keşif!',
        'desc': 'ID #${trainer.caughtPokemonIds.last} numaralı Pokémon başarıyla yakalandı!',
        'time': 'Yakın Zamanda',
        'icon': '✨',
        'color': AppColors.purple,
      });
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Başlık
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ADVENTURE LOG', style: TextStyle(color: AppColors.cream, fontSize: 14, letterSpacing: 1)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(2)),
                  child: const Text('GÜNCEL', style: TextStyle(color: AppColors.navy, fontSize: 7, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(color: AppColors.blue, thickness: 2, height: 16),
            const Text('Yolculuğunun, adımlarının ve keşiflerinin retro kayıtları.', style: TextStyle(color: AppColors.blue, fontSize: 8)),
            const SizedBox(height: 16),

            // Dinamik Günlük Listesi
            Expanded(
              child: ListView.builder(
                itemCount: journalEntries.length,
                itemBuilder: (context, index) {
                  final entry = journalEntries[index];
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.darkBlue,
                      border: Border.all(color: entry['color'] as Color, width: 2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry['icon'] as String, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry['title'] as String,
                                    style: TextStyle(color: entry['color'] as Color, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    entry['time'] as String,
                                    style: const TextStyle(color: AppColors.blue, fontSize: 7),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                entry['desc'] as String,
                                style: const TextStyle(color: AppColors.cream, fontSize: 9),
                              ),
                            ],
                          ),
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