import 'dart:math';

class Region {
  final String id;
  final String name;
  final int unlockSteps;
  final List<int> normalPokemonIds;
  final List<int> rarePokemonIds;
  final int minLevel;
  final int maxLevel;

  const Region({
    required this.id,
    required this.name,
    required this.unlockSteps,
    required this.normalPokemonIds,
    required this.rarePokemonIds,
    required this.minLevel,
    required this.maxLevel,
  });

  // Nadirlik durumuna göre bölge havuzundan rastgele Pokémon ID seçer
  int getRandomPokemonId({required bool isRare}) {
    final random = Random();
    if (isRare && rarePokemonIds.isNotEmpty) {
      return rarePokemonIds[random.nextInt(rarePokemonIds.length)];
    }
    if (normalPokemonIds.isNotEmpty) {
      return normalPokemonIds[random.nextInt(normalPokemonIds.length)];
    }
    return 1; // Fallback (Bulbasaur)
  }

  // Bölgenin seviye aralığına göre vahşi Pokémon seviyesi belirler
  int getWildLevel({required bool isRare}) {
    final random = Random();
    int baseLevel = minLevel + random.nextInt((maxLevel - minLevel) + 1);
    // Nadir karşılaşmalarda +2 ile +4 seviye bonusu
    if (isRare) {
      baseLevel += 2 + random.nextInt(3);
    }
    return baseLevel;
  }

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['id'] as String,
      name: json['name'] as String,
      unlockSteps: json['unlockSteps'] as int,
      normalPokemonIds: List<int>.from(json['normalPokemonIds'] ?? [1, 4, 7]),
      rarePokemonIds: List<int>.from(json['rarePokemonIds'] ?? [25]),
      minLevel: json['minLevel'] as int? ?? 3,
      maxLevel: json['maxLevel'] as int? ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'unlockSteps': unlockSteps,
      'normalPokemonIds': normalPokemonIds,
      'rarePokemonIds': rarePokemonIds,
      'minLevel': minLevel,
      'maxLevel': maxLevel,
    };
  }
}