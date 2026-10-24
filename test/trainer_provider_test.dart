import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';
import 'package:pokelife/core/providers/quest_provider.dart';
import 'package:pokelife/core/data/world_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PokéLife Core Game Logic Unit Tests', () {
    late TrainerProvider trainer;
    late QuestProvider questProvider;

    /// Yardımcı fonksiyon: SharedPreferences mock verisiyle TrainerProvider'ı
    /// sıfırdan gerçek bir yeni oyuncu gibi başlatır.
    Future<TrainerProvider> createInitializedTrainer([
      Map<String, Object> customPrefs = const {},
    ]) async {
      SharedPreferences.setMockInitialValues({
        ...customPrefs,
      });

      final provider = TrainerProvider();
      while (!provider.isInitialized) {
        await Future.delayed(Duration.zero);
      }
      return provider;
    }

    setUp(() async {
      trainer = await createInitializedTrainer();
      questProvider = QuestProvider();
    });

    // Test 1: 249 steps → 0 XP
    test('Test 1: 249 steps -> 0 XP', () async {
      final initialTrainerXp = trainer.xp;
      final initialPartnerXp = trainer.activePartner!.xp;

      await trainer.addSteps(249, questProvider);

      expect(trainer.dailySteps, 249);
      expect(trainer.xp - initialTrainerXp, 0);
      expect(trainer.activePartner!.xp - initialPartnerXp, 0);
      expect(trainer.unlockedAchievements.contains('first_catch'), false);
    });

    // Test 2: 250 steps → 1 XP
    test('Test 2: 250 steps -> 1 XP', () async {
      final initialTrainerXp = trainer.xp;

      await trainer.addSteps(250, questProvider);

      expect(trainer.dailySteps, 250);
      expect(trainer.xp - initialTrainerXp, 1);
      expect(trainer.activePartner!.xp, 1);
    });

    // Test 3: 1000 daily steps → streak +1
    test('Test 3: 1000 daily steps -> streak +1', () async {
      expect(trainer.streak, 0);

      await trainer.addSteps(1000, questProvider);

      expect(trainer.dailySteps, 1000);
      expect(trainer.streak, 1);
    });

    // Test 4: 1000 → 1001 → streak tekrar +1 olmamalı
    test('Test 4: 1000 -> 1001 steps -> streak should not increment again', () async {
      await trainer.addSteps(1000, questProvider);
      expect(trainer.streak, 1);

      await trainer.addSteps(1, questProvider); // Toplam 1001 adım
      expect(trainer.dailySteps, 1001);
      expect(trainer.streak, 1); // Tekrar artmamalı, 1 kalmalı
    });

    // Test 5: missed day → streak reset
    test('Test 5: missed day -> streak reset to 0', () async {
      final twoDaysAgo = DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String()
          .split('T')[0];

      // 2 gün önce streak yapmış (dünü kaçırmış) bir kullanıcı simülasyonu
      final missedDayTrainer = await createInitializedTrainer({
        'trainer_streak': 5,
        'last_streak_date': twoDaysAgo,
      });

      expect(missedDayTrainer.streak, 0);
    });

    // Test 6: level 16 Bulbasaur → Ivysaur (Eski Pokémon silinmeden koleksiyonda kalır)
    test('Test 6: level 16 Bulbasaur -> evolves into Ivysaur (id: 2) and retains Bulbasaur', () async {
      expect(trainer.activePartner!.id, 1);

      // Seviye 15'te evrim gerçekleşmemeli
      trainer.activePartner!.level = 15;
      expect(trainer.canEvolvePartner, false);
      expect(trainer.triggerManualEvolution(), false);
      expect(trainer.activePartner!.id, 1);

      // Seviye 16'ya ulaştığında (15 -> 16 için 1500 XP gerekir)
      await trainer.addXp(1500);
      expect(trainer.activePartner!.level, greaterThanOrEqualTo(16));
      expect(trainer.canEvolvePartner, true);

      // Evrim tetiklendiğinde Ivysaur (id: 2) olmalı ve Bulbasaur (id: 1) silinmemeli!
      final evolved = trainer.triggerManualEvolution();
      expect(evolved, true);
      expect(trainer.partnerId, 2);
      expect(trainer.activePartner!.id, 2);
      expect(trainer.caughtPokemonIds.contains(1), true);
      expect(trainer.caughtPokemonIds.contains(2), true);
    });

    // Test 7: Toplam adım eşiği → Viridian Forest kilidi açılması
    test('Test 7: Reaching Viridian Forest step threshold unlocks region', () async {
      final viridian = WorldData.regions.firstWhere(
        (r) => r.id == 'viridian_forest',
      );
      final requiredSteps = viridian.unlockSteps;

      // Eşiğin 1 adım altında bölge kilitli olmalı (Route 1'de kalmalı)
      await trainer.addSteps(requiredSteps - 1, questProvider);
      trainer.selectRegion('viridian_forest');
      expect(trainer.currentRegion.id, 'route_1');

      // Eşik tamamlandığında Viridian Forest açılmalı ve seçilebilmeli
      await trainer.addSteps(1, questProvider);
      trainer.selectRegion('viridian_forest');
      expect(trainer.currentRegion.id, 'viridian_forest');
    });

    // Test 8: Starter Pokémon 'first_catch' açmaz, sadece gerçek vahşi yakalama açar
    test('Test 8: Starter does not unlock first_catch; catching wild Pokémon does', () async {
      await trainer.addSteps(500, questProvider);
      expect(trainer.unlockedAchievements.contains('first_catch'), false);

      final isNew = await trainer.catchPokemon(16, wildLevel: 4, location: 'Route 1');
      expect(isNew, true);
      expect(trainer.unlockedAchievements.contains('first_catch'), true);

      // Aynı türü tekrar yakalamak koleksiyon sayısını artırmamalı
      final isDuplicate = await trainer.catchPokemon(16, wildLevel: 4, location: 'Route 1');
      expect(isDuplicate, false);
      expect(trainer.caughtPokemonIds.length, 2); // Bulbasaur (1) + Pidgey (16)
    });

    // Test 9: Atomik arama hakkı kontrolü (Hak yoksa tüketilemez)
    test('Test 9: Atomic search consumption prevents negative search charges', () async {
      expect(trainer.availableNormalSearches, 0);
      expect(trainer.tryConsumeNormalSearch(), false);
      expect(trainer.availableNormalSearches, 0);

      // 5000 adım -> 1 normal arama hakkı doğmalı
      await trainer.addSteps(5000, questProvider);
      expect(trainer.availableNormalSearches, 1);
      expect(trainer.tryConsumeNormalSearch(), true);
      expect(trainer.availableNormalSearches, 0);

      // İkinci kez basılırsa reddedilmeli
      expect(trainer.tryConsumeNormalSearch(), false);
    });

    // Test 10: Quest ödülü yalnızca bir kez alınabilir (Double-Claim Koruması)
    test('Test 10: Quest reward can only be claimed once and never duplicates XP', () async {
      // 1000 adım yürüyerek 'daily_walk_1000' görevini tamamla (+25 XP ödüllü)
      await trainer.addSteps(1000, questProvider);
      final xpBeforeClaim = trainer.xp;

      // İlk talep başarılı olmalı
      final firstClaim = await questProvider.claimReward('daily_walk_1000', trainer);
      expect(firstClaim, true);
      final xpAfterFirstClaim = trainer.xp;
      expect(xpAfterFirstClaim, greaterThan(xpBeforeClaim));

      // İkinci kez talep edildiğinde reddedilmeli ve XP kesinlikle artmamalı!
      final secondClaim = await questProvider.claimReward('daily_walk_1000', trainer);
      expect(secondClaim, false);
      expect(trainer.xp, xpAfterFirstClaim);
    });
  });
}