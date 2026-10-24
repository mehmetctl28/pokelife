class CaughtPokemon {
  final int id;
  int level;
  int xp;
  int friendshipPoints; // 0 - 100 arası
  int stepsWalked;
  DateTime caughtAt;
  String? caughtLocation;

  CaughtPokemon({
    required this.id,
    this.level = 5,
    this.xp = 0,
    this.friendshipPoints = 20, // 1 kalp başlangıç
    this.stepsWalked = 0,
    required this.caughtAt,
    this.caughtLocation,
  });

  // 20 puanda bir 1 kalp (Maksimum 5) - .toInt() ile tip güvenliği sağlandı
  int get friendshipHearts => (friendshipPoints ~/ 20).clamp(1, 5).toInt();

  int get nextLevelXp => level * 100;

  void addXp(int amount) {
    double multiplier = 1.0;
    if (friendshipHearts >= 5) {
      multiplier = 1.25;
    } else if (friendshipHearts >= 1) {
      multiplier = 1.10;
    }

    int gainedXp = (amount * multiplier).round();
    xp += gainedXp;

    while (xp >= nextLevelXp) {
      xp -= nextLevelXp;
      level++;
    }
  }

  void addSteps(int steps) {
    int oldSteps = stepsWalked;
    stepsWalked += steps;

    // Her 2.000 adımda +1 Friendship Puanı
    int gainedPoints = (stepsWalked ~/ 2000) - (oldSteps ~/ 2000);
    if (gainedPoints > 0) {
      addFriendshipPoints(gainedPoints);
    }
  }

  void addFriendshipPoints(int points) {
    friendshipPoints = (friendshipPoints + points).clamp(0, 100).toInt();
  }

  String get activePerkDescription {
    switch (friendshipHearts) {
      case 5:
        return '★ BEST BUDDY: +25% Trainer & Partner XP (All Perks Active)';
      case 4:
        return '★ LUCKY FIND: +10 Catch XP & 4.5k Step Search';
      case 3:
        return '★ ENERGY SAVER: 4.5k Steps Search Cost & +15% Rare Chance';
      case 2:
        return '★ SCOUT BOND: +15% Rare Encounter Synergy';
      case 1:
      default:
        return '★ STARTER BOND: +10% Partner XP Gain';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'level': level,
      'xp': xp,
      'friendshipPoints': friendshipPoints,
      'stepsWalked': stepsWalked,
      'caughtAt': caughtAt.toIso8601String(),
      'caughtLocation': caughtLocation,
    };
  }

  factory CaughtPokemon.fromMap(Map<String, dynamic> map) {
    return CaughtPokemon(
      id: map['id'] as int,
      level: map['level'] as int? ?? 5,
      xp: map['xp'] as int? ?? 0,
      friendshipPoints: map['friendshipPoints'] as int? ??
          (((map['friendship'] as int? ?? 1) * 20).clamp(0, 100).toInt()),
      stepsWalked: map['stepsWalked'] as int? ?? 0,
      caughtAt: DateTime.tryParse(map['caughtAt'] as String? ?? '') ?? DateTime.now(),
      caughtLocation: map['caughtLocation'] as String?,
    );
  }
}