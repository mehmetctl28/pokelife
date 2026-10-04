import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrainerProvider extends ChangeNotifier {
  int _xp = 35;
  int _steps = 0;
  int _dailySteps = 0;
  String _lastBonusDate = "";
  int _streak = 0;
  String _lastStreakDate = "";
  String _lastStepDate = "";
  
  // POKÉDEX LİSTESİ
  List<int> _caughtPokemonIds = [];

  int get xp => _xp;
  int get steps => _steps;
  int get dailySteps => _dailySteps;
  int get streak => _streak;
  List<int> get caughtPokemonIds => _caughtPokemonIds;
  
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

  bool get isBonusClaimedToday {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return _lastBonusDate == today;
  }

  TrainerProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _xp = prefs.getInt('trainer_xp') ?? 35;
    _steps = prefs.getInt('trainer_steps') ?? 0;
    _dailySteps = prefs.getInt('trainer_daily_steps') ?? 0;
    _lastBonusDate = prefs.getString('last_bonus_date') ?? "";
    _streak = prefs.getInt('trainer_streak') ?? 0;
    _lastStreakDate = prefs.getString('last_streak_date') ?? "";
    _lastStepDate = prefs.getString('last_step_date') ?? "";
    
    // Diske kaydedilmiş yakalanan Pokémon'ları yükle
    final List<String>? savedList = prefs.getStringList('caught_pokemons');
    if (savedList != null) {
      _caughtPokemonIds = savedList.map((e) => int.parse(e)).toList();
    } else {
      // Başlangıç hediyesi: Bulbasaur (1)
      _caughtPokemonIds = [1];
    }
    
    _checkDailyReset(prefs);
    _checkStreak(prefs);
    notifyListeners();
  }

  void _checkDailyReset(SharedPreferences prefs) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (_lastStepDate != today) {
      _dailySteps = 0;
      _lastStepDate = today;
      prefs.setInt('trainer_daily_steps', 0);
      prefs.setString('last_step_date', today);
    }
  }

  void _checkStreak(SharedPreferences prefs) {
    if (_lastStreakDate.isEmpty) return;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final lastDate = DateTime.parse(_lastStreakDate);
    final lastStreakDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
    
    if (todayDate.difference(lastStreakDay).inDays > 1) {
      _streak = 0;
      prefs.setInt('trainer_streak', 0);
    }
  }

  void addSteps(int newSteps) async {
    _steps += newSteps;
    _dailySteps += newSteps;
    
    if (_dailySteps % 250 == 0) {
      _xp += 1;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('trainer_steps', _steps);
    await prefs.setInt('trainer_daily_steps', _dailySteps);
    await prefs.setInt('trainer_xp', _xp);
    notifyListeners();
  }

  void addXp(int amount) async {
    _xp += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('trainer_xp', _xp);
    notifyListeners();
  }

  // POKÉMON YAKALAMA FONKSİYONU
  void catchPokemon(int pokeId) async {
    if (!_caughtPokemonIds.contains(pokeId)) {
      _caughtPokemonIds.add(pokeId);
      _caughtPokemonIds.sort(); 
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'caught_pokemons', 
        _caughtPokemonIds.map((e) => e.toString()).toList(),
      );
      notifyListeners();
    }
  }

  void claimDailyBonus() async {
    if (isBonusClaimedToday) return;
    
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];
    _lastBonusDate = todayStr;
    _xp += 15; 
    
    if (_lastStreakDate.isEmpty) {
      _streak = 1;
    } else {
      final lastDate = DateTime.parse(_lastStreakDate);
      final lastStreakDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final todayDate = DateTime(today.year, today.month, today.day);
      final diff = todayDate.difference(lastStreakDay).inDays;
      
      if (diff == 1) _streak++;
      else if (diff > 1) _streak = 1;
    }
    _lastStreakDate = todayStr;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_bonus_date', todayStr);
    await prefs.setString('last_streak_date', todayStr);
    await prefs.setInt('trainer_xp', _xp);
    await prefs.setInt('trainer_streak', _streak);
    notifyListeners();
  }
}