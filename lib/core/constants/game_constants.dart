class GameConstants {
  // Günlük Adım ve XP Kuralları
  static const int stepsPerXp = 250;
  static const int dailyFirstMilestone = 1000;
  static const int dailyNormalSearchCost = 5000;
  static const int dailyEnergySaverSearchCost = 4500;
  static const int dailyRareGoal = 10000;

  // Kanto Bölge Açılma Eşikleri (Tek Doğruluk Kaynağı - Single Source of Truth)
  static const int route1UnlockSteps = 0;
  static const int viridianForestUnlockSteps = 15000;
  static const int mtMoonUnlockSteps = 35000;
  static const int ceruleanCityUnlockSteps = 65000;
}