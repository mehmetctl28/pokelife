import 'package:pokelife/core/models/region.dart';

class WorldData {
  static final List<Region> regions = [
    const Region(
      id: 'route_1',
      name: 'Route 1',
      unlockSteps: 0,
      normalPokemonIds: [1, 4, 7, 10, 13, 16, 19], // Bulbasaur, Charmander, Squirtle, Caterpie, Weedle, Pidgey, Rattata vb.
      rarePokemonIds: [25, 35, 39], // Pikachu, Clefairy, Jigglypuff
      minLevel: 3,
      maxLevel: 7,
    ),
    const Region(
      id: 'viridian_forest',
      name: 'Viridian Forest',
      unlockSteps: 15000,
      normalPokemonIds: [10, 11, 13, 14, 16], // Caterpie, Metapod, Weedle, Kakuna, Pidgey
      rarePokemonIds: [12, 15, 25], // Butterfree, Beedrill, Pikachu
      minLevel: 6,
      maxLevel: 12,
    ),
    const Region(
      id: 'mt_moon',
      name: 'Mt. Moon',
      unlockSteps: 35000,
      normalPokemonIds: [41, 74, 35], // Zubat, Geodude, Clefairy
      rarePokemonIds: [95, 42, 66], // Onix, Golbat, Machop
      minLevel: 10,
      maxLevel: 18,
    ),
  ];

  /// Toplam adımlara göre kullanıcının unlocked (açık) olduğu en yüksek bölgeyi döndürür
  static Region getCurrentRegion(int steps) {
    Region unlockedRegion = regions.first;
    for (var region in regions) {
      if (steps >= region.unlockSteps) {
        unlockedRegion = region;
      }
    }
    return unlockedRegion;
  }

  /// ID'ye göre bölge bulur
  static Region getRegionById(String id) {
    return regions.firstWhere(
      (r) => r.id == id,
      orElse: () => regions.first,
    );
  }
}