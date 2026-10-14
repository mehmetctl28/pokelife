class EvolutionData {
  // Mantık: mevcut_pokemon_id : { gereken_level : evrimlesecegi_pokemon_id }
  static const Map<int, Map<int, int>> evolutions = {
    // Bulbasaur Ailesi
    1: {16: 2},   // Bulbasaur (1) -> Ivysaur (2)
    2: {36: 3},   // Ivysaur (2) -> Venusaur (3)
    
    // Charmander Ailesi
    4: {16: 5},   // Charmander (4) -> Charmeleon (5)
    5: {36: 6},   // Charmeleon (5) -> Charizard (6)
    
    // Squirtle Ailesi
    7: {16: 8},   // Squirtle (7) -> Wartortle (8)
    8: {36: 9},   // Wartortle (8) -> Blastoise (9)

    // Caterpie Ailesi 
    10: {7: 11},  // Caterpie (10) -> Metapod (11)
    11: {10: 12}, // Metapod (11) -> Butterfree (12)

    // Pidgey Ailesi 
    16: {9: 17},  // Pidgey (16) -> Pidgeotto (17)
    17: {18: 18}, // Pidgeotto (17) -> Pidgeot (18)
    
    // Rattata Ailesi 
    19: {20: 20}, // Rattata (19) -> Raticate (20)
    
    // Oddish Ailesi
    43: {21: 44}, // Oddish (43) -> Gloom (44)
    44: {22: 45}, // Gloom (44) -> Vileplume (45) - SON EVRİM
  };
}