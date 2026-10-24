import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokelife/core/models/quest.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';

class QuestProvider extends ChangeNotifier {
  static const String _questsPrefsKey = 'daily_quests_data';
  static const String _resetDatePrefsKey = 'quests_last_reset_date';
  static const String _claimedLedgerKey = 'claimed_quest_ledger';

  List<Quest> _quests = [];
  String _lastResetDate = '';
  final Set<String> _claimingInProgress = {};
  Set<String> _claimedLedger = {};

  List<Quest> get quests => _quests;

  bool get allQuestsClaimed =>
      _quests.isNotEmpty && _quests.every((q) => q.isClaimed);

  QuestProvider() {
    _initDefaultQuests();
    _loadQuests();
  }

  void _initDefaultQuests() {
    _quests = [
      Quest(
        id: 'daily_walk_1000',
        title: 'Walk 1,000 Steps',
        target: 1000,
        current: 0,
        rewardXp: 25,
        isClaimed: false,
      ),
      Quest(
        id: 'daily_walk_5000',
        title: 'Walk 5,000 Steps',
        target: 5000,
        current: 0,
        rewardXp: 60,
        isClaimed: false,
      ),
      Quest(
        id: 'daily_catch_1',
        title: 'Catch a New Pokémon Species',
        target: 1,
        current: 0,
        rewardXp: 50,
        isClaimed: false,
      ),
    ];
  }

  String _todayString() => DateTime.now().toIso8601String().split('T')[0];

  String _buildLedgerId(String questId) => '${_lastResetDate}_$questId';

  Future<void> _loadQuests() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    _lastResetDate = prefs.getString(_resetDatePrefsKey) ?? '';
    _claimedLedger = (prefs.getStringList(_claimedLedgerKey) ?? <String>[]).toSet();

    if (_lastResetDate != today) {
      await forceResetQuestsForNewDay();
      return;
    }

    final savedJson = prefs.getStringList(_questsPrefsKey);
    if (savedJson != null && savedJson.isNotEmpty) {
      _quests = savedJson.map((str) => Quest.fromMap(json.decode(str))).toList();
      // Ledger'da kayıtlı olan görevlerin isClaimed durumunu senkronize et
      for (final q in _quests) {
        if (_claimedLedger.contains(_buildLedgerId(q.id))) {
          q.isClaimed = true;
        }
      }
      notifyListeners();
    } else {
      await _saveQuests(prefs);
    }
  }

  Future<void> forceResetQuestsForNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    _lastResetDate = _todayString();
    _claimedLedger.clear();
    _initDefaultQuests();

    await prefs.setString(_resetDatePrefsKey, _lastResetDate);
    await prefs.setStringList(_claimedLedgerKey, <String>[]);
    await _saveQuests(prefs);
    notifyListeners();
  }

  Future<void> _saveQuests(SharedPreferences prefs) async {
    final encoded = _quests.map((q) => json.encode(q.toMap())).toList();
    await prefs.setStringList(_questsPrefsKey, encoded);
  }

  void updateStepProgress(int dailySteps) async {
    bool changed = false;
    for (var q in _quests) {
      if (q.id.startsWith('daily_walk_')) {
        final int clamped = dailySteps.clamp(0, q.target).toInt();
        if (q.current != clamped) {
          q.current = clamped;
          changed = true;
        }
      }
    }
    if (changed) {
      final prefs = await SharedPreferences.getInstance();
      await _saveQuests(prefs);
      notifyListeners();
    }
  }

  void addCatchProgress() async {
    bool changed = false;
    for (var q in _quests) {
      if (q.id == 'daily_catch_1' && q.current < q.target) {
        q.current = (q.current + 1).clamp(0, q.target).toInt();
        changed = true;
      }
    }
    if (changed) {
      final prefs = await SharedPreferences.getInstance();
      await _saveQuests(prefs);
      notifyListeners();
    }
  }

  /// DÜZELTME (Madde 6): Atomik ve İdempotent Ödül Talebi
  /// Aynı gün içinde aynı görev ID'si için XP ödülünün iki kez verilmesini %100 engeller.
  Future<bool> claimReward(String questId, TrainerProvider trainer) async {
    if (_claimingInProgress.contains(questId)) return false;

    final index = _quests.indexWhere((q) => q.id == questId);
    if (index == -1) return false;

    final quest = _quests[index];
    if (!quest.isCompleted || quest.isClaimed) return false;

    if (_lastResetDate.isEmpty) {
      _lastResetDate = _todayString();
    }
    final ledgerId = _buildLedgerId(questId);

    // Eğer bu görev bugün zaten ledger'a işlendiyse tekrar XP verme!
    if (_claimedLedger.contains(ledgerId)) {
      quest.isClaimed = true;
      notifyListeners();
      return false;
    }

    _claimingInProgress.add(questId);
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Önce kalıcı olarak talep durumunu ve ledger kaydını yaz
      quest.isClaimed = true;
      _claimedLedger.add(ledgerId);
      await prefs.setStringList(_claimedLedgerKey, _claimedLedger.toList());
      await _saveQuests(prefs);

      // 2. Ardından XP ödülünü ver
      await trainer.addXp(quest.rewardXp);

      notifyListeners();
      return true;
    } catch (_) {
      return false;
    } finally {
      _claimingInProgress.remove(questId);
    }
  }
}