import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:pokelife/core/theme/app_colors.dart';
import 'package:pokelife/core/providers/trainer_provider.dart';
import 'package:pokelife/core/providers/quest_provider.dart';
import 'package:pokelife/core/data/world_data.dart';
import 'package:pokelife/core/models/region.dart';
import 'package:pokelife/core/widgets/pokemon_sprite.dart';
import 'package:pokelife/core/constants/game_constants.dart'; // YENİ: Sabitler

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
    setState(() => isSearching = true);
    
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => isSearching = false);
      
      final trainerSteps = context.read<TrainerProvider>().steps;
      final pokeId = WorldData.getRandomEncounter(trainerSteps); 
      _showEncounterDialog(pokeId, isRare);
    });
  }

  void _showEncounterDialog(int pokeId, bool isRare) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppColors.darkBlue,
        shape: Border.all(color: isRare ? AppColors.purple : AppColors.cream, width: 2),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isRare ? '✨ RARE ENCOUNTER! ✨' : 'WILD POKEMON APPEARED!', 
                style: TextStyle(color: isRare ? AppColors.purple : AppColors.yellow, fontSize: 10, fontWeight: FontWeight.bold), 
                textAlign: TextAlign.center),
              const SizedBox(height: 20),
              PokemonSprite(pokemonId: pokeId, size: 100),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context), 
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
                      decoration: BoxDecoration(border: Border.all(color: AppColors.blue, width: 2)), 
                      child: const Text('RUN', style: TextStyle(color: AppColors.blue, fontSize: 10))
                    )
                  ),
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      bool isNew = await context.read<TrainerProvider>().catchPokemon(pokeId);
                      if (!context.mounted) return;
                      
                      int xpGained = isNew ? (isRare ? 50 : 20) : 10;
                      context.read<TrainerProvider>().addXp(xpGained);
                      
                      if (isNew) {
                        context.read<QuestProvider>().addCatchProgress();
                      }
                      
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(isNew ? 'CAUGHT #$pokeId! +$xpGained XP!' : 'CAUGHT AGAIN! +$xpGained XP', style: const TextStyle(fontSize: 10, color: AppColors.navy)), 
                        backgroundColor: AppColors.green, 
                        duration: const Duration(seconds: 2)
                      ));
                    }, 
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
                      decoration: BoxDecoration(color: AppColors.green, border: Border.all(color: AppColors.green, width: 2)), 
                      child: const Text('CATCH', style: TextStyle(color: AppColors.navy, fontSize: 10, fontWeight: FontWeight.bold))
                    )
                  ),
                ],
              )
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
    final totalSteps = trainer.steps;
    
    final currentRegion = WorldData.getCurrentRegion(totalSteps);
    
    final bool isCamping = _status == 'stopped';
    
    // SABİTLER KULLANILDI: Tutarsızlık riski tamamen ortadan kalktı
    final bool canGetXp = dailySteps >= GameConstants.dailyXpGoal;         
    final bool canSearchNormal = dailySteps >= GameConstants.dailyWildGoal;   
    final bool canSearchRare = dailySteps >= GameConstants.dailyRareGoal;    

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isCamping ? '🏕️ CAMP RESTING' : '📍 ACTIVE AREA', style: TextStyle(color: isCamping ? Colors.orangeAccent : AppColors.yellow, fontSize: 10)),
              Text('STATUS: ${_status.toUpperCase()}', style: TextStyle(color: _status == 'walking' ? AppColors.green : AppColors.blue, fontSize: 8)),
            ],
          ),
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.darkBlue, border: Border.all(color: isCamping ? Colors.orangeAccent : AppColors.cream, width: 2)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    Text(isCamping ? '🔥' : '🌍', style: const TextStyle(fontSize: 24)), 
                    const SizedBox(width: 12), 
                    Flexible(
                      child: Text(isCamping ? 'RESTING AT CAMP (Idle)' : currentRegion.name, 
                        style: const TextStyle(color: AppColors.cream, fontSize: 11), overflow: TextOverflow.ellipsis
                      )
                    )
                  ]
                ),
                const SizedBox(height: 12),
                const Text('Walk to explore and encounter Pokémon.', style: TextStyle(color: AppColors.blue, fontSize: 8), textAlign: TextAlign.center),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          if (!_permissionGranted)
            Container(
              padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppColors.navy, border: Border.all(color: Colors.redAccent, width: 2)),
              child: const Text('MOTION PERMISSION REQUIRED TO TRACK STEPS.', style: TextStyle(color: AppColors.yellow, fontSize: 9)),
            ),

          const Text('DAILY ACTION GOALS', style: TextStyle(color: AppColors.yellow, fontSize: 10)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.navy, border: Border.all(color: AppColors.blue, width: 2)),
            child: Column(
              children: [
                _buildMilestoneRow('1,000 Steps (XP)', canGetXp, canGetXp ? "READY!" : "${GameConstants.dailyXpGoal - dailySteps}L", 'Every 1,000 steps helps generate experience points for your partner.', context),
                const Divider(color: AppColors.darkBlue, height: 16),
                _buildMilestoneRow('5,000 Steps (Wild)', canSearchNormal, canSearchNormal ? "READY!" : "${GameConstants.dailyWildGoal - dailySteps}L", 'Allows you to search current area for wild Pokémon encounters.', context),
                const Divider(color: AppColors.darkBlue, height: 16),
                _buildMilestoneRow('10,000 Steps (Rare)', canSearchRare, canSearchRare ? "READY!" : "${GameConstants.dailyRareGoal - dailySteps}L", 'Unlocks deep exploration for rare and legendary Pokémon.', context),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (canSearchNormal) ...[
            GestureDetector(
              onTap: isSearching ? null : () => _triggerEncounter(false, currentRegion),
              child: Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.darkBlue, border: Border.all(color: AppColors.green, width: 2)), child: Center(child: Text(isSearching ? 'SEARCHING...' : '🔍 SEARCH AREA', style: const TextStyle(color: AppColors.green, fontSize: 10)))),
            ),
            const SizedBox(height: 12),
          ],

          if (canSearchRare) ...[
            GestureDetector(
              onTap: isSearching ? null : () => _triggerEncounter(true, currentRegion),
              child: Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.darkBlue, border: Border.all(color: AppColors.purple, width: 2)), child: Center(child: Text(isSearching ? 'SEARCHING...' : '✨ SEARCH DEEP AREA', style: const TextStyle(color: AppColors.purple, fontSize: 10, fontWeight: FontWeight.bold)))),
            ),
            const SizedBox(height: 12),
          ],

          const Text('DAILY STEP PROGRESS', style: TextStyle(color: AppColors.yellow, fontSize: 10)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.darkBlue, border: Border.all(color: AppColors.blue, width: 2)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: (dailySteps / GameConstants.dailyRareGoal).clamp(0.0, 1.0), 
                  minHeight: 10, 
                  backgroundColor: AppColors.navy, 
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green)
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
                  const Text('MILESTONE INFO', style: TextStyle(color: AppColors.yellow, fontSize: 10)),
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
                  )
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
                  Icon(isCompleted ? Icons.check_circle : Icons.radio_button_unchecked, 
                    color: isCompleted ? AppColors.green : AppColors.blue, size: 14),
                  const SizedBox(width: 8),
                  Flexible(child: Text(title, style: TextStyle(color: isCompleted ? AppColors.cream : AppColors.blue, fontSize: 9), overflow: TextOverflow.ellipsis)),
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