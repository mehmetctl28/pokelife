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
  
  List<int> _caughtPokemonIds = [];
  bool _isInitialized = false;
  int _lastSystemStep = 0;

  int get xp => _xp;
  int get steps => _steps;
  int get dailySteps => _dailySteps;
  int get streak => _streak;
  List<int> get caughtPokemonIds => _caughtPokemonIds;
  bool get isInitialized => _isInitialized;
  
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
    _lastSystemStep = prefs.getInt('last_system_step') ?? 0;
    
    final List<String>? savedList = prefs.getStringList('caught_pokemons');
    if (savedList != null) {
      _caughtPokemonIds = savedList.map((e) => int.parse(e)).toList();
    } else {
      _caughtPokemonIds = [1];
    }
    
    _handleDateChanges(prefs);
    _isInitialized = true;
    notifyListeners();
  }

  // 1. GÜN DÖNÜMÜ KALKANI (Midnight Reset)
  bool _handleDateChanges(SharedPreferences prefs) {
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];
    bool isNewDay = false;

    if (_lastStepDate.isNotEmpty && _lastStepDate != todayStr) {
      _dailySteps = 0; // Gece 00:00 oldu, adımları sıfırla
      _lastStepDate = todayStr;
      prefs.setInt('trainer_daily_steps', 0);
      prefs.setString('last_step_date', todayStr);
      isNewDay = true;
    } else if (_lastStepDate.isEmpty) {
      _lastStepDate = todayStr;
      prefs.setString('last_step_date', todayStr);
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

  // 2. DONANIM SAYACI VE ARKA PLAN KORUMASI
  void processHardwareStep(int hardwareStep) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Önce gün dönümü kontrolü yap, dünün adımları bugüne sarkmasın!
    bool dateChanged = _handleDateChanges(prefs);

    if (_lastSystemStep == 0) {
      _lastSystemStep = hardwareStep;
      await prefs.setInt('last_system_step', _lastSystemStep);
      if (dateChanged) notifyListeners(); // Sadece gün değiştiyse ekranı güncelle
      return;
    }

    // Telefon yeniden başlatıldıysa donanım sayacı 0'lanır. Eksiye düşmeyi engelle.
    if (hardwareStep < _lastSystemStep) {
      _lastSystemStep = hardwareStep;
      await prefs.setInt('last_system_step', _lastSystemStep);
      if (dateChanged) notifyListeners();
      return;
    }

    // Uygulama kapalıyken (veya açıkken) atılan farkı bul
    int delta = hardwareStep - _lastSystemStep;
    if (delta > 0) {
      _lastSystemStep = hardwareStep;
      await prefs.setInt('last_system_step', _lastSystemStep);
      addSteps(delta); // Bu işlem zaten notifyListeners tetikler
    } else if (dateChanged) {
      // Adım atılmadı ama gece yarısı olduysa ekranı "0 adım" olarak güncelle
      notifyListeners();
    }
  }

  void addSteps(int delta) async {
    if (delta <= 0) return;
    
    final prefs = await SharedPreferences.getInstance();
    _handleDateChanges(prefs); 

    int oldDaily = _dailySteps;
    _steps += delta;
    _dailySteps += delta;
    
    int earnedXp = (_dailySteps ~/ 250) - (oldDaily ~/ 250);
    
    if (earnedXp > 0) {
      _xp += earnedXp;
      await prefs.setInt('trainer_xp', _xp);
    }

    await prefs.setInt('trainer_steps', _steps);
    await prefs.setInt('trainer_daily_steps', _dailySteps);
    notifyListeners();
  }

  void addXp(int amount) async {
    _xp += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('trainer_xp', _xp);
    notifyListeners();
  }

  // 3. TEKRAR YAKALAMA İSTİSMARI ENGELLEYİCİ
  Future<bool> catchPokemon(int pokeId) async {
    if (!_caughtPokemonIds.contains(pokeId)) {
      _caughtPokemonIds.add(pokeId);
      _caughtPokemonIds.sort(); 
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'caught_pokemons', 
        _caughtPokemonIds.map((e) => e.toString()).toList(),
      );
      notifyListeners();
      return true; // Sadece ilk yakalamada True döner
    }
    return false; // Zaten koleksiyonda var, XP veya Görev ilerlemesi verilmez
  }

  void claimDailyBonus() async {
    if (isBonusClaimedToday) return;
    
    final prefs = await SharedPreferences.getInstance();
    _handleDateChanges(prefs); 
    
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];
    
    _lastBonusDate = todayStr;
    _xp += 15; 
    
    if (_lastStreakDate.isEmpty) {
      _streak = 1;
    } else {
      final lastDate = DateTime.parse(_lastStreakDate);
      final diff = DateTime(today.year, today.month, today.day)
          .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
          .inDays;
      
      if (diff == 1) {
        _streak++;
      } else if (diff > 1) {
        _streak = 1; 
      }
    }
    
    _lastStreakDate = todayStr;
    
    await prefs.setString('last_bonus_date', todayStr);
    await prefs.setString('last_streak_date', todayStr);
    await prefs.setInt('trainer_xp', _xp);
    await prefs.setInt('trainer_streak', _streak);
    notifyListeners();
  }
}