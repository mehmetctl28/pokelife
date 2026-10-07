class Region {
  final String id;
  final String name;
  final int unlockSteps;
  final List<int> dayEncounters;   // YENİ: Gündüz çıkacak Pokémon ID'leri
  final List<int> nightEncounters; // YENİ: Gece çıkacak Pokémon ID'leri

  const Region({
    required this.id,
    required this.name,
    required this.unlockSteps,
    required this.dayEncounters,
    required this.nightEncounters,
  });
}