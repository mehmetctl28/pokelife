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

    test('Test 2: Type effectiveness matrix returns 1.5x, 0.7x, or 1.0x', () {
      expect(BattleEngine.getTypeMultiplier('GRASS', 'Water'), 1.5);
      expect(BattleEngine.getTypeMultiplier('FIRE', 'Grass / Poison'), 1.5);
      expect(BattleEngine.getTypeMultiplier('WATER', 'Rock / Ground'), 1.5);
      expect(BattleEngine.getTypeMultiplier('ELECTRIC', 'Water / Flying'), 1.5);

      expect(BattleEngine.getTypeMultiplier('GRASS', 'Fire'), 0.7);
      expect(BattleEngine.getTypeMultiplier('FIRE', 'Water'), 0.7);
      expect(BattleEngine.getTypeMultiplier('WATER', 'Grass'), 0.7);

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
      expect(outcome.triggeredFalseSwipe, true);
      expect(outcome.isEnemyFainted, false);
    });

    test('Test 4: Standard lethal attack clamps enemy HP to 0 and triggers faint', () {
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

      // Brock rozetini kazanma ve duplicate engelleme testi
      final firstUnlock = await GymData.unlockBadge('boulder_badge');
      final duplicateUnlock = await GymData.unlockBadge('boulder_badge');
      final earned = await GymData.getEarnedBadges();

      expect(firstUnlock, true);
      expect(duplicateUnlock, false);
      expect(earned.length, 1);

      // 0 Rozet vs 4 Rozet Hasar Karşılaştırması
      final move = BattleEngine.buildMovesForType('Water')[1]; // WATER PULSE (Power: 24)
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

      // 0 Rozet vs 4 Rozet Yakalama Oranı Karşılaştırması
      final catchNoBadges = BattleEngine.calculateCatchProbability(
        enemyHp: 80,
        enemyMaxHp: 100,
        isRare: false,
        razzBerryActive: false,
        partnerHearts: 1,
        badgeCount: 0,
      );

      final catchWith4Badges = BattleEngine.calculateCatchProbability(
        enemyHp: 80,
        enemyMaxHp: 100,
        isRare: false,
        razzBerryActive: false,
        partnerHearts: 1,
        badgeCount: 4,
      );

      expect(catchWith4Badges, greaterThan(catchNoBadges));
    });
  });
}