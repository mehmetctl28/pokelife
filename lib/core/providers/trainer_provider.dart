import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokelife/core/providers/quest_provider.dart';
import 'package:pokelife/core/data/world_data.dart';
import 'package:pokelife/core/data/evolution_data.dart';
import 'package:pokelife/core/models/caught_pokemon.dart';
import 'package:pokelife/core/models/region.dart';

class TrainerProvider extends ChangeNotifier {
  int _xp = 35;
  int _steps = 0;
  int _dailySteps = 0;
  int _streak = 0;
  String _lastStreakDate = "";
  String _lastStepDate = "";
  String _lastActiveDate = DateTime.now().toIso8601String().split('T')[0];

  final Map<int, CaughtPokemon> _caughtPokemonMap = {};
  bool _isInitialized = false;
  int _lastSystemStep = 0;
  int _partnerId = 1;
  int _bestDailySteps = 0;

  // Harita Gezginliği (Seyahat) Durumu
  String _selectedRegionId = 'route_1';

  List<String> _unlockedAchievements = [];

  int _usedNormalSearches = 0;
  int _usedRareSearches = 0;

  int get xp => _xp;
  int get steps => _steps;
  int get dailySteps => _dailySteps;
  int get streak => _streak;
  List<int> get caughtPokemonIds => _caughtPokemonMap.keys.toList()..sort();
  Map<int, CaughtPokemon> get caughtPokemons => _caughtPokemonMap;
  bool get isInitialized => _isInitialized;
  int get partnerId => _partnerId;
  int get bestDailySteps => _bestDailySteps;
  List<String> get unlockedAchievements => _unlockedAchievements;
  String get selectedRegionId => _selectedRegionId;

  CaughtPokemon? get activePartner => _caughtPokemonMap[_partnerId];

  // Kullanıcının seçtiği bölge; eğer adım yetmiyorsa açılmış en son bölgeyi döndürür
  Region get currentRegion {
    final unlocked = WorldData.regions.where((r) => _steps >= r.unlockSteps).toList();
    if (unlocked.isEmpty) return WorldData.regions.first;
    return unlocked.firstWhere(
      (r) => r.id == _selectedRegionId,
      orElse: () => unlocked.last,
    );
  }

  // Perk 3: Kalp 3 ve üzeri ise arama eşiği 4.500 adıma iner
  int get _stepCostForSearch {
    final hearts = activePartner?.friendshipHearts ?? 1;
    return hearts >= 3 ? 4500 : 5000;
  }

  int get availableNormalSearches => (_dailySteps ~/ _stepCostForSearch) - _usedNormalSearches;
  int get availableRareSearches => (_dailySteps ~/ 10000) - _usedRareSearches;

  int get level {
    int l = 1;
    int totalRequired = 0;
    while (true) {
      int requiredForNext = l * 100;
      if (_xp >= totalRequired + requiredForNext) {
        totalRequired += requiredForNext;
        l++;
      } else {
        break;
      }
    }
    return l;
  }

  int get currentLevelXp {
    int l = 1;
    int totalRequired = 0;
    while (true) {
      int requiredForNext = l * 100;
      if (_xp >= totalRequired + requiredForNext) {
        totalRequired += requiredForNext;
        l++;
      } else {
        break;
      }
    }
    return _xp - totalRequired;
  }

  int get nextLevelXp => level * 100;

  TrainerProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _xp = prefs.getInt('trainer_xp') ?? 35;
    _steps = prefs.getInt('trainer_steps') ?? 0;
    _dailySteps = prefs.getInt('trainer_daily_steps') ?? 0;
    _streak = prefs.getInt('trainer_streak') ?? 0;
    _lastStreakDate = prefs.getString('last_streak_date') ?? "";
    _lastStepDate = prefs.getString('last_step_date') ?? "";
    _lastSystemStep = prefs.getInt('last_system_step') ?? 0;
    _partnerId = prefs.getInt('partner_id') ?? 1;
    _bestDailySteps = prefs.getInt('best_daily_steps') ?? 0;
    _lastActiveDate = prefs.getString('trainer_last_active_date') ?? DateTime.now().toIso8601String().split('T')[0];

    _selectedRegionId = prefs.getString('selected_region_id') ?? 'route_1';

    _usedNormalSearches = prefs.getInt('used_normal_searches') ?? 0;
    _usedRareSearches = prefs.getInt('used_rare_searches') ?? 0;

    final List<String>? jsonList = prefs.getStringList('caught_pokemons_detailed');
    if (jsonList != null && jsonList.isNotEmpty) {
      for (var str in jsonList) {
        final item = CaughtPokemon.fromMap(json.decode(str));
        _caughtPokemonMap[item.id] = item;
      }
    } else {
      final List<String>? oldList = prefs.getStringList('caught_pokemons');
      if (oldList != null && oldList.isNotEmpty) {
        for (var rawId in oldList) {
          int id = int.tryParse(rawId) ?? 1;
          _caughtPokemonMap[id] = CaughtPokemon(
            id: id,
            level: (id == _partnerId) ? level : 5,
            friendshipPoints: (id == _partnerId) ? (_streak.clamp(1, 5) * 20) : 20,
            caughtAt: DateTime.now(),
          );
        }
      } else {
        _caughtPokemonMap[1] = CaughtPokemon(id: 1, caughtAt: DateTime.now());
      }
      _saveDetailedPokemons(prefs);
    }

    if (!_caughtPokemonMap.containsKey(_partnerId) && _caughtPokemonMap.isNotEmpty) {
      _partnerId = _caughtPokemonMap.keys.first;
    }

    final List<String>? savedAchievements = prefs.getStringList('unlocked_achievements');
    if (savedAchievements != null) {
      _unlockedAchievements = savedAchievements;
    }

    _handleDateChanges(prefs, null);
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _saveDetailedPokemons(SharedPreferences prefs) async {
    final list = _caughtPokemonMap.values.map((p) => json.encode(p.toMap())).toList();
    await prefs.setStringList('caught_pokemons_detailed', list);
    await prefs.setStringList('caught_pokemons', _caughtPokemonMap.keys.map((e) => e.toString()).toList());
  }

  void selectRegion(String regionId) async {
    final region = WorldData.regions.firstWhere((r) => r.id == regionId, orElse: () => WorldData.regions.first);
    if (_steps >= region.unlockSteps) {
      _selectedRegionId = regionId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_region_id', regionId);
      notifyListeners();
    }
  }

  void setPartner(int pokeId) async {
    if (_caughtPokemonMap.containsKey(pokeId)) {
      _partnerId = pokeId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('partner_id', pokeId);
      notifyListeners();
    }
  }

  bool _handleDateChanges(SharedPreferences prefs, QuestProvider? questProv) {
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];
    bool isNewDay = false;

    if (_lastStepDate.isNotEmpty && _lastStepDate != todayStr) {
      _dailySteps = 0;
      _lastStepDate = todayStr;

      _usedNormalSearches = 0;
      _usedRareSearches = 0;
      prefs.setInt('used_normal_searches', 0);
      prefs.setInt('used_rare_searches', 0);

      prefs.setInt('trainer_daily_steps', 0);
      prefs.setString('last_step_date', todayStr);
      isNewDay = true;
    } else if (_lastStepDate.isEmpty) {
      _lastStepDate = todayStr;
      prefs.setString('last_step_date', todayStr);
    }

    if (_lastActiveDate != todayStr) {
      _lastActiveDate = todayStr;
      prefs.setString('trainer_last_active_date', todayStr);

      _usedNormalSearches = 0;
      _usedRareSearches = 0;
      prefs.setInt('used_normal_searches', 0);
      prefs.setInt('used_rare_searches', 0);

      if (questProv != null) {
        questProv.forceResetQuestsForNewDay();
      }
      isNewDay = true;
    }

    if (_lastStreakDate.isNotEmpty) {
      final lastDate = DateTime.parse(_lastStreakDate);
      final diff = DateTime(today.year, today.month, today.day)
          .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
          .inDays;

      if (diff > 1) {
        _streak = 0;
        prefs.setInt('trainer_streak', 0);
      }
    }

    return isNewDay;
  }

  Future<void> processHardwareStep(int hardwareStep, QuestProvider questProv) async {
    final prefs = await SharedPreferences.getInstance();

    bool dateChanged = _handleDateChanges(prefs, questProv);

    if (_lastSystemStep == 0) {
      _lastSystemStep = hardwareStep;
      await prefs.setInt('last_system_step', _lastSystemStep);
      questProv.updateStepProgress(_dailySteps);
      if (dateChanged) notifyListeners();
      return;
    }

    if (hardwareStep < _lastSystemStep) {
      _lastSystemStep = hardwareStep;
      await prefs.setInt('last_system_step', _lastSystemStep);
      questProv.updateStepProgress(_dailySteps);
      if (dateChanged) notifyListeners();
      return;
    }

    int delta = hardwareStep - _lastSystemStep;
    if (delta > 0) {
      _lastSystemStep = hardwareStep;
      await prefs.setInt('last_system_step', _lastSystemStep);
      await addSteps(delta, questProv);
    } else if (dateChanged) {
      notifyListeners();
    }
  }

  Future<void> addSteps(int delta, QuestProvider questProv) async {
    if (delta <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    _handleDateChanges(prefs, questProv);

    int oldDaily = _dailySteps;
    _steps += delta;
    _dailySteps += delta;

    if (_dailySteps > _bestDailySteps) {
      _bestDailySteps = _dailySteps;
      await prefs.setInt('best_daily_steps', _bestDailySteps);
    }

    // Aktif partnere özel adım ve arkadaşlık artışı
    final partner = activePartner;
    if (partner != null) {
      partner.addSteps(delta);
    }

    int earnedXp = (_dailySteps ~/ 250) - (oldDaily ~/ 250);
    if (earnedXp > 0) {
      _xp += earnedXp;
      await prefs.setInt('trainer_xp', _xp);
      partner?.addXp(earnedXp);
    }

    if (oldDaily < 1000 && _dailySteps >= 1000) {
      _streak += 1;
      partner?.addFriendshipPoints(2);

      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      _lastStreakDate = todayStr;

      await prefs.setInt('trainer_streak', _streak);
      await prefs.setString('last_streak_date', _lastStreakDate);
    }

    await prefs.setInt('trainer_steps', _steps);
    await prefs.setInt('trainer_daily_steps', _dailySteps);
    await _saveDetailedPokemons(prefs);

    questProv.updateStepProgress(_dailySteps);
    checkAchievements();
    notifyListeners();
  }

  Future<void> addXp(int amount) async {
    _xp += amount;
    final partner = activePartner;
    partner?.addXp(amount);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('trainer_xp', _xp);
    await _saveDetailedPokemons(prefs);

    checkAchievements();
    notifyListeners();
  }

  Future<bool> catchPokemon(int pokeId, {int wildLevel = 5, String? location}) async {
    final prefs = await SharedPreferences.getInstance();

    activePartner?.addFriendshipPoints(1);

    if (!_caughtPokemonMap.containsKey(pokeId)) {
      _caughtPokemonMap[pokeId] = CaughtPokemon(
        id: pokeId,
        level: wildLevel,
        friendshipPoints: 20,
        caughtAt: DateTime.now(),
        caughtLocation: location,
      );
      await _saveDetailedPokemons(prefs);
      checkAchievements();
      notifyListeners();
      return true;
    } else {
      _caughtPokemonMap[pokeId]?.addXp(25);
      await _saveDetailedPokemons(prefs);
      notifyListeners();
      return false;
    }
  }

  void checkAchievements() async {
    bool newlyUnlocked = false;
    final prefs = await SharedPreferences.getInstance();

    void unlock(String id, int xp) {
      if (!_unlockedAchievements.contains(id)) {
        _unlockedAchievements.add(id);
        _xp += xp;
        newlyUnlocked = true;
      }
    }

    if (_steps >= 1000) unlock('first_steps', 50);
    if (_caughtPokemonMap.isNotEmpty) unlock('first_catch', 50);
    if (_streak >= 7) unlock('getting_serious', 100);
    if (_bestDailySteps >= 10000) unlock('long_walker', 100);
    if (_caughtPokemonMap.length >= 25) unlock('collector', 150);

    int unlockedRegions = WorldData.regions.where((r) => _steps >= r.unlockSteps).length;
    if (unlockedRegions >= 3) unlock('explorer', 100);

    if (newlyUnlocked) {
      await prefs.setStringList('unlocked_achievements', _unlockedAchievements);
      await prefs.setInt('trainer_xp', _xp);
      notifyListeners();
    }
  }

  bool triggerManualEvolution() {
    final partner = activePartner;
    if (partner == null) return false;

    final currentLevel = partner.level;
    final evolutionRules = EvolutionData.evolutions[_partnerId];

    if (evolutionRules != null) {
      for (var requiredLevel in evolutionRules.keys) {
        if (currentLevel >= requiredLevel) {
          int nextEvolutionId = evolutionRules[requiredLevel]!;

          if (_partnerId != nextEvolutionId) {
            final oldPokemon = _caughtPokemonMap.remove(_partnerId);
            _partnerId = nextEvolutionId;

            _caughtPokemonMap[_partnerId] = CaughtPokemon(
              id: _partnerId,
              level: oldPokemon?.level ?? currentLevel,
              xp: oldPokemon?.xp ?? 0,
              friendshipPoints: oldPokemon?.friendshipPoints ?? 20,
              stepsWalked: oldPokemon?.stepsWalked ?? 0,
              caughtAt: oldPokemon?.caughtAt ?? DateTime.now(),
              caughtLocation: oldPokemon?.caughtLocation,
            );

            SharedPreferences.getInstance().then((prefs) {
              prefs.setInt('partner_id', _partnerId);
              _saveDetailedPokemons(prefs);
            });

            notifyListeners();
            return true;
          }
        }
      }
    }
    return false;
  }

  void consumeNormalSearch() async {
    _usedNormalSearches++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('used_normal_searches', _usedNormalSearches);
    notifyListeners();
  }

  void consumeRareSearch() async {
    _usedRareSearches++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('used_rare_searches', _usedRareSearches);
    notifyListeners();
  }
}