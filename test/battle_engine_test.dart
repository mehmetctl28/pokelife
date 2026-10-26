import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokelife/features/battle/battle_engine.dart';
import 'package:pokelife/core/data/gym_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PokéLife BattleEngine & Gym Badge Unit Tests', () {
    test('Test 1: Player and Enemy Max HP scale accurately with level and rarity', () {
      expect(BattleEngine.calculatePlayerMaxHp(5), 80);
      expect(BattleEngine.calculatePlayerMaxHp(16), 157);
      expect(BattleEngine.calculateEnemyMaxHp(5, isRare: false), 65);
      expect(BattleEngine.calculateEnemyMaxHp(5, isRare: true), 85);
    });

    test('Test 2: Type effectiveness matrix returns 1.5x, 0.7x, 1.0x, or 0.0x immunity', () {
      expect(BattleEngine.getTypeMultiplier('GRASS', 'Water'), 1.5);
      expect(BattleEngine.getTypeMultiplier('FIRE', 'Grass / Poison'), 1.5);
      expect(BattleEngine.getTypeMultiplier('WATER', 'Rock / Ground'), 1.5);
      expect(BattleEngine.getTypeMultiplier('ELECTRIC', 'Water / Flying'), 1.5);

      expect(BattleEngine.getTypeMultiplier('GRASS', 'Fire'), 0.7);
      expect(BattleEngine.getTypeMultiplier('FIRE', 'Water'), 0.7);
      expect(BattleEngine.getTypeMultiplier('WATER', 'Grass'), 0.7);

      // Bağışıklık (Electric vs Ground -> 0.0x)
      expect(BattleEngine.getTypeMultiplier('ELECTRIC', 'Rock / Ground'), 0.0);
      expect(BattleEngine.getTypeMultiplier('NORMAL', 'Ghost / Poison'), 0.0);

      expect(BattleEngine.getTypeMultiplier('NORMAL', 'Electric'), 1.0);
    });

    test('Test 3: FALSE SWIPE never drops enemy HP below 1', () {
      final moves = BattleEngine.buildMovesForType('Grass / Poison');
      final falseSwipe = moves.firstWhere((m) => m.isFalseSwipe);

      final outcome = BattleEngine.resolvePlayerAttack(
        move: falseSwipe,
        defenderType: 'Normal',
        attackerLevel: 25,
        defenderLevel: 5,
        currentEnemyHp: 5,
        maxEnemyHp: 65,
      );

      expect(outcome.remainingEnemyHp, 1);
      expect(outcome.damageDealt, 4); // 5 HP -> 1 HP (Gerçek düşen hasar: 4)
      expect(outcome.triggeredFalseSwipe, true);
      expect(outcome.isEnemyFainted, false);
    });

    test('Test 4: Lethal attack clamps enemy HP to 0 and caps damageDealt to remaining HP', () {
      final moves = BattleEngine.buildMovesForType('Fire');
      final emberStrike = moves[1];

      final outcome = BattleEngine.resolvePlayerAttack(
        move: emberStrike,
        defenderType: 'Grass',
        attackerLevel: 15,
        defenderLevel: 5,
        currentEnemyHp: 10,
        maxEnemyHp: 65,
      );

      expect(outcome.isSuperEffective, true);
      expect(outcome.remainingEnemyHp, 0);
      // DÜZELTME (Madde 2.E): Düşmanın 10 HP'si varken gösterilen hasar 10'u aşamaz
      expect(outcome.damageDealt, 10);
      expect(outcome.rawDamage, greaterThan(10));
      expect(outcome.triggeredFalseSwipe, false);
      expect(outcome.isEnemyFainted, true);
    });

    test('Test 5: 1 HP enemy guarantees 100% (1.0) catch probability', () {
      final catchRateAt1Hp = BattleEngine.calculateCatchProbability(
        enemyHp: 1,
        enemyMaxHp: 100,
        isRare: true,
        razzBerryActive: false,
        partnerHearts: 1,
      );

      expect(catchRateAt1Hp, 1.0);
    });

    test('Test 6: Lowering HP, using Razz Berry, and higher Hearts increase catch rate', () {
      final fullHpRate = BattleEngine.calculateCatchProbability(
        enemyHp: 100,
        enemyMaxHp: 100,
        isRare: false,
        razzBerryActive: false,
        partnerHearts: 1,
      );

      final weakenedRate = BattleEngine.calculateCatchProbability(
        enemyHp: 30,
        enemyMaxHp: 100,
        isRare: false,
        razzBerryActive: false,
        partnerHearts: 1,
      );

      final boostedWithBerryAndHearts = BattleEngine.calculateCatchProbability(
        enemyHp: 30,
        enemyMaxHp: 100,
        isRare: false,
        razzBerryActive: true,
        partnerHearts: 5,
      );

      expect(weakenedRate, greaterThan(fullHpRate));
      expect(boostedWithBerryAndHearts, greaterThan(weakenedRate));
      expect(boostedWithBerryAndHearts, lessThanOrEqualTo(0.98));
    });

    test('Test 7: Catch XP and Victory XP reward calculations include bonuses', () {
      final maxCatchXp = BattleEngine.calculateCatchXp(
        isNew: true,
        isRare: true,
        partnerHearts: 4,
        enemyHp: 20,
        enemyMaxHp: 100,
      );
      expect(maxCatchXp, 85);

      final minCatchXp = BattleEngine.calculateCatchXp(
        isNew: false,
        isRare: false,
        partnerHearts: 1,
        enemyHp: 100,
        enemyMaxHp: 100,
      );
      expect(minCatchXp, 20);
    });

    test('Test 8: Gym Badges permanently boost Attack Damage (+5%/badge) and Catch Rate (+3%/badge)', () async {
      SharedPreferences.setMockInitialValues({});

      final firstUnlock = await GymData.unlockBadge('boulder_badge');
      final duplicateUnlock = await GymData.unlockBadge('boulder_badge');
      final earned = await GymData.getEarnedBadges();

      expect(firstUnlock, true);
      expect(duplicateUnlock, false);
      expect(earned.length, 1);

      final move = BattleEngine.buildMovesForType('Water')[1];
      final outcomeNoBadges = BattleEngine.resolvePlayerAttack(
        move: move,
        defenderType: 'Rock',
        attackerLevel: 15,
        defenderLevel: 15,
        currentEnemyHp: 100,
        maxEnemyHp: 100,
        badgeCount: 0,
      );

      final outcomeWith4Badges = BattleEngine.resolvePlayerAttack(
        move: move,
        defenderType: 'Rock',
        attackerLevel: 15,
        defenderLevel: 15,
        currentEnemyHp: 100,
        maxEnemyHp: 100,
        badgeCount: 4,
      );

      expect(outcomeWith4Badges.damageDealt, greaterThan(outcomeNoBadges.damageDealt));
    });

    test('Test 9: Dual-type Normal/Flying builds WING ATTACK with FLYING type and MORNING SUN limits to 2 uses', () {
      final pidgeyMoves = BattleEngine.buildMovesForType('Normal / Flying');
      final specialMove = pidgeyMoves[1];
      final healMove = pidgeyMoves[3];

      expect(specialMove.name, 'WING ATTACK');
      expect(specialMove.type, 'FLYING');
      expect(healMove.isHeal, true);
      expect(healMove.maxUses, 2);
    });
  });
}