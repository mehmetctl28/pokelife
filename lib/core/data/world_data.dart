import '../models/region.dart';
import '../constants/game_constants.dart'; // YENİ: Sabitleri içeri aktar

class WorldData {
  static const List<Region> regions = [
    Region(
      id: 'route_1',
      name: 'Route 1',
      unlockSteps: GameConstants.regionRoute1Steps, // Sabit kullanıldı
      dayEncounters: [16, 19, 43], 
      nightEncounters: [19, 41, 163], 
    ),
    Region(
      id: 'viridian_forest',
      name: 'Viridian Forest',
      unlockSteps: GameConstants.regionViridianForestSteps, // Sabit kullanıldı
      dayEncounters: [10, 13, 25], 
      nightEncounters: [10, 13, 46], 
    ),
    Region(
      id: 'mt_moon',
      name: 'Mt. Moon',
      unlockSteps: GameConstants.regionMtMoonSteps, // Sabit kullanıldı
      dayEncounters: [35, 74, 27], 
      nightEncounters: [41, 74, 27], 
    ),
  ];

  static Region getCurrentRegion(int steps) {
    Region current = regions.first;
    for (var r in regions) {
      if (steps >= r.unlockSteps) {
        current = r;
      }
    }
    return current;
  }

  static int getRandomEncounter(int steps) {
    final region = getCurrentRegion(steps);
    final hour = DateTime.now().hour;
    final isNight = hour < 6 || hour > 18;
    
    final pool = isNight ? region.nightEncounters : region.dayEncounters;
    return pool[DateTime.now().millisecond % pool.length];
  }
}