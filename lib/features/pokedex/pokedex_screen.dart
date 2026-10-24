import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';
import 'package:pokelife/core/data/pokemon_data.dart';
import 'package:pokelife/core/data/evolution_data.dart';
import 'package:pokelife/core/models/caught_pokemon.dart';
import 'package:pokelife/core/widgets/pokemon_sprite.dart';

class PokedexScreen extends StatefulWidget {
  const PokedexScreen({super.key});

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  String _selectedFilter = 'ALL';

  static const List<String> _filters = [
    'ALL',
    'CAUGHT',
    'GRASS',
    'FIRE',
    'WATER',
    'ELECTRIC',
    'BUG',
    'NORMAL',
    'FLYING',
    'POISON',
    'ROCK',
    'GROUND',
    'FIGHTING',
    'PSYCHIC',
    'GHOST',
    'ICE',
    'DRAGON',
  ];

  List<int> _getFilteredPokemonIds(TrainerProvider trainer) {
    final allIds = List<int>.generate(151, (i) => i + 1);
    final caughtSet = trainer.caughtPokemonIds.toSet();

    if (_selectedFilter == 'ALL') return allIds;
    if (_selectedFilter == 'CAUGHT') {
      return allIds.where((id) => caughtSet.contains(id)).toList();
    }

    return allIds.where((id) {
      final type = PokemonData.getType(id).toUpperCase();
      return type.contains(_selectedFilter);
    }).toList();
  }

  String _getFieldNote(CaughtPokemon caught) {
    if (caught.friendshipHearts >= 5) {
      return 'Unbreakable bond! Walks happily right beside you.';
    } else if (caught.stepsWalked >= 5000) {
      return 'Seasoned trail companion with strong endurance.';
    } else if (caught.level >= 15) {
      return 'Battle-hardened and eager to test its strength.';
    }
    return 'Recently registered. Walk together to build trust!';
  }

  void _showPokemonDetails(BuildContext context, int pokemonId) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Consumer<TrainerProvider>(
          builder: (ctx, trainer, _) {
            final CaughtPokemon? caughtData = trainer.caughtPokemons[pokemonId];
            final bool isCaught = caughtData != null;

            // DÜZELTME (Madde 9.1): Yakalanmamış Pokémonların bilgileri gizlenir!
            if (!isCaught) {
              return Dialog(
                backgroundColor: AppColors.darkBlue,
                shape: Border.all(color: AppColors.blue, width: 2),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#${pokemonId.toString().padLeft(3, '0')} • ???',
                        style: const TextStyle(
                          color: AppColors.yellow,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          border: Border.all(color: AppColors.blue, width: 2),
                        ),
                        child: const Center(
                          child: Text(
                            '?',
                            style: TextStyle(
                              color: AppColors.blue,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'UNIDENTIFIED SPECIES',
                        style: TextStyle(
                          color: AppColors.cream,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        ' Type: UNKNOWN\nHabitat: Explore Kanto regions and battle wild Pokémon to unlock this Pokédex entry.',
                        style: TextStyle(color: AppColors.blue, fontSize: 8, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => Navigator.pop(dialogCtx),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            border: Border.all(color: AppColors.cream, width: 1.5),
                          ),
                          child: const Center(
                            child: Text(
                              'CLOSE',
                              style: TextStyle(color: AppColors.cream, fontSize: 8.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // YAKALANMIŞ POKÉMON DETAY PENCERESİ
            final String name = PokemonData.getName(pokemonId).toUpperCase();
            final String type = PokemonData.getType(pokemonId).toUpperCase();
            final bool isCurrentPartner = trainer.partnerId == pokemonId;

            final nextEvo = EvolutionData.getNextEvolution(pokemonId);
            final bool canEvolveThisPokemon =
                nextEvo != null && caughtData.level >= nextEvo.key;
            final String? targetEvoName =
                nextEvo != null ? PokemonData.getName(nextEvo.value).toUpperCase() : null;

            final double xpRatio = (caughtData.xp / caughtData.nextLevelXp)
                .clamp(0.0, 1.0)
                .toDouble();

            return Dialog(
              backgroundColor: AppColors.darkBlue,
              shape: Border.all(
                color: canEvolveThisPokemon ? AppColors.yellow : AppColors.cream,
                width: 2.5,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '#${pokemonId.toString().padLeft(3, '0')} $name',
                            style: const TextStyle(
                              color: AppColors.yellow,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            border: Border.all(color: AppColors.green, width: 1),
                          ),
                          child: Text(
                            'Lv.${caughtData.level}',
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Sprite ve Temel Bilgiler
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            border: Border.all(
                              color: isCurrentPartner ? AppColors.green : AppColors.blue,
                              width: 2,
                            ),
                          ),
                          child: PokemonSprite(pokemonId: pokemonId, size: 76),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TYPE: $type',
                                style: const TextStyle(
                                  color: AppColors.cream,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'BOND: ${"❤️" * caughtData.friendshipHearts} (${caughtData.friendshipPoints}/100)',
                                style: const TextStyle(color: AppColors.yellow, fontSize: 7.5),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'STEPS WALKED: ${caughtData.stepsWalked}',
                                style: const TextStyle(color: AppColors.green, fontSize: 7.5),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'MET AT: ${(caughtData.caughtLocation ?? "Kanto Starter").toUpperCase()}',
                                style: const TextStyle(color: AppColors.blue, fontSize: 7),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Partner XP İlerleme Çubuğu (.toDouble() ile tip güvenli)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PARTNER XP',
                          style: TextStyle(color: AppColors.yellow, fontSize: 7.5),
                        ),
                        Text(
                          '${caughtData.xp} / ${caughtData.nextLevelXp} XP',
                          style: const TextStyle(color: AppColors.cream, fontSize: 7.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: xpRatio,
                      minHeight: 8,
                      backgroundColor: AppColors.navy,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
                    ),
                    const SizedBox(height: 12),

                    // Aktif Arkadaşlık Perk Bilgisi
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        border: Border.all(color: AppColors.blue, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            caughtData.activePerkDescription,
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getFieldNote(caughtData),
                            style: const TextStyle(color: AppColors.cream, fontSize: 7),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Evrim Durumu Kutusu
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        border: Border.all(
                          color: canEvolveThisPokemon ? AppColors.yellow : AppColors.blue,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        EvolutionData.getEvolutionStatusText(
                          pokemonId,
                          currentLevel: caughtData.level,
                        ),
                        style: TextStyle(
                          color: canEvolveThisPokemon ? AppColors.yellow : AppColors.cream,
                          fontSize: 7.5,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // DÜZELTME (Madde 4): KULLANILABİLİR EVRİM BUTONU!
                    if (canEvolveThisPokemon) ...[
                      GestureDetector(
                        onTap: () {
                          if (!isCurrentPartner) {
                            trainer.setPartner(pokemonId);
                          }
                          final bool success = trainer.triggerManualEvolution();
                          if (success) {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '✨ CONGRATULATIONS! Your $name evolved into $targetEvoName!',
                                  style: const TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: AppColors.yellow,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.yellow,
                            border: Border.all(color: AppColors.cream, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '✨ EVOLVE INTO $targetEvoName ✨',
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Partner Seçme ve Kapatma Butonları
                    Row(
                      children: [
                        if (!isCurrentPartner) ...[
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                trainer.setPartner(pokemonId);
                                Navigator.pop(dialogCtx);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.navy,
                                  border: Border.all(color: AppColors.green, width: 1.5),
                                ),
                                child: const Center(
                                  child: Text(
                                    'SET AS PARTNER',
                                    style: TextStyle(
                                      color: AppColors.green,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(dialogCtx),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.navy,
                                border: Border.all(color: AppColors.cream, width: 1.5),
                              ),
                              child: const Center(
                                child: Text(
                                  'CLOSE',
                                  style: TextStyle(color: AppColors.cream, fontSize: 8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final trainer = context.watch<TrainerProvider>();
    final caughtIds = trainer.caughtPokemonIds;
    final filteredIds = _getFilteredPokemonIds(trainer);

    // DÜZELTME (Madde 1): İlerleme çubuğuna .toDouble() ile kesin double verilir
    final double completionRatio = (caughtIds.length / 151.0).clamp(0.0, 1.0).toDouble();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık ve Tamamlanma Oranı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'KANTO POKÉDEX',
                  style: TextStyle(
                    color: AppColors.yellow,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'CAUGHT: ${caughtIds.length} / 151',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: completionRatio,
              minHeight: 8,
              backgroundColor: AppColors.darkBlue,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
            ),
            const SizedBox(height: 12),

            // Eğer aktif partner evrimleşmeye hazırsa hızlı bildirim bandı!
            if (trainer.canEvolvePartner && trainer.activePartner != null)
              GestureDetector(
                onTap: () => _showPokemonDetails(context, trainer.partnerId),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    border: Border.all(color: AppColors.yellow, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '✨ ${PokemonData.getName(trainer.partnerId).toUpperCase()} IS READY TO EVOLVE!',
                          style: const TextStyle(
                            color: AppColors.yellow,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Text(
                        'TAP HERE ▶',
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 7.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Genişletilmiş Kanto Tür Filtreleri
            SizedBox(
              height: 30,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.yellow : AppColors.darkBlue,
                        border: Border.all(
                          color: isSelected ? AppColors.cream : AppColors.blue,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected ? AppColors.navy : AppColors.cream,
                            fontSize: 7.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Pokémon Izgarası (Grid)
            Expanded(
              child: filteredIds.isEmpty
                  ? const Center(
                      child: Text(
                        'NO POKÉMON MATCH THIS FILTER YET.',
                        style: TextStyle(color: AppColors.blue, fontSize: 8.5),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: filteredIds.length,
                      itemBuilder: (context, index) {
                        final id = filteredIds[index];
                        final caughtData = trainer.caughtPokemons[id];
                        final isCaught = caughtData != null;
                        final isPartner = trainer.partnerId == id;

                        final nextEvo = EvolutionData.getNextEvolution(id);
                        final bool isReadyToEvolve =
                            isCaught && nextEvo != null && caughtData.level >= nextEvo.key;

                        return GestureDetector(
                          onTap: () => _showPokemonDetails(context, id),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isCaught ? AppColors.darkBlue : AppColors.navy,
                              border: Border.all(
                                color: isReadyToEvolve
                                    ? AppColors.yellow
                                    : (isPartner
                                        ? AppColors.green
                                        : (isCaught ? AppColors.cream : AppColors.blue)),
                                width: isPartner || isReadyToEvolve ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '#${id.toString().padLeft(3, '0')}',
                                      style: TextStyle(
                                        color: isCaught ? AppColors.yellow : AppColors.blue,
                                        fontSize: 7,
                                      ),
                                    ),
                                    if (isReadyToEvolve)
                                      const Text('✨', style: TextStyle(fontSize: 9))
                                    else if (isPartner)
                                      const Text(
                                        '★',
                                        style: TextStyle(color: AppColors.green, fontSize: 9),
                                      ),
                                  ],
                                ),
                                Expanded(
                                  child: Center(
                                    child: isCaught
                                        ? PokemonSprite(pokemonId: id, size: 50)
                                        : const Text(
                                            '?',
                                            style: TextStyle(
                                              color: AppColors.blue,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                Text(
                                  isCaught ? PokemonData.getName(id).toUpperCase() : '???',
                                  style: TextStyle(
                                    color: isCaught ? AppColors.cream : AppColors.blue,
                                    fontSize: 7.5,
                                    fontWeight: isCaught ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (isCaught)
                                  Text(
                                    'Lv.${caughtData.level}',
                                    style: const TextStyle(color: AppColors.green, fontSize: 6.5),
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
}