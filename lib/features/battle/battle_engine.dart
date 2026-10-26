class BattleMove {
  final String name;
  final String type;
  final int power;
  final bool isFalseSwipe;
  final bool isHeal;
  final int? maxUses;
  final String description;

  const BattleMove({
    required this.name,
    required this.type,
    required this.power,
    this.isFalseSwipe = false,
    this.isHeal = false,
    this.maxUses,
    required this.description,
  });
}

class AttackOutcome {
  final int damageDealt;
  final int rawDamage;
  final int remainingEnemyHp;
  final double typeMultiplier;
  final bool triggeredFalseSwipe;

  const AttackOutcome({
    required this.damageDealt,
    required this.rawDamage,
    required this.remainingEnemyHp,
    required this.typeMultiplier,
    required this.triggeredFalseSwipe,
  });

  bool get isNoEffect => typeMultiplier == 0.0;
  bool get isSuperEffective => typeMultiplier > 1.2;
  bool get isNotVeryEffective => typeMultiplier > 0.0 && typeMultiplier < 0.9;
  bool get isEnemyFainted => remainingEnemyHp <= 0;
}

class BattleEngine {
  static int calculatePlayerMaxHp(int partnerLevel) {
    final int safeLevel = partnerLevel < 1 ? 1 : partnerLevel;
    return 45 + (safeLevel * 7);
  }

  static int calculateEnemyMaxHp(int wildLevel, {required bool isRare}) {
    final int safeLevel = wildLevel < 1 ? 1 : wildLevel;
    return 35 + (safeLevel * 6) + (isRare ? 20 : 0);
  }

  /// DÜZELTME (Madde 2.C & 2.F): Hamle adı ile hamle türü açıkça eşleştirilir,
  /// MORNING SUN hamlesi savaş başına 2 kullanımla (maxUses: 2) sınırlandırılır.
  static List<BattleMove> buildMovesForType(String type) {
    final String upperType = type.toUpperCase();
    String specialName = 'ELEMENTAL BLAST';
    String specialType = 'NORMAL';

    if (upperType.contains('GRASS')) {
      specialName = 'VINE WHIP';
      specialType = 'GRASS';
    } else if (upperType.contains('FIRE')) {
      specialName = 'EMBER STRIKE';
      specialType = 'FIRE';
    } else if (upperType.contains('WATER')) {
      specialName = 'WATER PULSE';
      specialType = 'WATER';
    } else if (upperType.contains('ELECTRIC')) {
      specialName = 'THUNDER SHOCK';
      specialType = 'ELECTRIC';
    } else if (upperType.contains('PSYCHIC')) {
      specialName = 'PSYBEAM';
      specialType = 'PSYCHIC';
    } else if (upperType.contains('ICE')) {
      specialName = 'ICE BEAM';
      specialType = 'ICE';
    } else if (upperType.contains('DRAGON')) {
      specialName = 'DRAGON RAGE';
      specialType = 'DRAGON';
    } else if (upperType.contains('GHOST')) {
      specialName = 'SHADOW BALL';
      specialType = 'GHOST';
    } else if (upperType.contains('FIGHTING')) {
      specialName = 'KARATE CHOP';
      specialType = 'FIGHTING';
    } else if (upperType.contains('ROCK')) {
      specialName = 'ROCK SLIDE';
      specialType = 'ROCK';
    } else if (upperType.contains('GROUND')) {
      specialName = 'EARTHQUAKE';
      specialType = 'GROUND';
    } else if (upperType.contains('FLYING')) {
      specialName = 'WING ATTACK';
      specialType = 'FLYING';
    } else if (upperType.contains('BUG')) {
      specialName = 'BUG BITE';
      specialType = 'BUG';
    } else if (upperType.contains('POISON')) {
      specialName = 'SLUDGE SHOT';
      specialType = 'POISON';
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
        type: specialType,
        power: 24,
        description: 'Strong $specialType type move.',
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
        maxUses: 2,
        description: 'Restores 35% HP (Max 2 uses).',
      ),
    ];
  }

  /// DÜZELTME (Madde 2.G): Gen 1 Bağışıklık (0.0x) ve genişletilmiş tür tablosu
  static double getTypeMultiplier(String moveType, String defenderType) {
    final String atk = moveType.toUpperCase().trim();
    final String def = defenderType.toUpperCase();

    // Bağışıklıklar (0.0x)
    if (atk == 'ELECTRIC' && def.contains('GROUND')) return 0.0;
    if (atk == 'GROUND' && def.contains('FLYING')) return 0.0;
    if (atk == 'NORMAL' && def.contains('GHOST')) return 0.0;
    if (atk == 'GHOST' && def.contains('NORMAL')) return 0.0;

    // Süper Etkili Eşleşmeler (1.5x)
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
    if (atk == 'ROCK' && (def.contains('FIRE') || def.contains('FLYING') || def.contains('BUG') || def.contains('ICE'))) {
      return 1.5;
    }
    if (atk == 'GROUND' && (def.contains('FIRE') || def.contains('ELECTRIC') || def.contains('ROCK') || def.contains('POISON'))) {
      return 1.5;
    }
    if (atk == 'FLYING' && (def.contains('GRASS') || def.contains('BUG') || def.contains('FIGHTING'))) {
      return 1.5;
    }
    if (atk == 'PSYCHIC' && (def.contains('FIGHTING') || def.contains('POISON'))) {
      return 1.5;
    }
    if (atk == 'ICE' && (def.contains('GRASS') || def.contains('GROUND') || def.contains('FLYING') || def.contains('DRAGON'))) {
      return 1.5;
    }
    if (atk == 'FIGHTING' && (def.contains('NORMAL') || def.contains('ROCK') || def.contains('ICE'))) {
      return 1.5;
    }
    if (atk == 'BUG' && (def.contains('GRASS') || def.contains('PSYCHIC'))) {
      return 1.5;
    }
    if (atk == 'GHOST' && (def.contains('PSYCHIC') || def.contains('GHOST'))) {
      return 1.5;
    }
    if (atk == 'POISON' && def.contains('GRASS')) {
      return 1.5;
    }
    if (atk == 'DRAGON' && def.contains('DRAGON')) {
      return 1.5;
    }

    // Az Etkili Eşleşmeler (0.7x)
    if (atk == 'GRASS' && (def.contains('FIRE') || def.contains('FLYING') || def.contains('BUG') || def.contains('POISON') || def.contains('DRAGON'))) {
      return 0.7;
    }
    if (atk == 'FIRE' && (def.contains('WATER') || def.contains('ROCK') || def.contains('FIRE') || def.contains('DRAGON'))) {
      return 0.7;
    }
    if (atk == 'WATER' && (def.contains('GRASS') || def.contains('WATER') || def.contains('DRAGON'))) {
      return 0.7;
    }
    if (atk == 'ELECTRIC' && (def.contains('GRASS') || def.contains('ELECTRIC') || def.contains('DRAGON'))) {
      return 0.7;
    }
    if (atk == 'FLYING' && (def.contains('ROCK') || def.contains('ELECTRIC'))) {
      return 0.7;
    }
    if (atk == 'ROCK' && (def.contains('FIGHTING') || def.contains('GROUND'))) {
      return 0.7;
    }

    return 1.0;
  }

  /// DÜZELTME (Madde 2.A): Tüm .clamp() çağrıları .toDouble() / .toInt() ile tip güvenli
  static double calculateCatchProbability({
    required int enemyHp,
    required int enemyMaxHp,
    required bool isRare,
    required bool razzBerryActive,
    required int partnerHearts,
    int badgeCount = 0,
  }) {
    if (enemyHp <= 1) return 1.0;

    final int safeMaxHp = enemyMaxHp <= 0 ? 1 : enemyMaxHp;
    final double hpRatio = (enemyHp / safeMaxHp).clamp(0.0, 1.0).toDouble();
    final double baseRate = isRare ? 0.22 : 0.38;
    final double hpBonus = (1.0 - hpRatio) * 0.65;
    final double berryBonus = razzBerryActive ? 0.20 : 0.0;
    final double heartBonus = partnerHearts.clamp(1, 5).toInt() * 0.03;
    final double badgeBonus = (badgeCount < 0 ? 0 : badgeCount) * 0.03;

    return (baseRate + hpBonus + berryBonus + heartBonus + badgeBonus)
        .clamp(0.15, 0.98)
        .toDouble();
  }

  /// DÜZELTME (Madde 2.A & 2.E): Gerçek düşen HP (actualDamage) hesaplanır
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

    if (typeMult == 0.0) {
      return AttackOutcome(
        damageDealt: 0,
        rawDamage: 0,
        remainingEnemyHp: currentEnemyHp,
        typeMultiplier: 0.0,
        triggeredFalseSwipe: false,
      );
    }

    final double levelDelta = ((attackerLevel - defenderLevel) * 0.04)
        .clamp(-0.3, 0.5)
        .toDouble();
    final double levelFactor = 1.0 + levelDelta;
    final double badgeMultiplier = 1.0 + ((badgeCount < 0 ? 0 : badgeCount) * 0.05);

    final int calculatedRawDamage =
        (move.power * typeMult * levelFactor * badgeMultiplier + randomBonus)
            .round()
            .clamp(4, 999)
            .toInt();

    int newEnemyHp = currentEnemyHp - calculatedRawDamage;
    bool triggeredFalseSwipe = false;

    if (move.isFalseSwipe && newEnemyHp < 1) {
      newEnemyHp = 1;
      triggeredFalseSwipe = true;
    } else {
      newEnemyHp = newEnemyHp.clamp(0, maxEnemyHp).toInt();
    }

    // DÜZELTME (Madde 2.E): Gösterilen hasar, düşmanın kaybettiği gerçek HP'yi aşamaz
    final int actualDamage = (currentEnemyHp - newEnemyHp).clamp(0, currentEnemyHp).toInt();

    return AttackOutcome(
      damageDealt: actualDamage,
      rawDamage: calculatedRawDamage,
      remainingEnemyHp: newEnemyHp,
      typeMultiplier: typeMult,
      triggeredFalseSwipe: triggeredFalseSwipe,
    );
  }

  static int calculateEnemyDamage({
    required int wildLevel,
    int randomBonus = 0,
  }) {
    return (10 + (wildLevel * 1.2) + randomBonus).round().clamp(5, 45).toInt();
  }

  static int calculateHealAmount(int maxHp, double ratio) {
    final int safeMax = maxHp < 1 ? 1 : maxHp;
    return (safeMax * ratio).round().clamp(1, safeMax).toInt();
  }

  /// Yakalama XP'sinin tek doğruluk kaynağı (Single Source of Truth)
  static int calculateCatchXp({
    required bool isNew,
    required bool isRare,
    required int partnerHearts,
    required int enemyHp,
    required int enemyMaxHp,
  }) {
    final int baseXp = isNew ? (isRare ? 65 : 35) : 20;
    final int heartBonus = partnerHearts >= 4 ? 10 : 0; // Lucky Find (+10 XP)
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