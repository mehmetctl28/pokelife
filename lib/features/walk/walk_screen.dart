import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';
import 'package:pokelife/core/providers/quest_provider.dart';
import 'package:pokelife/core/data/world_data.dart';
import 'package:pokelife/core/data/pokemon_data.dart';
import 'package:pokelife/core/models/region.dart';
import 'package:pokelife/core/widgets/pokemon_sprite.dart';
import 'package:pokelife/core/constants/game_constants.dart';

class WalkScreen extends StatefulWidget {
  const WalkScreen({super.key});

  @override
  State<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends State<WalkScreen> with WidgetsBindingObserver {
  StreamSubscription<StepCount>? _stepCountStreamSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusStreamSubscription;

  String _status = 'STOPPED';
  bool isSearching = false;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissionAndInit();
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
      if (_permissionGranted) _initPedometer();
    } else if (state == AppLifecycleState.paused) {
      _stopPedometer();
    }
  }

  Future<void> _requestPermissionAndInit() async {
    PermissionStatus status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      setState(() => _permissionGranted = true);
      _initPedometer();
    }
  }

  void _initPedometer() {
    _stopPedometer();
    _pedestrianStatusStreamSubscription = Pedometer.pedestrianStatusStream
        .listen(onPedestrianStatusChanged, onError: (e) {});

    _stepCountStreamSubscription = Pedometer.stepCountStream
        .listen(onStepCount, onError: (e) {});
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
    final trainer = context.read<TrainerProvider>();

    if (isRare) {
      trainer.consumeRareSearch();
    } else {
      trainer.consumeNormalSearch();
    }

    setState(() => isSearching = true);

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => isSearching = false);

      final int pokeId = currentRegion.getRandomPokemonId(isRare: isRare);
      final int wildLevel = currentRegion.getWildLevel(isRare: isRare);

      _showEncounterDialog(pokeId, wildLevel, isRare, currentRegion);
    });
  }

  void _showEncounterDialog(int pokeId, int wildLevel, bool isRare, Region currentRegion) {
    final pokeName = PokemonData.getName(pokeId);
    final pokeType = PokemonData.getType(pokeId);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool isThrowing = false;

          return Dialog(
            backgroundColor: AppColors.darkBlue,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            shape: Border.all(
              color: isRare ? AppColors.yellow : AppColors.cream,
              width: isRare ? 3 : 2,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isRare ? AppColors.purple.withValues(alpha: 0.3) : AppColors.navy,
                      border: Border.all(color: isRare ? AppColors.purple : AppColors.blue, width: 1),
                    ),
                    child: Text(
                      isRare ? '★ RARE ENCOUNTER ★' : 'WILD POKÉMON',
                      style: TextStyle(
                        color: isRare ? AppColors.yellow : AppColors.cream,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pokeName.toUpperCase(),
                    style: const TextStyle(color: AppColors.cream, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(2)),
                        child: Text(
                          'Lv. $wildLevel',
                          style: const TextStyle(color: AppColors.navy, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        pokeType,
                        style: const TextStyle(color: AppColors.blue, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      border: Border.all(color: isRare ? AppColors.yellow : AppColors.blue, width: 2),
                    ),
                    child: Center(
                      child: isThrowing
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('🔴', style: TextStyle(fontSize: 28)),
                                SizedBox(height: 6),
                                Text('THROWING...', style: TextStyle(color: AppColors.yellow, fontSize: 7.5)),
                              ],
                            )
                          : PokemonSprite(pokemonId: pokeId, size: 84),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Encountered in ${currentRegion.name}',
                    style: const TextStyle(color: AppColors.blue, fontSize: 7.5),
                  ),
                  const SizedBox(height: 16),
                  if (!isThrowing)
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(dialogCtx),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.blue, width: 1),
                              ),
                              child: const Center(
                                child: Text(
                                  'RUN AWAY',
                                  style: TextStyle(color: AppColors.blue, fontSize: 9),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () async {
                              setDialogState(() => isThrowing = true);
                              await Future.delayed(const Duration(milliseconds: 900));

                              final trainerProv = context.read<TrainerProvider>();
                              final questProv = context.read<QuestProvider>();

                              bool isNew = await trainerProv.catchPokemon(
                                pokeId,
                                wildLevel: wildLevel,
                                location: currentRegion.name,
                              );

                              int baseBonus = (trainerProv.activePartner?.friendshipHearts ?? 1) >= 4 ? 10 : 0;
                              int xpGained = (isNew ? (isRare ? 60 : 30) : 15) + baseBonus;

                              await trainerProv.addXp(xpGained);

                              if (isNew) {
                                questProv.addCatchProgress();
                              }

                              if (!context.mounted) return;
                              Navigator.pop(dialogCtx);

                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                  isNew
                                      ? 'GOTCHA! $pokeName (Lv. $wildLevel) was caught! +$xpGained XP'
                                      : 'CAUGHT AGAIN! +$xpGained XP',
                                  style: const TextStyle(fontSize: 9.5, color: AppColors.navy, fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: AppColors.green,
                                duration: const Duration(seconds: 3),
                              ));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.green,
                                border: Border.all(color: AppColors.green, width: 1),
                              ),
                              child: const Center(
                                child: Text(
                                  'THROW POKÉBALL',
                                  style: TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
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
                  Text('MAP TRAVEL', style: TextStyle(color: AppColors.yellow, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  Icon(Icons.map, color: AppColors.yellow, size: 16),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Select an unlocked region to explore:', style: TextStyle(color: AppColors.blue, fontSize: 8)),
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
                        color: isSelected ? AppColors.green : (isUnlocked ? AppColors.blue : AppColors.navy),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isUnlocked ? (isSelected ? Icons.check_circle : Icons.circle_outlined) : Icons.lock,
                              color: isSelected ? AppColors.green : (isUnlocked ? AppColors.cream : AppColors.blue),
                              size: 14,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  region.name.toUpperCase(),
                                  style: TextStyle(
                                    color: isSelected ? AppColors.green : (isUnlocked ? AppColors.cream : AppColors.blue),
                                    fontSize: 9,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                if (!isUnlocked)
                                  Text('Unlocks at ${region.unlockSteps} steps', style: const TextStyle(color: AppColors.blue, fontSize: 7)),
                              ],
                            ),
                          ],
                        ),
                        if (isSelected)
                          const Text('CURRENT', style: TextStyle(color: AppColors.green, fontSize: 7, fontWeight: FontWeight.bold)),
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

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCamping ? '🏕️ CAMP RESTING' : '📍 ACTIVE AREA',
                style: TextStyle(color: isCamping ? Colors.orangeAccent : AppColors.yellow, fontSize: 10),
              ),
              Text(
                'STATUS: ${_status.toUpperCase()}',
                style: TextStyle(color: _status.toLowerCase() == 'walking' ? AppColors.green : AppColors.blue, fontSize: 8),
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
                      style: TextStyle(color: AppColors.yellow, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ],
                ),
                Text(
                  '${trainer.steps} TOTAL STEPS',
                  style: const TextStyle(color: AppColors.green, fontSize: 8, fontWeight: FontWeight.bold),
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
                border: Border.all(color: isCamping ? Colors.orangeAccent : AppColors.cream, width: 2),
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
                          style: const TextStyle(color: AppColors.cream, fontSize: 11, fontWeight: FontWeight.bold),
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
          const SizedBox(height: 20),
          if (!_permissionGranted)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.navy,
                border: Border.all(color: Colors.redAccent, width: 2),
              ),
              child: const Text(
                'MOTION PERMISSION REQUIRED TO TRACK STEPS.',
                style: TextStyle(color: AppColors.yellow, fontSize: 9),
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
                    isSearching ? 'SEARCHING THE AREA...' : '🔍 SEARCH AREA ($normalSearches)',
                    style: const TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.bold),
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
                    isSearching ? 'SEARCHING DEEP AREA...' : '✨ SEARCH DEEP AREA ($rareSearches)',
                    style: const TextStyle(color: AppColors.purple, fontSize: 10, fontWeight: FontWeight.bold),
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
                  value: (dailySteps / GameConstants.dailyRareGoal).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: AppColors.navy,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$dailySteps / ${GameConstants.dailyRareGoal} STEPS', style: const TextStyle(color: AppColors.cream, fontSize: 8)),
                    Text('${(dailySteps / 250).floor()} XP earned', style: const TextStyle(color: AppColors.yellow, fontSize: 8)),
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

  Widget _buildMilestoneRow(String title, bool isCompleted, String statusText, String description, BuildContext context) {
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
                  Text(title, style: const TextStyle(color: AppColors.cream, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(color: AppColors.blue, fontSize: 9), textAlign: TextAlign.center),
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
                      style: TextStyle(color: isCompleted ? AppColors.cream : AppColors.blue, fontSize: 9),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Text(statusText, style: TextStyle(color: isCompleted ? AppColors.green : AppColors.cream, fontSize: 8)),
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