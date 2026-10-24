import 'package:pokelife/core/data/pokemon_data.dart';

class EvolutionData {
  /// Kanto Pokémon Evrim Kuralları: { pokemonId: { requiredLevel: nextPokemonId } }
  static const Map<int, Map<int, int>> evolutions = {
    // Bulbasaur -> Ivysaur (16) -> Venusaur (32)
    1: {16: 2},
    2: {32: 3},

    // Charmander -> Charmeleon (16) -> Charizard (36)
    4: {16: 5},
    5: {36: 6},

    // Squirtle -> Wartortle (16) -> Blastoise (36)
    7: {16: 8},
    8: {36: 9},

    // Caterpie -> Metapod (7) -> Butterfree (10)
    10: {7: 11},
    11: {10: 12},

    // Weedle -> Kakuna (7) -> Beedrill (10)
    13: {7: 14},
    14: {10: 15},

    // Pidgey -> Pidgeotto (18) -> Pidgeot (36)
    16: {18: 17},
    17: {36: 18},

    // Rattata -> Raticate (20)
    19: {20: 20},

    // Spearow -> Fearow (20)
    21: {20: 22},

    // Ekans -> Arbok (22)
    23: {22: 24},

    // Pikachu -> Raichu (Seviye 28 Partner Bağı / Thunder Stone eşdeğeri)
    25: {28: 26},

    // Sandshrew -> Sandslash (22)
    27: {22: 28},

    // Nidoran♀ -> Nidorina (16) -> Nidoqueen (32)
    29: {16: 30},
    30: {32: 31},

    // Nidoran♂ -> Nidorino (16) -> Nidoking (32)
    32: {16: 33},
    33: {32: 34},

    // Zubat -> Golbat (22)
    41: {22: 42},

    // Oddish -> Gloom (21) -> Vileplume (32)
    43: {21: 44},
    44: {32: 45},

    // Diglett -> Dugtrio (26)
    50: {26: 51},

    // Meowth -> Persian (28)
    52: {28: 53},

    // Psyduck -> Golduck (33)
    54: {33: 55},

    // Mankey -> Primeape (28)
    56: {28: 57},

    // Growlithe -> Arcanine (30)
    58: {30: 59},

    // Poliwag -> Poliwhirl (25) -> Poliwrath (36)
    60: {25: 61},
    61: {36: 62},

    // Abra -> Kadabra (16) -> Alakazam (36)
    63: {16: 64},
    64: {36: 65},

    // Machop -> Machoke (28) -> Machamp (38)
    66: {28: 67},
    67: {38: 68},

    // Bellsprout -> Weepinbell (21) -> Victreebel (32)
    69: {21: 70},
    70: {32: 71},

    // Geodude -> Graveler (25) -> Golem (36)
    74: {25: 75},
    75: {36: 76},

    // Gastly -> Haunter (25) -> Gengar (38)
    92: {25: 93},
    93: {38: 94},

    // Magikarp -> Gyarados (20)
    129: {20: 130},

    // Dratini -> Dragonair (30) -> Dragonite (55)
    147: {30: 148},
    148: {55: 149},
  };

  /// Gerçekten son evrim aşamasında olan veya tek aşamalı efsanevi türler
  static const Set<int> finalFormIds = {
    3, 6, 9, 12, 15, 18, 20, 22, 24, 26, 28, 31, 34, 42, 45,
    51, 53, 55, 57, 59, 62, 65, 68, 71, 76, 94, 95, 130, 131,
    143, 144, 145, 146, 149, 150, 151,
  };

  /// Verilen Pokémon ID için bir sonraki evrim hedefini (seviye ve yeni ID) döndürür
  static MapEntry<int, int>? getNextEvolution(int pokemonId) {
    final rule = evolutions[pokemonId];
    if (rule == null || rule.isEmpty) return null;
    return rule.entries.first;
  }

  /// Pokédex detay penceresi için doğru ve dürüst evrim durumu açıklaması
  static String getEvolutionStatusText(int pokemonId, {int? currentLevel}) {
    final next = getNextEvolution(pokemonId);
    if (next != null) {
      final targetName = PokemonData.getName(next.value).toUpperCase();
      if (currentLevel != null && currentLevel >= next.key) {
        return 'READY TO EVOLVE ➔ $targetName (Lv.${next.key})';
      }
      return 'Evolves into $targetName at Lv.${next.key}';
    }

    if (finalFormIds.contains(pokemonId)) {
      return 'Final Form (Max Evolution Stage)';
    }

    return 'Evolution not available in MVP yet';
  }
}