import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';
import 'package:pokelife/core/providers/quest_provider.dart';
import 'package:pokelife/core/data/world_data.dart';
import 'package:pokelife/core/data/gym_data.dart';
import 'package:pokelife/core/models/region.dart';
import 'package:pokelife/core/constants/game_constants.dart';
import 'package:pokelife/features/battle/battle_screen.dart';

class WalkScreen extends StatefulWidget {
  const WalkScreen({super.key});

  @override
  State<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends State<WalkScreen> with WidgetsBindingObserver {
  StreamSubscription<StepCount>? _stepCountStreamSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusStreamSubscription;

  final Random _rng = Random();
  String _status = 'STOPPED';
  bool isSearching = false;
  bool _permissionGranted = false;
  bool _permissionPermanentlyDenied = false;
  String? _sensorError;
  List<String> _earnedBadges = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissionAndInit();
    _refreshBadges();
  }

  Future<void> _refreshBadges() async {
    final badges = await GymData.getEarnedBadges();
    if (mounted) {
      setState(() => _earnedBadges = badges);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPedometer();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_permissionGranted) {
        _initPedometer();
      } else {
        _checkPermissionStatusOnly();
      }
    } else if (state == AppLifecycleState.paused) {
      _stopPedometer();
    }
  }

  Future<void> _checkPermissionStatusOnly() async {
    final status = await Permission.activityRecognition.status;
    if (!mounted) return;
    if (status.isGranted) {
      setState(() {
        _permissionGranted = true;
        _permissionPermanentlyDenied = false;
      });
      _initPedometer();
    }
  }

  Future<void> _requestPermissionAndInit() async {
    final status = await Permission.activityRecognition.request();
    if (!mounted) return;

    if (status.isGranted) {
      setState(() {
        _permissionGranted = true;
        _permissionPermanentlyDenied = false;
        _sensorError = null;
      });
      _initPedometer();
    } else {
      setState(() {
        _permissionGranted = false;
        _permissionPermanentlyDenied = status.isPermanentlyDenied;
      });
    }
  }

  void _initPedometer() {
    _stopPedometer();
    _pedestrianStatusStreamSubscription = Pedometer.pedestrianStatusStream.listen(
      onPedestrianStatusChanged,
      onError: (e) {
        if (mounted) setState(() => _status = 'IDLE');
      },
    );

    _stepCountStreamSubscription = Pedometer.stepCountStream.listen(
      onStepCount,
      onError: (e) {
        if (mounted) {
          setState(() => _sensorError = 'Step sensor unavailable on this device.');
        }
      },
    );
  }

  void _stopPedometer() {
    _stepCountStreamSubscription?.cancel();
    _pedestrianStatusStreamSubscription?.cancel();
  }

  void onStepCount(StepCount event) async {
    if (!mounted) return;
    final trainer = context.read<TrainerProvider>();
    final questProv = context.read<QuestProvider>();
    await trainer.processHardwareStep(event.steps, questProv);
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    if (mounted) setState(() => _status = event.status);
  }

void _triggerEncounter(bool isRare, Region currentRegion) {
    if (isSearching) return;
    final trainer = context.read<TrainerProvider>();

    final bool consumed = isRare
        ? trainer.tryConsumeRareSearch()
        : trainer.tryConsumeNormalSearch();

    if (!consumed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No search charges available! Walk more steps to recharge.',
            style: TextStyle(fontSize: 9, color: AppColors.cream),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => isSearching = true);

    Future.delayed(const Duration(milliseconds: 900), () async {
      if (!mounted) return;
      setState(() => isSearching = false);

      final bool effectiveRare =
          isRare || (trainer.hasScoutBondSynergy && _rng.nextDouble() < 0.15);

      final int pokeId = currentRegion.getRandomPokemonId(isRare: effectiveRare);
      final int wildLevel = currentRegion.getWildLevel(isRare: effectiveRare);

      // DÜZELTME (Madde 2.B): Savaş ekranından dönen sonuç mesajı parent ekranda gösterilir
      final String? battleBanner = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => BattleScreen(
            wildPokemonId: pokeId,
            wildLevel: wildLevel,
            isRare: effectiveRare,
            region: currentRegion,
          ),
        ),
      );

      if (!mounted || battleBanner == null || battleBanner.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            battleBanner,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.navy,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppColors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  Future<void> _challengeGymLeader(Region currentRegion, GymLeader leader) async {
    final String? gymBanner = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => BattleScreen(
          wildPokemonId: leader.team.first.id,
          wildLevel: leader.team.first.level,
          isRare: true,
          region: currentRegion,
          gymLeader: leader,
        ),
      ),
    );
    await _refreshBadges();
    if (!mounted || gymBanner == null || gymBanner.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          gymBanner,
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.yellow,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showRegionSelector(BuildContext context, TrainerProvider trainer) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.darkBlue,
        shape: Border.all(color: AppColors.cream, width: 2),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MAP TRAVEL',
                    style: TextStyle(
                      color: AppColors.yellow,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Icon(Icons.map, color: AppColors.yellow, size: 16),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Select an unlocked region to explore:',
                style: TextStyle(color: AppColors.blue, fontSize: 8),
              ),
              const Divider(color: AppColors.navy, height: 16),
              ...WorldData.regions.map((region) {
                final bool isUnlocked = trainer.steps >= region.unlockSteps;
                final bool isSelected = trainer.currentRegion.id == region.id;

                return GestureDetector(
                  onTap: isUnlocked
                      ? () {
                          trainer.selectRegion(region.id);
                          Navigator.pop(ctx);
                        }
                      : null,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.navy : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.green
                            : (isUnlocked ? AppColors.blue : AppColors.navy),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isUnlocked
                                  ? (isSelected ? Icons.check_circle : Icons.circle_outlined)
                                  : Icons.lock,
                              color: isSelected
                                  ? AppColors.green
                                  : (isUnlocked ? AppColors.cream : AppColors.blue),
                              size: 14,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  region.name.toUpperCase(),
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.green
                                        : (isUnlocked ? AppColors.cream : AppColors.blue),
                                    fontSize: 9,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                if (!isUnlocked)
                                  Text(
                                    'Unlocks at ${region.unlockSteps} steps',
                                    style: const TextStyle(color: AppColors.blue, fontSize: 7),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        if (isSelected)
                          const Text(
                            'CURRENT',
                            style: TextStyle(
                              color: AppColors.green,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trainer = context.watch<TrainerProvider>();
    final dailySteps = trainer.dailySteps;
    final currentRegion = trainer.currentRegion;
    final bool isCamping = _status.toLowerCase() == 'stopped';
    final bool canGetMilestone = dailySteps >= GameConstants.dailyFirstMilestone;

    final int normalSearches = trainer.availableNormalSearches;
    final int rareSearches = trainer.availableRareSearches;
    final bool canSearchNormal = normalSearches > 0;
    final bool canSearchRare = rareSearches > 0;

    final GymLeader regionLeader = GymData.getLeaderForRegion(
      currentRegion.id,
      currentRegion.name,
    );
    final bool hasRegionBadge = _earnedBadges.contains(regionLeader.badgeId);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCamping ? '🏕️ CAMP RESTING' : '📍 ACTIVE AREA',
                style: TextStyle(
                  color: isCamping ? Colors.orangeAccent : AppColors.yellow,
                  fontSize: 10,
                ),
              ),
              Text(
                'STATUS: ${_status.toUpperCase()}',
                style: TextStyle(
                  color: _status.toLowerCase() == 'walking' ? AppColors.green : AppColors.blue,
                  fontSize: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // WORLD PROGRESS (Lifetime Adım & Bölge İlerleme Bilgisi)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.navy,
              border: Border.all(color: AppColors.blue, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('🗺️ ', style: TextStyle(fontSize: 12)),
                    Text(
                      'WORLD PROGRESS',
                      style: TextStyle(
                        color: AppColors.yellow,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${trainer.steps} TOTAL STEPS',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // KANTO GYM BADGE CASE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.darkBlue,
              border: Border.all(color: AppColors.yellow, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🏅 GYM BADGE CASE',
                      style: TextStyle(
                        color: AppColors.yellow,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _earnedBadges.isEmpty
                          ? 'NO BADGES YET'
                          : '+${_earnedBadges.length * 5}% DMG | +${_earnedBadges.length * 3}% CATCH',
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: GymData.leaders.map((leader) {
                    final bool unlocked = _earnedBadges.contains(leader.badgeId);
                    return Opacity(
                      opacity: unlocked ? 1.0 : 0.3,
                      child: Column(
                        children: [
                          Text(leader.badgeEmoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(
                            leader.leaderName,
                            style: TextStyle(
                              color: unlocked ? AppColors.cream : AppColors.blue,
                              fontSize: 6.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () => _showRegionSelector(context, trainer),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkBlue,
                border: Border.all(
                  color: isCamping ? Colors.orangeAccent : AppColors.cream,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isCamping ? '🔥' : '🌍', style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          isCamping ? 'RESTING AT CAMP (Idle)' : currentRegion.name.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.cream,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.swap_horiz, color: AppColors.yellow, size: 16),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tap to switch region • Lifetime progress unlocks areas.',
                    style: TextStyle(color: AppColors.blue, fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // GYM LEADER BOSS CHALLENGE KARTI
          GestureDetector(
            onTap: () => _challengeGymLeader(currentRegion, regionLeader),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.navy,
                border: Border.all(
                  color: hasRegionBadge ? AppColors.green : AppColors.yellow,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasRegionBadge
                              ? '${regionLeader.badgeEmoji} ${regionLeader.badgeName.toUpperCase()} EARNED'
                              : '👑 GYM BOSS: ${regionLeader.leaderName} (${regionLeader.title})',
                          style: TextStyle(
                            color: hasRegionBadge ? AppColors.green : AppColors.yellow,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasRegionBadge
                              ? 'Tap for a rematch! (+${regionLeader.rewardXp ~/ 2} XP)'
                              : 'Defeat ${regionLeader.leaderName} to earn ${regionLeader.badgeName} (${regionLeader.perkDescription})',
                          style: const TextStyle(color: AppColors.cream, fontSize: 7.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: hasRegionBadge ? AppColors.darkBlue : AppColors.yellow,
                      border: Border.all(color: AppColors.cream, width: 1),
                    ),
                    child: Text(
                      hasRegionBadge ? 'REMATCH' : 'BATTLE',
                      style: TextStyle(
                        color: hasRegionBadge ? AppColors.cream : AppColors.navy,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // DÜZELTME: İzin reddedildiğinde TRY AGAIN ve OPEN SETTINGS kurtarma butonları
          if (!_permissionGranted)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.navy,
                border: Border.all(color: Colors.redAccent, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️ MOTION PERMISSION REQUIRED TO TRACK STEPS.',
                    style: TextStyle(
                      color: AppColors.yellow,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _permissionPermanentlyDenied
                        ? 'Permission was permanently denied. Please enable Physical Activity in App Settings.'
                        : 'Allow activity recognition so your real-world steps power your partner!',
                    style: const TextStyle(color: AppColors.cream, fontSize: 7.5),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _requestPermissionAndInit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.darkBlue,
                            border: Border.all(color: AppColors.green, width: 1.5),
                          ),
                          child: const Text(
                            'TRY AGAIN',
                            style: TextStyle(
                              color: AppColors.green,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => openAppSettings(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.darkBlue,
                            border: Border.all(color: AppColors.yellow, width: 1.5),
                          ),
                          child: const Text(
                            'OPEN SETTINGS',
                            style: TextStyle(
                              color: AppColors.yellow,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          if (_sensorError != null)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.darkBlue,
                border: Border.all(color: Colors.orangeAccent, width: 1.5),
              ),
              child: Text(
                'ℹ️ $_sensorError',
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 8),
              ),
            ),

          const Text('DAILY ACTION GOALS', style: TextStyle(color: AppColors.yellow, fontSize: 10)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.navy,
              border: Border.all(color: AppColors.blue, width: 2),
            ),
            child: Column(
              children: [
                _buildMilestoneRow(
                  '1,000 Steps (Milestone)',
                  canGetMilestone,
                  canGetMilestone ? "READY!" : "${GameConstants.dailyFirstMilestone - dailySteps}L",
                  'Reaching 1,000 steps secures your daily streak and marks your first milestone.',
                  context,
                ),
                const Divider(color: AppColors.darkBlue, height: 16),
                _buildMilestoneRow(
                  'Search Charge (Wild)',
                  canSearchNormal,
                  canSearchNormal ? "$normalSearches READY" : "IN PROGRESS",
                  'Allows you to search current area for wild Pokémon encounters.',
                  context,
                ),
                const Divider(color: AppColors.darkBlue, height: 16),
                _buildMilestoneRow(
                  'Deep Search (Rare)',
                  canSearchRare,
                  canSearchRare ? "$rareSearches READY" : "IN PROGRESS",
                  'Unlocks deep exploration for rare and evolved Pokémon.',
                  context,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (canSearchNormal) ...[
            GestureDetector(
              onTap: isSearching ? null : () => _triggerEncounter(false, currentRegion),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkBlue,
                  border: Border.all(color: AppColors.green, width: 2),
                ),
                child: Center(
                  child: Text(
                    isSearching ? 'ENTERING TALL GRASS...' : '⚔️ SEARCH & BATTLE ($normalSearches)',
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (canSearchRare) ...[
            GestureDetector(
              onTap: isSearching ? null : () => _triggerEncounter(true, currentRegion),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkBlue,
                  border: Border.all(color: AppColors.purple, width: 2),
                ),
                child: Center(
                  child: Text(
                    isSearching ? 'SEARCHING DEEP AREA...' : '✨ RARE ENCOUNTER BATTLE ($rareSearches)',
                    style: const TextStyle(
                      color: AppColors.purple,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const Text('DAILY STEP PROGRESS', style: TextStyle(color: AppColors.yellow, fontSize: 10)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkBlue,
              border: Border.all(color: AppColors.blue, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  // DÜZELTME: .toDouble() ile tip güvenliği sağlandı
                  value: (dailySteps / GameConstants.dailyRareGoal).clamp(0.0, 1.0).toDouble(),
                  minHeight: 10,
                  backgroundColor: AppColors.navy,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$dailySteps / ${GameConstants.dailyRareGoal} STEPS',
                      style: const TextStyle(color: AppColors.cream, fontSize: 8),
                    ),
                    Text(
                      '${(dailySteps / 250).floor()} XP earned',
                      style: const TextStyle(color: AppColors.yellow, fontSize: 8),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMilestoneRow(
    String title,
    bool isCompleted,
    String statusText,
    String description,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: AppColors.darkBlue,
            shape: Border.all(color: AppColors.cream, width: 2),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('ACTION INFO', style: TextStyle(color: AppColors.yellow, fontSize: 10)),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.cream,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(color: AppColors.blue, fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.cream, width: 2)),
                      child: const Text('OK', style: TextStyle(color: AppColors.cream, fontSize: 9)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isCompleted ? AppColors.green : AppColors.blue,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isCompleted ? AppColors.cream : AppColors.blue,
                        fontSize: 9,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: isCompleted ? AppColors.green : AppColors.cream,
                    fontSize: 8,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.info_outline, color: AppColors.blue, size: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}