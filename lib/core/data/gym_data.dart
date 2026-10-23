import 'package:shared_preferences/shared_preferences.dart';

class GymPokemon {
  final int id;
  final int level;

  const GymPokemon({required this.id, required this.level});
}

class GymLeader {
  final String regionId;
  final String leaderName;
  final String title;
  final String badgeId;
  final String badgeName;
  final String badgeEmoji;
  final String introQuote;
  final String defeatQuote;
  final String perkDescription;
  final int rewardXp;
  final List<GymPokemon> team;

  const GymLeader({
    required this.regionId,
    required this.leaderName,
    required this.title,
    required this.badgeId,
    required this.badgeName,
    required this.badgeEmoji,
    required this.introQuote,
    required this.defeatQuote,
    required this.perkDescription,
    required this.rewardXp,
    required this.team,
  });
}

class GymData {
  static const String _prefsKey = 'earned_gym_badges';

  static const List<GymLeader> leaders = [
    GymLeader(
      regionId: 'route_1',
      leaderName: 'JOEY',
      title: 'Rookie Ace Trainer',
      badgeId: 'rookie_badge',
      badgeName: 'Rookie Badge',
      badgeEmoji: '🎗️',
      introQuote: 'My Rattata is in the top percentage! Show me your steps!',
      defeatQuote: 'Whoa! Your partner bond is way stronger than I expected!',
      perkDescription: '+5% Attack DMG & +3% Catch Rate',
      rewardXp: 120,
      team: [
        GymPokemon(id: 19, level: 5), // Rattata
        GymPokemon(id: 17, level: 7), // Pidgeotto
      ],
    ),
    GymLeader(
      regionId: 'viridian_forest',
      leaderName: 'BROCK',
      title: 'Pewter Gym Leader',
      badgeId: 'boulder_badge',
      badgeName: 'Boulder Badge',
      badgeEmoji: '🪨',
      introQuote: 'My rock-hard willpower is evident in my Pokémon! Ready?',
      defeatQuote: 'I took you for granted. Take the official BOULDER BADGE!',
      perkDescription: '+5% Attack DMG & +3% Catch Rate',
      rewardXp: 200,
      team: [
        GymPokemon(id: 74, level: 12), // Geodude
        GymPokemon(id: 95, level: 14), // Onix
      ],
    ),
    GymLeader(
      regionId: 'mt_moon',
      leaderName: 'MISTY',
      title: 'Cerulean Gym Leader',
      badgeId: 'cascade_badge',
      badgeName: 'Cascade Badge',
      badgeEmoji: '💧',
      introQuote: 'My policy is an all-out offensive with Water-type Pokémon!',
      defeatQuote: 'Wow! You are too much! You earned the CASCADE BADGE!',
      perkDescription: '+5% Attack DMG & +3% Catch Rate',
      rewardXp: 300,
      team: [
        GymPokemon(id: 120, level: 18), // Staryu
        GymPokemon(id: 121, level: 21), // Starmie
      ],
    ),
    GymLeader(
      regionId: 'cerulean_city',
      leaderName: 'LT. SURGE',
      title: 'Vermilion Gym Leader',
      badgeId: 'thunder_badge',
      badgeName: 'Thunder Badge',
      badgeEmoji: '⚡',
      introQuote: 'Hey kid! My electric Pokémon saved me! They will zap you!',
      defeatQuote: 'Whoa! You are the real deal! Take the THUNDER BADGE!',
      perkDescription: '+5% Attack DMG & +3% Catch Rate',
      rewardXp: 400,
      team: [
        GymPokemon(id: 100, level: 22), // Voltorb
        GymPokemon(id: 26, level: 25), // Raichu
      ],
    ),
  ];

  /// Bölgeye göre Gym Liderini döndürür (Tanımsız bölgeler için dinamik lider üretir)
  static GymLeader getLeaderForRegion(String regionId, String regionName) {
    for (final leader in leaders) {
      if (leader.regionId == regionId) return leader;
    }
    return GymLeader(
      regionId: regionId,
      leaderName: 'E4 CHALLENGER',
      title: '$regionName Master',
      badgeId: '${regionId}_badge',
      badgeName: '$regionName Badge',
      badgeEmoji: '🏅',
      introQuote: 'Only true walkers can conquer $regionName! Prepare yourself!',
      defeatQuote: 'Incredible strength! This badge belongs to you!',
      perkDescription: '+5% Attack DMG & +3% Catch Rate',
      rewardXp: 350,
      team: const [
        GymPokemon(id: 58, level: 24), // Growlithe
        GymPokemon(id: 59, level: 28), // Arcanine
      ],
    );
  }

  /// Kazanılmış rozet ID listesini yükler
  static Future<List<String>> getEarnedBadges() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_prefsKey) ?? <String>[];
  }

  /// Yeni kazanılan rozeti kaydeder. İlk kez kazanıldıysa true döner.
  static Future<bool> unlockBadge(String badgeId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_prefsKey) ?? <String>[];
    if (!current.contains(badgeId)) {
      current.add(badgeId);
      await prefs.setStringList(_prefsKey, current);
      return true;
    }
    return false;
  }
}