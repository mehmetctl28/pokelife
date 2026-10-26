import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';
import 'package:pokelife/core/providers/quest_provider.dart';
import 'package:pokelife/core/data/pokemon_data.dart';
import 'package:pokelife/core/data/gym_data.dart';
import 'package:pokelife/core/models/region.dart';
import 'package:pokelife/core/widgets/pokemon_sprite.dart';
import 'package:pokelife/features/battle/battle_engine.dart';

enum BattleMenuState { main, fight, bag, busy, finished }

class BattleScreen extends StatefulWidget {
  final int wildPokemonId;
  final int wildLevel;
  final bool isRare;
  final Region region;
  final GymLeader? gymLeader;

  const BattleScreen({
    super.key,
    required this.wildPokemonId,
    required this.wildLevel,
    required this.isRare,
    required this.region,
    this.gymLeader,
  });

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  final Random _rng = Random();

  bool get _isGymBattle => widget.gymLeader != null;
  int _currentGymRosterIndex = 0;
  int _earnedBadgeCount = 0;

  late int _partnerId;
  late String _partnerName;
  late String _partnerType;
  late int _partnerLevel;
  late int _partnerHearts;

  late int _currentEnemyPokemonId;
  late int _currentEnemyLevel;
  late String _wildName;
  late String _wildType;

  late int _playerMaxHp;
  late int _playerHp;
  late int _enemyMaxHp;
  late int _enemyHp;

  late List<BattleMove> _moves;
  int _healsRemaining = 2; // DÜZELTME (Madde 2.C): Savaş başına maksimum 2 Morning Sun hakkı

  BattleMenuState _menuState = BattleMenuState.busy;
  String _battleLog = '';

  // Görsel Animasyon Durumları
  bool _enemyHitFlash = false;
  bool _playerHitFlash = false;
  double _playerOffsetX = 0;
  double _enemyOffsetX = 0;

  // Yakalama ve Eşya Durumları
  bool _isShowingPokeball = false;
  int _pokeballShakeCount = 0;
  bool _razzBerryActive = false;
  int _razzBerriesLeft = 2;
  int _oranBerriesLeft = 2;

  @override
  void initState() {
    super.initState();
    _initBattleStats();
    _loadBadgesAndStartIntro();
  }

  void _initBattleStats() {
    final trainer = context.read<TrainerProvider>();
    final partner = trainer.activePartner;

    _partnerId = partner?.id ?? trainer.partnerId;
    _partnerName = PokemonData.getName(_partnerId).toUpperCase();
    _partnerType = PokemonData.getType(_partnerId);
    _partnerLevel = partner?.level ?? trainer.level;
    _partnerHearts = partner?.friendshipHearts ?? 1;

    _playerMaxHp = BattleEngine.calculatePlayerMaxHp(_partnerLevel);
    _playerHp = _playerMaxHp;

    _moves = BattleEngine.buildMovesForType(_partnerType);
    final healMove = _moves.where((m) => m.isHeal).firstOrNull;
    _healsRemaining = healMove?.maxUses ?? 2;

    if (_isGymBattle) {
      final firstPoke = widget.gymLeader!.team.first;
      _loadEnemyPokemon(firstPoke.id, firstPoke.level, isBoss: true);
    } else {
      _loadEnemyPokemon(widget.wildPokemonId, widget.wildLevel, isBoss: widget.isRare);
    }
  }

  void _loadEnemyPokemon(int pokeId, int level, {required bool isBoss}) {
    _currentEnemyPokemonId = pokeId;
    _currentEnemyLevel = level;
    _wildName = PokemonData.getName(pokeId).toUpperCase();
    _wildType = PokemonData.getType(pokeId);
    _enemyMaxHp = BattleEngine.calculateEnemyMaxHp(level, isRare: isBoss);
    _enemyHp = _enemyMaxHp;
  }

  Future<void> _loadBadgesAndStartIntro() async {
    final badges = await GymData.getEarnedBadges();
    if (!mounted) return;
    setState(() => _earnedBadgeCount = badges.length);

    if (_isGymBattle) {
      final leader = widget.gymLeader!;
      setState(() {
        _battleLog = '${leader.leaderName}: "${leader.introQuote}"';
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      setState(() {
        _battleLog =
            '${leader.title} ${leader.leaderName} sent out $_wildName (Lv.$_currentEnemyLevel)!';
      });
    } else {
      setState(() {
        _battleLog = widget.isRare
            ? '★ A rare wild $_wildName (Lv.$_currentEnemyLevel) appeared in ${widget.region.name}!'
            : 'A wild $_wildName (Lv.$_currentEnemyLevel) appeared in ${widget.region.name}!';
      });
    }

    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() {
      _battleLog = 'Go, $_partnerName! What will $_partnerName do?';
      _menuState = BattleMenuState.main;
    });
  }

  double get _catchProbability => BattleEngine.calculateCatchProbability(
        enemyHp: _enemyHp,
        enemyMaxHp: _enemyMaxHp,
        isRare: widget.isRare,
        razzBerryActive: _razzBerryActive,
        partnerHearts: _partnerHearts,
        badgeCount: _earnedBadgeCount,
      );

  Future<void> _executePlayerMove(BattleMove move) async {
    if (_menuState == BattleMenuState.busy) return;

    // DÜZELTME (Madde 2.C): Morning Sun kullanım sınırı kontrolü
    if (move.isHeal) {
      if (_healsRemaining <= 0) {
        setState(() {
          _battleLog = 'No uses left for ${move.name} in this battle!';
        });
        return;
      }
      if (_playerHp >= _playerMaxHp) {
        setState(() {
          _battleLog = '$_partnerName\'s HP is already full!';
        });
        return;
      }

      setState(() => _menuState = BattleMenuState.busy);
      final int healAmount = BattleEngine.calculateHealAmount(_playerMaxHp, 0.35);
      final int newHp = (_playerHp + healAmount).clamp(1, _playerMaxHp).toInt();
      final int actualRestored = newHp - _playerHp;

      setState(() {
        _healsRemaining--;
        _playerHp = newHp;
        _battleLog =
            '$_partnerName used ${move.name}! Restored $actualRestored HP! ($_healsRemaining left)';
      });
      await Future.delayed(const Duration(milliseconds: 1100));
      if (!mounted) return;
      await _executeEnemyTurn();
      return;
    }

    setState(() => _menuState = BattleMenuState.busy);

    // Saldırı Hamlesi Animasyonu
    setState(() {
      _battleLog = '$_partnerName used ${move.name}!';
      _playerOffsetX = 18;
    });
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() {
      _playerOffsetX = 0;
      _enemyHitFlash = true;
    });
    await Future.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    setState(() => _enemyHitFlash = false);

    // Gym savaşında False Swipe rakibi bayıltabilir (yakalama olmadığı için)
    final effectiveMove = _isGymBattle && move.isFalseSwipe
        ? BattleMove(
            name: move.name,
            type: move.type,
            power: move.power,
            isFalseSwipe: false,
            description: move.description,
          )
        : move;

    final outcome = BattleEngine.resolvePlayerAttack(
      move: effectiveMove,
      defenderType: _wildType,
      attackerLevel: _partnerLevel,
      defenderLevel: _currentEnemyLevel,
      currentEnemyHp: _enemyHp,
      maxEnemyHp: _enemyMaxHp,
      badgeCount: _earnedBadgeCount,
      randomBonus: _rng.nextInt(4),
    );

    setState(() {
      _enemyHp = outcome.remainingEnemyHp;
      if (outcome.isNoEffect) {
        _battleLog = "It doesn't affect $_wildName... (0 HP)";
      } else if (outcome.triggeredFalseSwipe) {
        _battleLog = '$_wildName held on with 1 HP! Catch chance is now 100%!';
      } else if (outcome.isSuperEffective) {
        _battleLog = "It's super effective! (-${outcome.damageDealt} HP)";
      } else if (outcome.isNotVeryEffective) {
        _battleLog = "It's not very effective... (-${outcome.damageDealt} HP)";
      } else {
        _battleLog = '$_wildName took ${outcome.damageDealt} damage!';
      }
    });

    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;

    if (outcome.isEnemyFainted) {
      await _handleEnemyFainted();
      return;
    }

    await _executeEnemyTurn();
  }

  Future<void> _executeEnemyTurn() async {
    if (!mounted) return;

    final enemyMoves = ['TACKLE', 'QUICK STRIKE', '${_wildType.toUpperCase()} RUSH'];
    final chosenMove = enemyMoves[_rng.nextInt(enemyMoves.length)];

    setState(() {
      _battleLog = '${_isGymBattle ? "Foe" : "Wild"} $_wildName used $chosenMove!';
      _enemyOffsetX = -18;
    });
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() {
      _enemyOffsetX = 0;
      _playerHitFlash = true;
    });
    await Future.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    setState(() => _playerHitFlash = false);

    final int dmg = BattleEngine.calculateEnemyDamage(
      wildLevel: _currentEnemyLevel,
      randomBonus: _rng.nextInt(5),
    );
    final int newPlayerHp = (_playerHp - dmg).clamp(0, _playerMaxHp).toInt();
    final int actualPlayerDmg = _playerHp - newPlayerHp;

    setState(() {
      _playerHp = newPlayerHp;
      _battleLog = '$_partnerName took $actualPlayerDmg damage!';
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    if (_playerHp <= 0) {
      setState(() {
        _battleLog = '$_partnerName is exhausted! You safely retreated to Camp.';
        _menuState = BattleMenuState.finished;
      });
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      Navigator.pop(context, '$_partnerName rested at Camp after the battle.');
      return;
    }

    setState(() {
      _battleLog = 'What will $_partnerName do?';
      _menuState = BattleMenuState.main;
    });
  }

  Future<void> _useBerry(bool isRazzBerry) async {
    if (_menuState == BattleMenuState.busy) return;
    setState(() => _menuState = BattleMenuState.busy);

    if (isRazzBerry) {
      setState(() {
        _razzBerriesLeft--;
        _razzBerryActive = true;
        _battleLog = 'Used RAZZ BERRY! Wild $_wildName is easier to catch!';
      });
    } else {
      final int heal = BattleEngine.calculateHealAmount(_playerMaxHp, 0.45);
      final int newHp = (_playerHp + heal).clamp(1, _playerMaxHp).toInt();
      final int actualRestored = newHp - _playerHp;
      setState(() {
        _oranBerriesLeft--;
        _playerHp = newHp;
        _battleLog = 'Fed ORAN BERRY to $_partnerName! Restored $actualRestored HP!';
      });
    }

    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    await _executeEnemyTurn();
  }

  Future<void> _throwPokeball() async {
    if (_menuState == BattleMenuState.busy) return;

    if (_isGymBattle) {
      setState(() {
        _battleLog =
            '${widget.gymLeader!.leaderName}: "Hey! You can\'t catch another Trainer\'s Pokémon!"';
      });
      return;
    }

    setState(() {
      _menuState = BattleMenuState.busy;
      _isShowingPokeball = true;
      _pokeballShakeCount = 0;
      _battleLog = 'You threw a POKÉBALL at $_wildName!';
    });

    final double chance = _catchProbability;
    final bool isCaught = _rng.nextDouble() <= chance;
    final int shakesToPerform = isCaught ? 3 : (1 + _rng.nextInt(2));

    for (int i = 1; i <= shakesToPerform; i++) {
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      setState(() {
        _pokeballShakeCount = i;
        _battleLog = 'Shake... $i...';
      });
    }

    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    if (isCaught) {
      final trainerProv = context.read<TrainerProvider>();
      final questProv = context.read<QuestProvider>();

      // DÜZELTME (Madde 2.D): XP tek bir yerde (BattleEngine.calculateCatchXp) hesaplanır
      final int xpGained = BattleEngine.calculateCatchXp(
        isNew: !trainerProv.caughtPokemonIds.contains(_currentEnemyPokemonId),
        isRare: widget.isRare,
        partnerHearts: _partnerHearts,
        enemyHp: _enemyHp,
        enemyMaxHp: _enemyMaxHp,
      );

      final bool isNew = await trainerProv.catchPokemon(
        _currentEnemyPokemonId,
        wildLevel: _currentEnemyLevel,
        location: widget.region.name,
      );

      await trainerProv.addXp(xpGained);
      if (isNew) {
        await questProv.addCatchProgress();
      }

      if (!mounted) return;
      setState(() {
        _battleLog = 'GOTCHA! $_wildName was caught! (+$xpGained XP)';
        _menuState = BattleMenuState.finished;
      });

      await Future.delayed(const Duration(milliseconds: 1300));
      if (!mounted) return;

      final String resultBanner = isNew
          ? '★ NEW DEX ENTRY! $_wildName (Lv.$_currentEnemyLevel) caught! +$xpGained XP'
          : 'CAUGHT $_wildName! +$xpGained XP';

      // DÜZELTME (Madde 2.B): SnackBar burada değil, mesaj döndürülerek WalkScreen'de gösterilir!
      Navigator.pop(context, resultBanner);
    } else {
      setState(() {
        _isShowingPokeball = false;
        _razzBerryActive = false;
        _battleLog = 'Oh no! Wild $_wildName broke free! Weaken its HP more!';
      });
      await Future.delayed(const Duration(milliseconds: 1100));
      if (!mounted) return;
      await _executeEnemyTurn();
    }
  }

  Future<void> _handleEnemyFainted() async {
    if (_isGymBattle) {
      final leader = widget.gymLeader!;
      if (_currentGymRosterIndex + 1 < leader.team.length) {
        setState(() {
          _battleLog = 'Foe $_wildName fainted!';
        });
        await Future.delayed(const Duration(milliseconds: 1100));
        if (!mounted) return;

        _currentGymRosterIndex++;
        final nextPoke = leader.team[_currentGymRosterIndex];
        setState(() {
          _loadEnemyPokemon(nextPoke.id, nextPoke.level, isBoss: true);
          _battleLog =
              '${leader.leaderName} sent out $_wildName (Lv.$_currentEnemyLevel)!';
        });

        await Future.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;
        setState(() {
          _battleLog = 'What will $_partnerName do?';
          _menuState = BattleMenuState.main;
        });
        return;
      }

      // DÜZELTME (Madde 3.1): İlk zaferde tam ödül + rozet; tekrar savaşında (rematch) 0 XP (sonsuz XP farm engeli)
      final trainerProv = context.read<TrainerProvider>();
      final bool isFirstTimeBadge = await GymData.unlockBadge(leader.badgeId);
      final int rewardXp = isFirstTimeBadge ? leader.rewardXp : 0;

      if (rewardXp > 0) {
        await trainerProv.addXp(rewardXp);
      }

      if (!mounted) return;
      setState(() {
        _battleLog = isFirstTimeBadge
            ? '${leader.leaderName}: "${leader.defeatQuote}" (+$rewardXp XP)'
            : '${leader.leaderName}: "${leader.defeatQuote}" (Rematch Victory!)';
        _menuState = BattleMenuState.finished;
      });

      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;

      final String gymResultBanner = isFirstTimeBadge
          ? '${leader.badgeEmoji} OBTAINED ${leader.badgeName.toUpperCase()}! (${leader.perkDescription}) +$rewardXp XP'
          : '${leader.badgeEmoji} REMATCH VICTORY AGAINST ${leader.leaderName}! (Badge already earned)';

      Navigator.pop(context, gymResultBanner);
      return;
    }

    // Normal Vahşi Pokémon Bayılması
    final trainerProv = context.read<TrainerProvider>();
    final int victoryXp = BattleEngine.calculateVictoryXp(
      isRare: widget.isRare,
      partnerHearts: _partnerHearts,
    );
    await trainerProv.addXp(victoryXp);

    if (!mounted) return;
    setState(() {
      _battleLog = 'Wild $_wildName fainted! $_partnerName gained +$victoryXp Battle XP!';
      _menuState = BattleMenuState.finished;
    });

    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    Navigator.pop(
      context,
      'VICTORY! Defeated wild $_wildName! +$victoryXp XP (Tip: Use FALSE SWIPE to catch safely)',
    );
  }

  Color _getHpColor(double ratio) {
    if (ratio > 0.5) return AppColors.green;
    if (ratio > 0.2) return AppColors.yellow;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final int catchPct = (_catchProbability * 100).round();

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.darkBlue,
                border: Border(
                  bottom: BorderSide(
                    color: _isGymBattle ? AppColors.yellow : AppColors.blue,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(_isGymBattle ? '🏅 ' : '⚔️ ', style: const TextStyle(fontSize: 12)),
                      Text(
                        _isGymBattle
                            ? '${widget.gymLeader!.title.toUpperCase()} ${widget.gymLeader!.leaderName}'
                            : widget.region.name.toUpperCase(),
                        style: TextStyle(
                          color: _isGymBattle ? AppColors.yellow : AppColors.cream,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_isGymBattle)
                    Row(
                      children: List.generate(widget.gymLeader!.team.length, (idx) {
                        final bool isAlive = idx >= _currentGymRosterIndex;
                        return Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            isAlive ? '🔴' : '⚫',
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        border: Border.all(
                          color: catchPct >= 80 ? AppColors.green : AppColors.yellow,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'CATCH RATE: $catchPct%',
                        style: TextStyle(
                          color: catchPct >= 80 ? AppColors.green : AppColors.yellow,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // DSi ÜST EKRAN: SAVAŞ ARENASI
            Expanded(
              flex: 6,
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _isGymBattle
                          ? AppColors.yellow.withValues(alpha: 0.18)
                          : (widget.isRare
                              ? AppColors.purple.withValues(alpha: 0.25)
                              : AppColors.darkBlue),
                      AppColors.navy,
                    ],
                  ),
                  border: Border.all(
                    color: _isGymBattle || widget.isRare ? AppColors.yellow : AppColors.cream,
                    width: 2.5,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.08,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            12,
                            (_) => Container(height: 2, color: AppColors.cream),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: _buildEnemyHud(),
                    ),
                    Positioned(
                      top: 28,
                      right: 22,
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            transform: Matrix4.translationValues(_enemyOffsetX, 0, 0),
                            child: Opacity(
                              opacity: _enemyHitFlash ? 0.25 : 1.0,
                              child: _isShowingPokeball
                                  ? _buildPokeballAnimation()
                                  : PokemonSprite(pokemonId: _currentEnemyPokemonId, size: 88),
                            ),
                          ),
                          Container(
                            width: 104,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.darkBlue,
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: _isGymBattle || widget.isRare
                                    ? AppColors.yellow
                                    : AppColors.blue,
                                width: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 18,
                      left: 22,
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            transform: Matrix4.translationValues(_playerOffsetX, 0, 0),
                            child: Opacity(
                              opacity: _playerHitFlash ? 0.25 : 1.0,
                              child: Transform.scale(
                                scaleX: -1,
                                child: PokemonSprite(pokemonId: _partnerId, size: 92),
                              ),
                            ),
                          ),
                          Container(
                            width: 112,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.darkBlue,
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(color: AppColors.green, width: 2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      right: 14,
                      child: _buildPlayerHud(),
                    ),
                  ],
                ),
              ),
            ),

            // DSi ALT EKRAN: DİYALOG KUTUSU + DOKUNMATİK KOMUT GÜVERTESİ
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 58),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.darkBlue,
                        border: Border.all(color: AppColors.cream, width: 2),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('▶ ', style: TextStyle(color: AppColors.yellow, fontSize: 10)),
                          Expanded(
                            child: Text(
                              _battleLog,
                              style: const TextStyle(
                                color: AppColors.cream,
                                fontSize: 9.5,
                                height: 1.35,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _buildBottomCommandDeck(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnemyHud() {
    // DÜZELTME (Madde 2.A): .toDouble() ile tip güvenli
    final double ratio = (_enemyHp / _enemyMaxHp).clamp(0.0, 1.0).toDouble();
    return Container(
      width: 175,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.92),
        border: Border.all(
          color: _isGymBattle || widget.isRare ? AppColors.yellow : AppColors.cream,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  _isGymBattle
                      ? '👑 $_wildName'
                      : (widget.isRare ? '★ $_wildName' : _wildName),
                  style: TextStyle(
                    color: _isGymBattle || widget.isRare ? AppColors.yellow : AppColors.cream,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Lv.$_currentEnemyLevel',
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                color: AppColors.darkBlue,
                child: Text(
                  _wildType.toUpperCase(),
                  style: const TextStyle(color: AppColors.blue, fontSize: 7),
                ),
              ),
              if (_razzBerryActive) ...[
                const SizedBox(width: 4),
                const Text('🍓+20%', style: TextStyle(color: AppColors.yellow, fontSize: 7)),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                'HP ',
                style: TextStyle(
                  color: AppColors.yellow,
                  fontSize: 7.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.darkBlue,
                    border: Border.all(color: AppColors.cream, width: 1),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: ratio,
                    child: Container(color: _getHpColor(ratio)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$_enemyHp / $_enemyMaxHp',
              style: const TextStyle(color: AppColors.cream, fontSize: 7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerHud() {
    // DÜZELTME (Madde 2.A): .toDouble() ile tip güvenli
    final double ratio = (_playerHp / _playerMaxHp).clamp(0.0, 1.0).toDouble();
    return Container(
      width: 180,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.92),
        border: Border.all(color: AppColors.cream, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  _partnerName,
                  style: const TextStyle(
                    color: AppColors.cream,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Lv.$_partnerLevel',
                style: const TextStyle(
                  color: AppColors.yellow,
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                'HP ',
                style: TextStyle(
                  color: AppColors.yellow,
                  fontSize: 7.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.darkBlue,
                    border: Border.all(color: AppColors.cream, width: 1),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: ratio,
                    child: Container(color: _getHpColor(ratio)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('❤️' * _partnerHearts, style: const TextStyle(fontSize: 7)),
                  if (_earnedBadgeCount > 0)
                    Text(
                      ' +${_earnedBadgeCount * 5}%⚔️',
                      style: const TextStyle(
                        color: AppColors.yellow,
                        fontSize: 6.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              Text(
                '$_playerHp / $_playerMaxHp',
                style: const TextStyle(
                  color: AppColors.cream,
                  fontSize: 7.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPokeballAnimation() {
    return SizedBox(
      width: 88,
      height: 88,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.rotate(
            angle: _pokeballShakeCount == 0
                ? 0
                : (_pokeballShakeCount.isOdd ? -0.25 : 0.25),
            child: const Text('🔴', style: TextStyle(fontSize: 34)),
          ),
          const SizedBox(height: 6),
          Text(
            _pokeballShakeCount == 0 ? 'THROWING...' : 'SHAKE $_pokeballShakeCount/3',
            style: const TextStyle(
              color: AppColors.yellow,
              fontSize: 7.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCommandDeck() {
    if (_menuState == BattleMenuState.busy || _menuState == BattleMenuState.finished) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.darkBlue,
          border: Border.all(color: AppColors.blue, width: 2),
        ),
        child: const Center(
          child: Text(
            '⏳ BATTLE IN PROGRESS...',
            style: TextStyle(color: AppColors.yellow, fontSize: 9, letterSpacing: 1.2),
          ),
        ),
      );
    }

    if (_menuState == BattleMenuState.fight) {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildMoveButton(_moves[0])),
                const SizedBox(width: 8),
                Expanded(child: _buildMoveButton(_moves[1])),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildMoveButton(_moves[2])),
                const SizedBox(width: 8),
                Expanded(child: _buildMoveButton(_moves[3])),
              ],
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _menuState = BattleMenuState.main),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.navy,
                border: Border.all(color: AppColors.blue, width: 1.5),
              ),
              child: const Center(
                child: Text(
                  '◀ BACK TO COMMANDS',
                  style: TextStyle(color: AppColors.cream, fontSize: 8),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_menuState == BattleMenuState.bag) {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildBagItemButton(
                    title: '🍓 RAZZ BERRY ($_razzBerriesLeft)',
                    subtitle: _isGymBattle ? 'Wild Battles Only' : '+20% Catch Rate',
                    color: AppColors.purple,
                    enabled: !_isGymBattle && _razzBerriesLeft > 0 && !_razzBerryActive,
                    onTap: () => _useBerry(true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBagItemButton(
                    title: '🍊 ORAN BERRY ($_oranBerriesLeft)',
                    subtitle: 'Heal 45% Partner HP',
                    color: AppColors.green,
                    enabled: _oranBerriesLeft > 0 && _playerHp < _playerMaxHp,
                    onTap: () => _useBerry(false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _menuState = BattleMenuState.main),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.navy,
                border: Border.all(color: AppColors.blue, width: 1.5),
              ),
              child: const Center(
                child: Text(
                  '◀ BACK TO COMMANDS',
                  style: TextStyle(color: AppColors.cream, fontSize: 8),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final int catchPct = (_catchProbability * 100).round();
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildMainActionTile(
                  icon: '⚔️',
                  label: 'FIGHT',
                  sub: _isGymBattle ? 'Defeat Leader' : 'Weaken Foe',
                  borderColor: Colors.redAccent,
                  fillColor: Colors.redAccent.withValues(alpha: 0.18),
                  onTap: () => setState(() => _menuState = BattleMenuState.fight),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMainActionTile(
                  icon: _isGymBattle ? '🚫' : '🔴',
                  label: _isGymBattle ? 'NO CATCH' : 'POKÉBALL',
                  sub: _isGymBattle ? 'Gym Locked' : '$catchPct% Chance',
                  borderColor: _isGymBattle ? AppColors.blue : AppColors.green,
                  fillColor: _isGymBattle
                      ? AppColors.navy
                      : AppColors.green.withValues(alpha: 0.22),
                  onTap: _throwPokeball,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildMainActionTile(
                  icon: '🎒',
                  label: 'BAG / BERRY',
                  sub: '${_razzBerriesLeft + _oranBerriesLeft} Items Left',
                  borderColor: AppColors.yellow,
                  fillColor: AppColors.yellow.withValues(alpha: 0.15),
                  onTap: () => setState(() => _menuState = BattleMenuState.bag),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMainActionTile(
                  icon: '🏃',
                  label: _isGymBattle ? 'FORFEIT' : 'RUN AWAY',
                  sub: 'Safe Escape',
                  borderColor: AppColors.blue,
                  fillColor: AppColors.darkBlue,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainActionTile({
    required String icon,
    required String label,
    required String sub,
    required Color borderColor,
    required Color fillColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: fillColor,
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.cream,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: TextStyle(
                      color: borderColor,
                      fontSize: 7.5,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoveButton(BattleMove move) {
    final bool isFalseSwipe = move.isFalseSwipe && !_isGymBattle;
    final bool isDisabledHeal = move.isHeal && _healsRemaining <= 0;
    final Color borderCol = isDisabledHeal
        ? AppColors.blue
        : (isFalseSwipe
            ? AppColors.yellow
            : (move.isHeal ? AppColors.green : AppColors.cream));

    return GestureDetector(
      onTap: isDisabledHeal ? null : () => _executePlayerMove(move),
      child: Opacity(
        opacity: isDisabledHeal ? 0.45 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.darkBlue,
            border: Border.all(color: borderCol, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      move.name,
                      style: TextStyle(
                        color: borderCol,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    move.isHeal
                        ? 'HEAL ($_healsRemaining/${move.maxUses ?? 2})'
                        : 'PWR ${move.power}',
                    style: const TextStyle(color: AppColors.blue, fontSize: 7),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                move.description,
                style: const TextStyle(color: AppColors.cream, fontSize: 6.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBagItemButton({
    required String title,
    required String subtitle,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.darkBlue,
            border: Border.all(color: color, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.cream, fontSize: 7),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}