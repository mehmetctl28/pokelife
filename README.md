# 🕹️ PokéLife — Retro DSi Kanto Fitness-RPG

**PokéLife** is a retro handheld-inspired (Nintendo DSi / Gen 4 aesthetic) fitness-RPG built with Flutter. It transforms your real-world daily steps into Kanto region exploration, wild Pokémon encounters, turn-based tactical battles, partner friendship bonds, evolutions, and Gym Leader challenges.

---

## ✨ Core Gameplay Features

* **🏃 Real-World Step Progression:**
  * Uses hardware pedometer events to track daily and lifetime steps.
  * Every **250 steps** grants Trainer and Partner XP.
  * Reaching **1,000 daily steps** secures your daily walking streak and builds Partner Friendship.
* **🗺️ Interactive Kanto World & Regional Pools:**
  * Lifetime steps unlock iconic Kanto areas (**Route 1**, **Viridian Forest**, **Mt. Moon**, and **Cerulean Cape**).
  * Each region features distinct normal and rare wild Pokémon pools and level ranges.
* **⚔️ Dual-Screen DSi Turn-Based Battle System:**
  * Decoupled combat math engine (`BattleEngine`) featuring Gen 1 type effectiveness (`1.5x` super effective, `0.7x` not very effective, `0.0x` immunity).
  * Tactical moves including type-specific signature attacks, **False Swipe** (leaves wild Pokémon with at least `1 HP` for a guaranteed `100%` catch rate), and **Morning Sun** (`2/2` battle heal limit).
  * Berry inventory support (**Razz Berry** for `+20%` catch rate, **Oran Berry** for HP recovery) and 3-shake Pokéball capture tension.
* **🏅 Regional Gym Leaders & Permanent Badge Perks:**
  * Multi-Pokémon Boss battles against **Joey**, **Brock**, **Misty**, and **Lt. Surge**.
  * Each earned Gym Badge permanently boosts **Attack Damage by +5%** and **Catch Probability by +3%**.
* **❤️ Partner Friendship & Kanto Evolution:**
  * Walking with an active partner unlocks cumulative bond perks (**Starter Bond**, **Scout Bond**, **Energy Saver**, **Lucky Find**, and **Best Buddy**).
  * Leveling up partners unlocks manual evolutions directly inside the **Kanto Pokédex** while preserving previous species records.
* **📋 Atomic Daily Quests & Achievements:**
  * Daily step and discovery quests with idempotent ledger protection against double-claiming.

---

## 🏗️ Project Architecture

```text
lib/
├── core/
│   ├── constants/       # GameConstants (Single source of truth for step thresholds)
│   ├── data/            # PokemonData, WorldData, EvolutionData, GymData, AchievementData
│   ├── models/          # CaughtPokemon, Region, Quest, Achievement
│   ├── providers/       # TrainerProvider, QuestProvider (ChangeNotifier state + persistence)
│   ├── theme/           # AppColors & Press Start 2P retro pixel styling
│   └── widgets/         # PokemonSprite, KantoTownMap
└── features/
    ├── battle/          # BattleEngine (pure logic) & BattleScreen (DSi dual-screen UI)
    ├── home/            # HomeScreen, PartnerScene, XpBar, DailyStats, DailyQuests
    ├── journal/         # JournalScreen (World progress, Gym Badge Case, Achievements)
    ├── pokedex/         # PokedexScreen (151 Kanto grid, 19 filters, Evolution trigger)
    ├── quests/          # QuestScreen (Daily quest board)
    └── walk/            # WalkScreen (Hardware pedometer stream, Region travel, Encounters)