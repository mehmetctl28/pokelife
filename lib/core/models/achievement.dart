class Achievement {
  final String id;
  final String title;
  final String description;
  final int rewardXp;
  final int target; // YENİ: Başarımın tamamlanma hedefi

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardXp,
    required this.target,
  });
}