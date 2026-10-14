import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';
import 'package:pokelife/core/widgets/pokemon_sprite.dart';
import 'package:pokelife/core/data/pokemon_data.dart';
import 'package:pokelife/core/data/evolution_data.dart';
import 'package:pokelife/core/models/caught_pokemon.dart';

class PokedexScreen extends StatefulWidget {
  const PokedexScreen({super.key});

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  String _selectedFilter = 'ALL';

  String _getPokemonNature(int id) {
    const natures = [
      'ADAMANT',
      'JOLLY',
      'TIMID',
      'BRAVE',
      'RELAXED',
      'MODEST',
      'HASTY',
    ];
    return natures[id % natures.length];
  }

  String _getEvolutionRequirement(int id) {
    final rules = EvolutionData.evolutions[id];
    if (rules != null && rules.isNotEmpty) {
      final reqLevel = rules.keys.first;
      final targetId = rules[reqLevel]!;
      final targetName = PokemonData.getName(targetId);
      return '$targetName (Lv. $reqLevel)';
    }
    return 'Final Form';
  }

  Widget _buildMemoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.blue,
            fontSize: 7,
            letterSpacing: 0.8,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.cream,
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showPokemonDetail(
    BuildContext context,
    int pokeId,
    CaughtPokemon? caughtData,
    bool isCaught,
    bool isPartner,
  ) {
    final trainer = context.read<TrainerProvider>();
    final pokeName = PokemonData.getName(pokeId);
    final pokeType = PokemonData.getType(pokeId);
    final nature = _getPokemonNature(pokeId);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.darkBlue,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: Border.all(
          color: isPartner ? AppColors.green : AppColors.cream,
          width: 2,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'No. ${pokeId.toString().padLeft(3, '0')}',
                    style: const TextStyle(
                      color: AppColors.yellow,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isPartner)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Text(
                        'ACTIVE PARTNER',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  border: Border.all(color: AppColors.blue, width: 1.5),
                ),
                child: Center(
                  child: PokemonSprite(pokemonId: pokeId, size: 72),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pokeName.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.cream,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                pokeType,
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (isCaught && caughtData != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    border: Border.all(color: AppColors.blue, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMemoItem(
                            'ORIGIN',
                            caughtData.caughtLocation ?? (pokeId == 1 ? 'Pallet Town' : 'Kanto Wild'),
                          ),
                          _buildMemoItem('NATURE', nature),
                        ],
                      ),
                      const Divider(color: AppColors.darkBlue, height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMemoItem(
                            'LEVEL',
                            'Lv. ${caughtData.level} (${caughtData.xp}/${caughtData.nextLevelXp} XP)',
                          ),
                          _buildMemoItem(
                            'WALKED',
                            '${caughtData.stepsWalked} steps',
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.darkBlue, height: 14),
                      Row(
                        children: [
                          const Text(
                            'PERK: ',
                            style: TextStyle(
                              color: AppColors.blue,
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              caughtData.activePerkDescription.replaceAll('★ ', ''),
                              style: const TextStyle(
                                color: AppColors.yellow,
                                fontSize: 7.5,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text(
                            'EVO:  ',
                            style: TextStyle(
                              color: AppColors.blue,
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _getEvolutionRequirement(pokeId),
                              style: const TextStyle(
                                color: AppColors.cream,
                                fontSize: 7.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    border: Border.all(color: AppColors.blue, width: 1),
                  ),
                  child: const Center(
                    child: Text(
                      'NOT YET CAUGHT\nExplore regions to encounter this Pokémon.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.blue, fontSize: 8, height: 1.4),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.blue, width: 1),
                      ),
                      child: const Text(
                        'CLOSE',
                        style: TextStyle(color: AppColors.cream, fontSize: 8),
                      ),
                    ),
                  ),
                  if (isCaught && !isPartner)
                    GestureDetector(
                      onTap: () {
                        trainer.setPartner(pokeId);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${pokeName.toUpperCase()} is now your partner!',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.navy,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: AppColors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          border: Border.all(color: AppColors.green, width: 1),
                        ),
                        child: const Text(
                          'SET AS PARTNER',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.green : AppColors.navy,
          border: Border.all(
            color: isSelected ? AppColors.green : AppColors.blue,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.navy : AppColors.cream,
              fontSize: 7.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trainer = context.watch<TrainerProvider>();
    final caughtIds = trainer.caughtPokemonIds;
    final caughtMap = trainer.caughtPokemons;
    final partnerId = trainer.partnerId;
    final activePartner = trainer.activePartner;

    List<int> displayedIds = List.generate(151, (index) => index + 1);

    if (_selectedFilter == 'CAUGHT') {
      displayedIds = displayedIds.where((id) => caughtIds.contains(id)).toList();
    } else if (_selectedFilter != 'ALL') {
      displayedIds = displayedIds.where((id) {
        final type = PokemonData.getType(id);
        return type.contains(_selectedFilter);
      }).toList();
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('POKÉDEX', style: TextStyle(color: AppColors.cream, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    border: Border.all(color: AppColors.blue, width: 1),
                  ),
                  child: Text(
                    '${caughtIds.length} / 151 CAUGHT',
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (activePartner != null)
            GestureDetector(
              onTap: () => _showPokemonDetail(
                context,
                partnerId,
                activePartner,
                true,
                true,
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkBlue,
                  border: Border.all(color: AppColors.green, width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        border: Border.all(color: AppColors.green, width: 1.5),
                      ),
                      child: Center(
                        child: PokemonSprite(pokemonId: partnerId, size: 42),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                PokemonData.getName(partnerId).toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.cream,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Text(
                                    i < activePartner.friendshipHearts ? '❤️' : '🤍',
                                    style: const TextStyle(fontSize: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.green,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  'Lv. ${activePartner.level}',
                                  style: const TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                PokemonData.getType(partnerId),
                                style: const TextStyle(
                                  color: AppColors.blue,
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            child: LinearProgressIndicator(
                              value: (activePartner.xp / activePartner.nextLevelXp).clamp(0.0, 1.0),
                              minHeight: 5,
                              backgroundColor: AppColors.navy,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 6),

          SizedBox(
            height: 28,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('ALL'),
                _buildFilterChip('CAUGHT'),
                _buildFilterChip('GRASS'),
                _buildFilterChip('FIRE'),
                _buildFilterChip('WATER'),
                _buildFilterChip('BUG'),
                _buildFilterChip('NORMAL'),
                _buildFilterChip('ELECTRIC'),
                _buildFilterChip('POISON'),
                _buildFilterChip('PSYCHIC'),
              ],
            ),
          ),
          const SizedBox(height: 6),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.68,
              ),
              itemCount: displayedIds.length,
              itemBuilder: (context, index) {
                final pokeId = displayedIds[index];
                final bool isCaught = caughtIds.contains(pokeId);
                final bool isPartner = (pokeId == partnerId);
                final caughtData = caughtMap[pokeId];

                return GestureDetector(
                  onTap: () => _showPokemonDetail(
                    context,
                    pokeId,
                    caughtData,
                    isCaught,
                    isPartner,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isPartner
                          ? AppColors.green.withValues(alpha: 0.15)
                          : (isCaught ? AppColors.darkBlue : AppColors.navy),
                      border: Border.all(
                        color: isPartner
                            ? AppColors.green
                            : (isCaught ? AppColors.blue : AppColors.navy),
                        width: isPartner ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '#${pokeId.toString().padLeft(3, '0')}',
                                style: TextStyle(
                                  color: isCaught ? AppColors.yellow : AppColors.blue,
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isCaught && caughtData != null)
                                Text(
                                  '❤️${caughtData.friendshipHearts}',
                                  style: const TextStyle(fontSize: 6.5),
                                ),
                            ],
                          ),
                        ),
                        ColorFiltered(
                          colorFilter: isCaught
                              ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                              : const ColorFilter.mode(AppColors.blue, BlendMode.srcIn),
                          child: Opacity(
                            opacity: isCaught ? 1.0 : 0.4,
                            child: PokemonSprite(
                              pokemonId: pokeId,
                              size: 40,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            isCaught ? PokemonData.getName(pokeId).toUpperCase() : '???',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isCaught ? AppColors.cream : AppColors.blue,
                              fontSize: 7.5,
                              fontWeight: isCaught ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isCaught && caughtData != null)
                          Text(
                            'Lv. ${caughtData.level}',
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 6.5,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          const Text(
                            'LOCKED',
                            style: TextStyle(color: AppColors.blue, fontSize: 6.5),
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
    );
  }
}