class EvolutionData {
  // Mantık: mevcut_pokemon_id : { gereken_level : evrimlesecegi_pokemon_id }
  static const Map<int, Map<int, int>> evolutions = {
    // Bulbasaur Ailesi
    1: {16: 2},   // Bulbasaur (1), Level 16'da Ivysaur (2) olur
    2: {36: 3},   // Ivysaur (2), Level 36'da Venusaur (3) olur
    
    // Charmander Ailesi
    4: {16: 5},   // Charmander (4) -> Charmeleon (5)
    5: {36: 6},   // Charmeleon (5) -> Charizard (6)
    
    // Squirtle Ailesi
    7: {16: 8},   // Squirtle (7) -> Wartortle (8)
    8: {36: 9},   // Wartortle (8) -> Blastoise (9)

    // Caterpie Ailesi (Erken evrim örneği)
    10: {7: 11},  // Caterpie (10) -> Metapod (11)
    11: {10: 12}, // Metapod (11) -> Butter

    // Pidgey Ailesi (Erken evrim örneği)
    16: {9: 17},  // Pidgey (16) -> Pidgeotto (17)
    17: {18: 18}, // Pidgeotto (17) -> Pidgeot (18)
    // Rattata Ailesi (Erken evrim örneği)
    19: {20: 20}, // Rattata (19) -> Raticate (20)
    // Ekstra: Oddish Ailesi
    43: {21: 44}, // Oddish (43) -> Gloom
    44: {22: 45}, // Gloom (44) -> Vileplume
    45: {23: 46}, // Vileplume (45) -> Bellossom
  };
}