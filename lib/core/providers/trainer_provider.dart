import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokelife/core/providers/quest_provider.dart';
import 'package:pokelife/core/data/world_data.dart';
import 'package:pokelife/core/data/evolution_data.dart'; // YENİ: Evrim veritabanı

class TrainerProvider extends ChangeNotifier {
  int _xp = 35;
  int _steps = 0;
  int _dailySteps = 0;
  int _streak = 0;
  String _lastStreakDate = "";
  String _lastStepDate = "";
  
  // O anki tarihi anlık takip eden değişken
  String _lastActiveDate = DateTime.now().toIso8601String().split('T')[0];
  
  List<int> _caughtPokemonIds = [];
  bool _isInitialized = false;
  int _lastSystemStep = 0;
  int _partnerId = 1;
  int _bestDailySteps = 0;
  
  List<String> _unlockedAchievements = [];

  int get xp => _xp;
  int get steps => _steps;
  int get dailySteps => _dailySteps;
  int get streak => _streak;
  List<int> get caughtPokemonIds => _caughtPokemonIds;
  bool get isInitialized => _isInitialized;
  int get partnerId => _partnerId;
  int get bestDailySteps => _bestDailySteps;
  List<String> get unlockedAchievements => _unlockedAchievements;

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
    
    final List<String>? savedList = prefs.getStringList('caught_pokemons');
    if (savedList != null) {
      _caughtPokemonIds = savedList.map((e) => int.parse(e)).toList();
    } else {
      _caughtPokemonIds = [1];
    }

    final List<String>? savedAchievements = prefs.getStringList('unlocked_achievements');
    if (savedAchievements != null) {
      _unlockedAchievements = savedAchievements;
    }
    
    _handleDateChanges(prefs, null); 
    _isInitialized = true;
    notifyListeners();
  }

  void setPartner(int pokeId) async {
    if (_caughtPokemonIds.contains(pokeId)) {
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

    // Adım tarihine göre kontrol
    if (_lastStepDate.isNotEmpty && _lastStepDate != todayStr) {
      _dailySteps = 0; 
      _lastStepDate = todayStr;
      prefs.setInt('trainer_daily_steps', 0);
      prefs.setString('last_step_date', todayStr);
      isNewDay = true;
    } else if (_lastStepDate.isEmpty) {
      _lastStepDate = todayStr;
      prefs.setString('last_step_date', todayStr);
    }

    // Uygulama gece yarısı açık kaldıysa, görevleri ZORLA resetle!
    if (_lastActiveDate != todayStr) {
      _lastActiveDate = todayStr;
      prefs.setString('trainer_last_active_date', todayStr);
      if (questProv != null) {
        questProv.forceResetQuestsForNewDay();
      }
      isNewDay = true;
    }

    // Streak kontrolü
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
    
    int earnedXp = (_dailySteps ~/ 250) - (oldDaily ~/ 250);
    
    if (earnedXp > 0) {
      _xp += earnedXp;
      await prefs.setInt('trainer_xp', _xp);
    }

    if (oldDaily < 1000 && _dailySteps >= 1000) {
      _streak += 1;
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      _lastStreakDate = todayStr;
      
      await prefs.setInt('trainer_streak', _streak);
      await prefs.setString('last_streak_date', _lastStreakDate);
    }

    await prefs.setInt('trainer_steps', _steps);
    await prefs.setInt('trainer_daily_steps', _dailySteps);
    
    questProv.updateStepProgress(_dailySteps);
    
    checkAchievements();
    checkEvolution(); // YENİ: XP artınca evrim kontrolü yap
    notifyListeners();
  }

  void addXp(int amount) async {
    _xp += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('trainer_xp', _xp);
    
    checkAchievements();
    checkEvolution(); // YENİ: XP artınca evrim kontrolü yap
    notifyListeners();
  }

  Future<bool> catchPokemon(int pokeId) async {
    if (!_caughtPokemonIds.contains(pokeId)) {
      _caughtPokemonIds.add(pokeId);
      _caughtPokemonIds.sort(); 
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'caught_pokemons', 
        _caughtPokemonIds.map((e) => e.toString()).toList(),
      );
      
      checkAchievements();
      notifyListeners();
      return true; 
    }
    return false; 
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
    if (_caughtPokemonIds.length >= 1) unlock('first_catch', 50);
    if (_streak >= 7) unlock('getting_serious', 100);
    if (_bestDailySteps >= 10000) unlock('long_walker', 100);
    if (_caughtPokemonIds.length >= 25) unlock('collector', 150);
    
    int unlockedRegions = WorldData.regions.where((r) => _steps >= r.unlockSteps).length;
    if (unlockedRegions >= 3) unlock('explorer', 100);

    if (newlyUnlocked) {
      await prefs.setStringList('unlocked_achievements', _unlockedAchievements);
      await prefs.setInt('trainer_xp', _xp);
      checkEvolution(); // YENİ: Başarımdan gelen XP evrim tetikleyebilir
      notifyListeners();
    }
  }

  // YENİ: EVRİM MOTORU
  void checkEvolution() async {
    final currentLevel = this.level; 
    final evolutionRules = EvolutionData.evolutions[_partnerId];

    if (evolutionRules != null) {
      for (var requiredLevel in evolutionRules.keys) {
        if (currentLevel >= requiredLevel) {
          
          int nextEvolutionId = evolutionRules[requiredLevel]!;
          
          // Partner henüz evrimleşmemişse evrimi gerçekleştir
          if (_partnerId != nextEvolutionId) {
            _partnerId = nextEvolutionId;
            
            if (!_caughtPokemonIds.contains(_partnerId)) {
              _caughtPokemonIds.add(_partnerId);
              _caughtPokemonIds.sort();
            }
            
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('partner_id', _partnerId);
            await prefs.setStringList('caught_pokemons', _caughtPokemonIds.map((e) => e.toString()).toList());
            
            notifyListeners();
            break; 
          }
        }
      }
    }
  }
}