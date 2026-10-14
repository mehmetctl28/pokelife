import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';
import 'package:pokelife/core/providers/quest_provider.dart';
import 'package:pokelife/core/data/world_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PokéLife 7 Core Game Logic Unit Tests', () {
    late TrainerProvider trainer;
    late QuestProvider questProvider;

    /// Yardımcı fonksiyon: SharedPreferences mock verisiyle TrainerProvider'ı
    /// başlatır ve asenkron _loadData() işleminin bitmesini bekler.
    Future<TrainerProvider> createInitializedTrainer([
      Map<String, Object> customPrefs = const {},
    ]) async {
      SharedPreferences.setMockInitialValues({
        // Başarım kaynaklı ekstra XP'lerin saf adım-XP testini bozmaması için:
        'unlocked_achievements': <String>[
          'first_steps',
          'first_catch',
          'getting_serious',
          'long_walker',
          'collector',
          'explorer',
        ],
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

    // Test 6: level 16 Bulbasaur → Ivysaur
    test('Test 6: level 16 Bulbasaur -> evolves into Ivysaur (id: 2)', () async {
      // Başlangıç partneri Bulbasaur (id: 1, level: 5)
      expect(trainer.activePartner!.id, 1);

      // Seviye 15'te evrim gerçekleşmemeli
      trainer.activePartner!.level = 15;
      expect(trainer.triggerManualEvolution(), false);
      expect(trainer.activePartner!.id, 1);

      // Seviye 16'ya ulaştığında (15 -> 16 için 1500 XP gerekir)
      await trainer.addXp(1500);
      expect(trainer.activePartner!.level, greaterThanOrEqualTo(16));

      // Evrim tetiklendiğinde Ivysaur (id: 2) olmalı
      final evolved = trainer.triggerManualEvolution();
      expect(evolved, true);
      expect(trainer.partnerId, 2);
      expect(trainer.activePartner!.id, 2);
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
  });
}