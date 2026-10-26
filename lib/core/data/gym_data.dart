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

  /// DÜZELTME (Madde 3.4): Liderin takımındaki en güçlü Pokémon'a göre önerilen partner seviyesi
  int get recommendedLevel {
    if (team.isEmpty) return 5;
    int maxLvl = team.first.level;
    for (final p in team) {
      if (p.level > maxLvl) maxLvl = p.level;
    }
    return maxLvl;
  }
}

class GymData {
  static const String _prefsKey = 'earned_gym_badges';

  /// DÜZELTME (Madde 3.2): Lider unvanları ve hikâyeleri WorldData bölgeleriyle birebir uyumlu hale getirildi
  static const List<GymLeader> leaders = [
    GymLeader(
      regionId: 'route_1',
      leaderName: 'JOEY',
      title: 'Route 1 Rookie Challenge',
      badgeId: 'rookie_badge',
      badgeName: 'Rookie Emblem',
      badgeEmoji: '🎗️',
      introQuote: 'My Rattata is in the top percentage on Route 1! Show me your steps!',
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
      title: 'Viridian-Pewter Vanguard',
      badgeId: 'boulder_badge',
      badgeName: 'Boulder Badge',
      badgeEmoji: '🪨',
      introQuote: 'I guard the northern exit of Viridian Forest toward Pewter City! Ready?',
      defeatQuote: 'Your willpower is rock-solid! Take the official BOULDER BADGE!',
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
      title: 'Mt. Moon-Cerulean Leader',
      badgeId: 'cascade_badge',
      badgeName: 'Cascade Badge',
      badgeEmoji: '💧',
      introQuote: 'Crossing Mt. Moon toward Cerulean? My Water-types will test you first!',
      defeatQuote: 'Wow! You conquered the mountain pass! Here is the CASCADE BADGE!',
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
      title: 'Cerulean Cape Commander',
      badgeId: 'thunder_badge',
      badgeName: 'Thunder Badge',
      badgeEmoji: '⚡',
      introQuote: 'At Cerulean Cape, my electric Pokémon will zap anyone who slacks off!',
      defeatQuote: 'Whoa! You walked the distance, kid! Take the THUNDER BADGE!',
      perkDescription: '+5% Attack DMG & +3% Catch Rate',
      rewardXp: 400,
      team: [
        GymPokemon(id: 100, level: 22), // Voltorb
        GymPokemon(id: 26, level: 25), // Raichu
      ],
    ),
  ];

  static GymLeader getLeaderForRegion(String regionId, String regionName) {
    for (final leader in leaders) {
      if (leader.regionId == regionId) return leader;
    }
    return GymLeader(
      regionId: regionId,
      leaderName: 'KANTO ACE',
      title: '$regionName Guardian',
      badgeId: '${regionId}_badge',
      badgeName: '$regionName Badge',
      badgeEmoji: '🏅',
      introQuote: 'Only true walkers can conquer $regionName! Prepare yourself!',
      defeatQuote: 'Incredible strength! This badge belongs to you!',
      perkDescription: '+5% Attack DMG & +3% Catch Rate',
      rewardXp: 350,
      team: const [
        GymPokemon(id: 58, level: 24),
        GymPokemon(id: 59, level: 28),
      ],
    );
  }

  /// DÜZELTME (Madde 3.4): Henüz kazanılmamış ilk Gym hedefini döndürür
  static GymLeader? getNextUndefeatedLeader(List<String> earnedBadges) {
    for (final leader in leaders) {
      if (!earnedBadges.contains(leader.badgeId)) {
        return leader;
      }
    }
    return null;
  }

  static Future<List<String>> getEarnedBadges() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_prefsKey) ?? <String>[];
  }

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