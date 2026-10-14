import '../models/achievement.dart';

class AchievementData {
  static const List<Achievement> achievements = [
    Achievement(
      id: 'first_steps',
      title: '🥾 FIRST STEPS',
      description: '1,000 total steps',
      rewardXp: 50,
      target: 1000,
    ),
    Achievement(
      id: 'first_catch',
      title: '🔴 FIRST CATCH',
      description: 'Catch 1 Pokémon',
      rewardXp: 50,
      target: 1,
    ),
    Achievement(
      id: 'getting_serious',
      title: '🔥 GETTING SERIOUS',
      description: '7-day streak',
      rewardXp: 100,
      target: 7,
    ),
    Achievement(
      id: 'long_walker',
      title: '🏃 LONG WALKER',
      description: '10k steps in a day',
      rewardXp: 100,
      target: 10000,
    ),
    Achievement(
      id: 'collector',
      title: '🎒 COLLECTOR',
      description: 'Catch 25 Pokémon',
      rewardXp: 150,
      target: 25,
    ),
    Achievement(
      id: 'explorer',
      title: '🗺️ EXPLORER',
      description: 'Unlock 3 regions',
      rewardXp: 100,
      target: 3,
    ),
  ];
}