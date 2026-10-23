class BattleMove {
  final String name;
  final String type;
  final int power;
  final bool isFalseSwipe;
  final bool isHeal;
  final String description;

  const BattleMove({
    required this.name,
    required this.type,
    required this.power,
    this.isFalseSwipe = false,
    this.isHeal = false,
    required this.description,
  });
}

class AttackOutcome {
  final int damageDealt;
  final int remainingEnemyHp;
  final double typeMultiplier;
  final bool triggeredFalseSwipe;

  const AttackOutcome({
    required this.damageDealt,
    required this.remainingEnemyHp,
    required this.typeMultiplier,
    required this.triggeredFalseSwipe,
  });

  bool get isSuperEffective => typeMultiplier > 1.2;
  bool get isNotVeryEffective => typeMultiplier < 0.9;
  bool get isEnemyFainted => remainingEnemyHp <= 0;
}

class BattleEngine {
  static int calculatePlayerMaxHp(int partnerLevel) {
    final safeLevel = partnerLevel < 1 ? 1 : partnerLevel;
    return 45 + (safeLevel * 7);
  }

  static int calculateEnemyMaxHp(int wildLevel, {required bool isRare}) {
    final safeLevel = wildLevel < 1 ? 1 : wildLevel;
    return 35 + (safeLevel * 6) + (isRare ? 20 : 0);
  }

  static List<BattleMove> buildMovesForType(String type) {
    final upperType = type.toUpperCase();
    String specialName = 'ELEMENTAL BLAST';

    if (upperType.contains('GRASS')) {
      specialName = 'VINE WHIP';
    } else if (upperType.contains('FIRE')) {
      specialName = 'EMBER STRIKE';
    } else if (upperType.contains('WATER')) {
      specialName = 'WATER PULSE';
    } else if (upperType.contains('ELECTRIC')) {
      specialName = 'THUNDER SHOCK';
    } else if (upperType.contains('PSYCHIC')) {
      specialName = 'PSYBEAM';
    } else if (upperType.contains('ROCK') || upperType.contains('GROUND')) {
      specialName = 'ROCK SLIDE';
    } else if (upperType.contains('FLYING')) {
      specialName = 'WING ATTACK';
    } else if (upperType.contains('BUG')) {
      specialName = 'BUG BITE';
    } else if (upperType.contains('POISON')) {
      specialName = 'SLUDGE SHOT';
    }

    return [
      const BattleMove(
        name: 'QUICK ATTACK',
        type: 'NORMAL',
        power: 16,
        description: 'Reliable physical strike.',
      ),
      BattleMove(
        name: specialName,
        type: upperType.split('/').first.trim(),
        power: 24,
        description: 'Strong $type type move.',
      ),
      const BattleMove(
        name: 'FALSE SWIPE',
        type: 'NORMAL',
        power: 18,
        isFalseSwipe: true,
        description: 'Leaves foe with at least 1 HP.',
      ),
      const BattleMove(
        name: 'MORNING SUN',
        type: 'STATUS',
        power: 0,
        isHeal: true,
        description: 'Restores 35% of partner HP.',
      ),
    ];
  }

  static double getTypeMultiplier(String moveType, String defenderType) {
    final atk = moveType.toUpperCase().trim();
    final def = defenderType.toUpperCase();

    if (atk == 'GRASS' && (def.contains('WATER') || def.contains('ROCK') || def.contains('GROUND'))) {
      return 1.5;
    }
    if (atk == 'FIRE' && (def.contains('GRASS') || def.contains('BUG') || def.contains('ICE'))) {
      return 1.5;
    }
    if (atk == 'WATER' && (def.contains('FIRE') || def.contains('ROCK') || def.contains('GROUND'))) {
      return 1.5;
    }
    if (atk == 'ELECTRIC' && (def.contains('WATER') || def.contains('FLYING'))) {
      return 1.5;
    }
    if (atk == 'ROCK' && (def.contains('FIRE') || def.contains('FLYING') || def.contains('BUG'))) {
      return 1.5;
    }

    if (atk == 'GRASS' && (def.contains('FIRE') || def.contains('FLYING') || def.contains('BUG'))) {
      return 0.7;
    }
    if (atk == 'FIRE' && (def.contains('WATER') || def.contains('ROCK'))) {
      return 0.7;
    }
    if (atk == 'WATER' && def.contains('GRASS')) {
      return 0.7;
    }

    return 1.0;
  }

  /// Dinamik Yakalama Olasılığı (Her Gym Rozeti +%3 ek yakalama şansı sağlar)
  static double calculateCatchProbability({
    required int enemyHp,
    required int enemyMaxHp,
    required bool isRare,
    required bool razzBerryActive,
    required int partnerHearts,
    int badgeCount = 0,
  }) {
    if (enemyHp <= 1) return 1.0;

    final safeMaxHp = enemyMaxHp <= 0 ? 1 : enemyMaxHp;
    final double hpRatio = (enemyHp / safeMaxHp).clamp(0.0, 1.0);
    final double baseRate = isRare ? 0.22 : 0.38;
    final double hpBonus = (1.0 - hpRatio) * 0.65;
    final double berryBonus = razzBerryActive ? 0.20 : 0.0;
    final double heartBonus = partnerHearts.clamp(1, 5) * 0.03;
    final double badgeBonus = (badgeCount < 0 ? 0 : badgeCount) * 0.03;

    return (baseRate + hpBonus + berryBonus + heartBonus + badgeBonus).clamp(0.15, 0.98);
  }

  /// Oyuncu saldırısı (Her Gym Rozeti +%5 saldırı hasarı çarpanı verir)
  static AttackOutcome resolvePlayerAttack({
    required BattleMove move,
    required String defenderType,
    required int attackerLevel,
    required int defenderLevel,
    required int currentEnemyHp,
    required int maxEnemyHp,
    int badgeCount = 0,
    int randomBonus = 0,
  }) {
    final double typeMult = getTypeMultiplier(move.type, defenderType);
    final double levelFactor =
        1.0 + ((attackerLevel - defenderLevel) * 0.04).clamp(-0.3, 0.5);
    final double badgeMultiplier = 1.0 + ((badgeCount < 0 ? 0 : badgeCount) * 0.05);

    final int rawDamage =
        (move.power * typeMult * levelFactor * badgeMultiplier + randomBonus)
            .round()
            .clamp(4, 999);

    int newEnemyHp = currentEnemyHp - rawDamage;
    bool triggeredFalseSwipe = false;

    if (move.isFalseSwipe && newEnemyHp < 1) {
      newEnemyHp = 1;
      triggeredFalseSwipe = true;
    } else {
      newEnemyHp = newEnemyHp.clamp(0, maxEnemyHp);
    }

    return AttackOutcome(
      damageDealt: rawDamage,
      remainingEnemyHp: newEnemyHp,
      typeMultiplier: typeMult,
      triggeredFalseSwipe: triggeredFalseSwipe,
    );
  }

  static int calculateEnemyDamage({
    required int wildLevel,
    int randomBonus = 0,
  }) {
    return (10 + (wildLevel * 1.2) + randomBonus).round().clamp(5, 45);
  }

  static int calculateHealAmount(int maxHp, double ratio) {
    return (maxHp * ratio).round().clamp(1, maxHp);
  }

  static int calculateCatchXp({
    required bool isNew,
    required bool isRare,
    required int partnerHearts,
    required int enemyHp,
    required int enemyMaxHp,
  }) {
    final int baseXp = isNew ? (isRare ? 65 : 35) : 20;
    final int heartBonus = partnerHearts >= 4 ? 10 : 0;
    final int weakenBonus = enemyHp < (enemyMaxHp * 0.5) ? 10 : 0;
    return baseXp + heartBonus + weakenBonus;
  }

  static int calculateVictoryXp({
    required bool isRare,
    required int partnerHearts,
  }) {
    final int baseXp = isRare ? 40 : 20;
    final int heartBonus = partnerHearts >= 4 ? 5 : 0;
    return baseXp + heartBonus;
  }
}