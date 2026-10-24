import 'package:pokelife/core/constants/game_constants.dart';
import 'package:pokelife/core/models/region.dart';

class WorldData {
  static final List<Region> regions = [
    Region(
      id: 'route_1',
      name: 'Route 1',
      unlockSteps: GameConstants.route1UnlockSteps,
      minLevel: 2,
      maxLevel: 5,
      normalPokemonIds: const [16, 19, 10, 13], // Pidgey, Rattata, Caterpie, Weedle
      rarePokemonIds: const [25, 1, 4, 7], // Pikachu, Bulbasaur, Charmander, Squirtle
    ),
    Region(
      id: 'viridian_forest',
      name: 'Viridian Forest',
      unlockSteps: GameConstants.viridianForestUnlockSteps,
      minLevel: 6,
      maxLevel: 12,
      normalPokemonIds: const [10, 11, 13, 14, 16, 43], // Caterpie, Metapod, Weedle, Kakuna, Pidgey, Oddish
      rarePokemonIds: const [25, 12, 15, 17], // Pikachu, Butterfree, Beedrill, Pidgeotto
    ),
    Region(
      id: 'mt_moon',
      name: 'Mt. Moon',
      unlockSteps: GameConstants.mtMoonUnlockSteps,
      minLevel: 12,
      maxLevel: 18,
      normalPokemonIds: const [41, 74, 27, 50], // Zubat, Geodude, Sandshrew, Diglett
      rarePokemonIds: const [35, 95, 42, 63], // Clefairy, Onix, Golbat, Abra
    ),
    Region(
      id: 'cerulean_city',
      name: 'Cerulean Cape',
      unlockSteps: GameConstants.ceruleanCityUnlockSteps,
      minLevel: 18,
      maxLevel: 25,
      normalPokemonIds: const [60, 69, 54, 120, 129], // Poliwag, Bellsprout, Psyduck, Staryu, Magikarp
      rarePokemonIds: const [121, 130, 58, 147], // Starmie, Gyarados, Growlithe, Dratini
    ),
  ];

  /// Adım sayısına göre açılmış en ileri bölgeyi döndürür
  static Region getCurrentRegion(int totalSteps) {
    final unlocked = regions.where((r) => totalSteps >= r.unlockSteps).toList();
    if (unlocked.isEmpty) return regions.first;
    return unlocked.last;
  }

  /// ID'ye göre bölge döndürür
  static Region getRegionById(String id) {
    return regions.firstWhere((r) => r.id == id, orElse: () => regions.first);
  }

  /// Kullanıcının seçtiği bölge açıksa onu, değilse açılmış en son bölgeyi döndürür
  static Region resolveActiveRegion(int totalSteps, String selectedRegionId) {
    final unlocked = regions.where((r) => totalSteps >= r.unlockSteps).toList();
    if (unlocked.isEmpty) return regions.first;
    return unlocked.firstWhere(
      (r) => r.id == selectedRegionId,
      orElse: () => unlocked.last,
    );
  }
}