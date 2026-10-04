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

  // YENİ: Donanımın son bildirdiği toplam adım (Uygulama kapalıyken atılanları bulmak için)
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
    
    // YENİ: Diske kaydedilen son donanım adımı verisini yükle
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

  // Tarih ve Seri Kontrolü Tek Merkezde
  void _handleDateChanges(SharedPreferences prefs) {
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];

    // Gün değiştiyse günlük adımları sıfırla
    if (_lastStepDate.isNotEmpty && _lastStepDate != todayStr) {
      _dailySteps = 0;
      _lastStepDate = todayStr;
      prefs.setInt('trainer_daily_steps', 0);
      prefs.setString('last_step_date', todayStr);
    } else if (_lastStepDate.isEmpty) {
      _lastStepDate = todayStr;
      prefs.setString('last_step_date', todayStr);
    }

    // Seri (Streak) bozulma kontrolü
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
  }

  // YENİ: UYGULAMA KAPALIYKEN ATILAN ADIMLARI HESAPLAYAN FONKSİYON
  void processHardwareStep(int hardwareStep) async {
    final prefs = await SharedPreferences.getInstance();

    if (_lastSystemStep == 0) {
      _lastSystemStep = hardwareStep;
      await prefs.setInt('last_system_step', _lastSystemStep);
      return;
    }

    // Eğer telefon yeniden başlatıldıysa donanım sayacı 0'lanır.
    if (hardwareStep < _lastSystemStep) {
      _lastSystemStep = hardwareStep;
      await prefs.setInt('last_system_step', _lastSystemStep);
      return;
    }

    // Uygulama kapalıyken (veya açıkken) atılan farkı bul
    int delta = hardwareStep - _lastSystemStep;
    if (delta > 0) {
      _lastSystemStep = hardwareStep;
      await prefs.setInt('last_system_step', _lastSystemStep);
      addSteps(delta); // Aradaki farkı normal adım ekleme sistemine yolla
    }
  }

  // Atlanan Eşikleri Doğru Hesaplama Modülü
  void addSteps(int delta) async {
    if (delta <= 0) return;
    
    final prefs = await SharedPreferences.getInstance();
    _handleDateChanges(prefs); 

    int oldDaily = _dailySteps;
    _steps += delta;
    _dailySteps += delta;
    
    // Modulo (%) yerine tam sayı bölmesi ile kesin eşik tespiti
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

  // Tekrar Yakalama İstismarını Engelleme Modülü
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
      return true; // Yeni keşif
    }
    return false; // Zaten koleksiyonda var
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
        _streak = 1; // Dün girmediyse seri 1'den başlar
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