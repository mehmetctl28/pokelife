import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokelife/core/models/quest.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';

class QuestProvider extends ChangeNotifier {
  List<Quest> _dailyQuests = [];
  String _lastQuestDate = "";

  List<Quest> get dailyQuests => _dailyQuests;

  QuestProvider() {
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    final prefs = await SharedPreferences.getInstance();
    _lastQuestDate = prefs.getString('last_quest_date') ?? "";
    
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (_lastQuestDate != today) {
      _generateDailyQuests();
      _lastQuestDate = today;
      await prefs.setString('last_quest_date', today);
    } else {
      final questsJson = prefs.getStringList('daily_quests');
      if (questsJson != null) {
        _dailyQuests = questsJson.map((e) => Quest.fromMap(json.decode(e))).toList();
      } else {
        _generateDailyQuests();
      }
    }
    notifyListeners();
  }

  void _generateDailyQuests() {
    _dailyQuests = [
      Quest(id: 'q1', title: 'First Steps (1,000)', target: 1000, rewardXp: 20, type: 'step'),
      Quest(id: 'q2', title: 'Explorer (3,000)', target: 3000, rewardXp: 50, type: 'step'),
      Quest(id: 'q3', title: 'Catch 1 Wild Pokémon', target: 1, rewardXp: 30, type: 'catch'),
    ];
    _saveQuests();
  }

  Future<void> _saveQuests() async {
    final prefs = await SharedPreferences.getInstance();
    final questsJson = _dailyQuests.map((q) => json.encode(q.toMap())).toList();
    await prefs.setStringList('daily_quests', questsJson);
  }

  void updateStepProgress(int totalDailySteps) {
    bool changed = false;
    for (var q in _dailyQuests.where((q) => q.type == 'step' && !q.isClaimed)) {
      if (q.progress != totalDailySteps) {
         q.progress = totalDailySteps;
         changed = true;
      }
    }
    if (changed) {
      _saveQuests();
      notifyListeners();
    }
  }

  void addCatchProgress() {
    bool changed = false;
    for (var q in _dailyQuests.where((q) => q.type == 'catch' && !q.isClaimed)) {
      q.progress += 1;
      changed = true;
    }
    if (changed) {
      _saveQuests();
      notifyListeners();
    }
  }

  // YENİ: TrainerProvider'ı içeri alıyoruz. İşlemler artık kilitli ve tek seferlik!
  bool claimReward(String questId, TrainerProvider trainer) {
    final questIndex = _dailyQuests.indexWhere((q) => q.id == questId);
    if (questIndex != -1) {
      final q = _dailyQuests[questIndex];
      // Eğer görev bittiyse ve henüz alınmadıysa işlemi başlat
      if (q.progress >= q.target && !q.isClaimed) {
        // 1. Önce kilitliyoruz (Double-tap hilesini engeller)
        q.isClaimed = true; 
        
        // 2. XP'yi Trainer'a aktarıyoruz
        trainer.addXp(q.rewardXp);
        
        // 3. Görevin alındığını diske kaydediyoruz
        _saveQuests();
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  // YENİ: TrainerProvider "Gün değişti" dediğinde bunu çağırıp görevleri sıfırlayacak
  void forceResetQuestsForNewDay() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (_lastQuestDate != today) {
      _generateDailyQuests();
      _lastQuestDate = today;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_quest_date', today);
      notifyListeners();
    }
  }
}